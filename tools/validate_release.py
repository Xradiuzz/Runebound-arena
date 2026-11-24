#!/usr/bin/env python3
"""Dependency-free release-preparation checks for Runebound Arena."""
from pathlib import Path
import re
import sys
import struct
import wave

ROOT = Path(__file__).resolve().parents[1]
ERRORS: list[str] = []


def require(condition: bool, message: str) -> None:
    if not condition:
        ERRORS.append(message)


def main() -> int:
    project = ROOT / "project.godot"
    scene = ROOT / "Main.tscn"
    require(project.is_file(), "project.godot must be at the project root")
    require(scene.is_file(), "Main.tscn must be at the project root")
    if project.is_file():
        data = project.read_text(encoding="utf-8")
        require('run/main_scene="res://Main.tscn"' in data, "main scene path is invalid")
        require('"4.3"' in data, "Godot 4.3 compatibility feature is missing")

    scripts = sorted((ROOT / "scripts").rglob("*.gd"))
    require(len(scripts) >= 24, "expected the Stage 14 foundation plus integrated audio director")
    classes: dict[str, str] = {}
    function_count = 0
    for path in scripts:
        text = path.read_text(encoding="utf-8")
        names = re.findall(r"^class_name\s+([A-Za-z_]\w*)", text, re.M)
        for name in names:
            require(name not in classes, f"duplicate global class {name}")
            classes[name] = str(path.relative_to(ROOT))
        functions = re.findall(r"^func\s+([A-Za-z_]\w*)\s*\(", text, re.M)
        function_count += len(functions)
        require(len(functions) == len(set(functions)), f"duplicate function in {path.relative_to(ROOT)}")
        for line_no, line in enumerate(text.splitlines(), 1):
            indent = line[:len(line) - len(line.lstrip())]
            require("\t" not in indent, f"tab indentation: {path.relative_to(ROOT)}:{line_no}")
            if line.strip() and indent:
                require(len(indent) % 4 == 0, f"invalid indentation: {path.relative_to(ROOT)}:{line_no}")

    # Verify every explicit res:// resource reference resolves inside the project.
    for path in [scene, *scripts]:
        if not path.is_file():
            continue
        for resource in re.findall(r"res://([^\"' )]+)", path.read_text(encoding="utf-8")):
            require((ROOT / resource).exists(), f"missing resource {resource} referenced by {path.relative_to(ROOT)}")

    game = (ROOT / "scripts/game.gd").read_text(encoding="utf-8")
    profile = (ROOT / "scripts/arena_performance_profile.gd").read_text(encoding="utf-8")
    actor = (ROOT / "scripts/actor.gd").read_text(encoding="utf-8")
    tower = (ROOT / "scripts/tower.gd").read_text(encoding="utf-8")
    projectile = (ROOT / "scripts/arena_projectile.gd").read_text(encoding="utf-8")
    neutral = (ROOT / "scripts/arena_neutral_monster.gd").read_text(encoding="utf-8")
    audio = (ROOT / "scripts/arena_audio_director.gd").read_text(encoding="utf-8")
    requirements = {
        "hero kill/death counters": "match_kills[killer_team] += 1" in game and "match_deaths[actor.team] += 1" in game and "actor.team == BLUE or actor.team == RED" in game,
        "tower objective counters": "match_towers_destroyed[killer_team] += 1" in game,
        "boss objective counters": "match_boss_kills[killer_team] += 1" in game,
        "kill feed": "func _show_kill_feed(" in game,
        "match result panel": "func _show_match_summary(" in game and "_show_match_summary(winner_team)" in game,
        "return to hero selection": "func _return_to_hero_select() -> void:" in game and "return_button.pressed.connect(_return_to_hero_select)" in game,
        "persistent settings load": '_settings.get_value("graphics", "quality"' in profile,
        "persistent settings save": "_settings.save(SETTINGS_PATH)" in profile,
        "Android export preset": (ROOT / "export_presets.cfg").is_file() and 'name="Android"' in (ROOT / "export_presets.cfg").read_text(encoding="utf-8"),
        "Android ARM64 target": "architectures/arm64-v8a=true" in (ROOT / "export_presets.cfg").read_text(encoding="utf-8"),
        "GitHub Android build workflow": (ROOT / ".github/workflows/build-android.yml").is_file(),
        "actors freeze after match end": 'bool(game.get("game_over"))' in actor,
        "towers freeze after match end": 'bool(game.get("game_over"))' in tower,
        "neutral monsters freeze after match end": 'bool(game.get("game_over"))' in neutral,
        "projectiles freeze after match end": 'bool(game.get("game_over"))' in projectile,
        "world input locks after match end": "if not match_started or game_over:" in game,
        "target lock clears at match end": "targeting.clear_target()" in game,
        "audio director integration": "ArenaAudioDirector.new()" in game and "play_arena_sound(\"death\")" in game,
        "procedural locomotion animation": "visual_root.position.y = sin(_visual_clock" in actor,
        "procedural jungle landmarks": "func _make_arena_landmarks()" in game and "_make_arena_landmarks()" in game,
        "hero portrait assets wired": all(f"hero_{hero}.png" in game for hero in ("warden", "nyxara", "grom", "elyra", "vaelis")),
        "ability icon assets wired": "ABILITY_ICON_PATHS" in game,
        "terrain textures wired": "moss_ground.png" in game and "ancient_stone.png" in game,
        "audio events registered": all(f'"{key}":' in audio for key in ("ui", "attack", "spell", "death", "structure")),
    }
    required_assets = [
        ROOT / "assets/textures/moss_ground.png",
        ROOT / "assets/textures/ancient_stone.png",
        *[ROOT / f"assets/icons/hero_{hero}.png" for hero in ("warden", "nyxara", "grom", "elyra", "vaelis")],
        *[ROOT / f"assets/icons/ability_{slot}.png" for slot in ("q", "w", "e", "r")],
        *[ROOT / f"assets/audio/{name}.wav" for name in ("ambient_loop", "ui_select", "sword_hit", "spell_cast", "hero_death", "structure_break")],
    ]
    require(all(path.is_file() and path.stat().st_size > 44 for path in required_assets), "one or more generated visual/audio assets are missing or empty")
    for path in required_assets:
        if not path.is_file():
            continue
        if path.suffix == ".png":
            data = path.read_bytes()
            require(data[:8] == b"\x89PNG\r\n\x1a\n", f"invalid PNG signature: {path.relative_to(ROOT)}")
            if len(data) >= 24:
                width, height = struct.unpack(">II", data[16:24])
                require(width >= 64 and height >= 64, f"unexpectedly small PNG: {path.relative_to(ROOT)}")
        elif path.suffix == ".wav":
            try:
                with wave.open(str(path), "rb") as audio_file:
                    require(audio_file.getnchannels() == 1, f"audio must be mono: {path.relative_to(ROOT)}")
                    require(audio_file.getsampwidth() == 2, f"audio must be 16-bit PCM: {path.relative_to(ROOT)}")
                    require(audio_file.getframerate() == 22050, f"unexpected audio sample rate: {path.relative_to(ROOT)}")
                    require(audio_file.getnframes() > 1000, f"audio clip is too short: {path.relative_to(ROOT)}")
            except (wave.Error, OSError) as error:
                require(False, f"invalid WAV file {path.relative_to(ROOT)}: {error}")
    for label, passed in requirements.items():
        require(passed, f"missing release integration: {label}")

    print(f"Project root: {ROOT}")
    print(f"GDScript files: {len(scripts)}")
    print(f"Global classes: {len(classes)}")
    print(f"Function declarations: {function_count}")
    print(f"Release integration assertions: {sum(requirements.values())}/{len(requirements)}")
    print(f"Generated assets checked: {len(required_assets)}")
    print(f"Errors: {len(ERRORS)}")
    for error in ERRORS:
        print("ERROR:", error)
    if ERRORS:
        return 1
    print("PASS — static source checks only; Godot parser/runtime/export remain unverified.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
