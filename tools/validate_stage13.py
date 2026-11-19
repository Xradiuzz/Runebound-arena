#!/usr/bin/env python3
"""Dependency-free structural checks for the Runebound Arena Stage 13 source."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
SCRIPT_ROOT = ROOT / "scripts"
REQUIRED = {
    "targeting class registered": ("scripts/arena_targeting.gd", "class_name ArenaTargeting"),
    "game creates targeting controller": ("scripts/game.gd", "targeting = ArenaTargeting.new()"),
    "game forwards input": ("scripts/game.gd", "targeting.handle_input(event)"),
    "player attack-move approaches target": ("scripts/actor.gd", "_approach_or_attack(target, delta)"),
    "manual movement cancels order": ("scripts/actor.gd", "player_attack_order = false"),
    "Ancient remains gated": ("scripts/arena_targeting.gd", 'all_towers_destroyed", tower.team'),
    "target panel refresh is throttled": ("scripts/arena_targeting.gd", "_refresh_timer = 0.12"),
    "tap drift filter exists": ("scripts/arena_targeting.gd", "TAP_MAX_DRIFT := 14.0"),
    "modal shop / talent panels block world taps": ("scripts/arena_targeting.gd", "_point_inside_visible_panel"),
    "desktop mouse selection exists": ("scripts/arena_targeting.gd", "InputEventMouseButton"),
    "touch selection exists": ("scripts/arena_targeting.gd", "InputEventScreenTouch"),
}


def scan_source(path: Path, errors: list[str]) -> int:
    source = path.read_text(encoding="utf-8")
    stack: list[tuple[str, int]] = []
    quote: str | None = None
    escaped = False
    in_comment = False
    pairs = {")": "(", "]": "[", "}": "{"}
    line_number = 1

    for char in source:
        if char == "\n":
            line_number += 1
            in_comment = False
            if quote and not escaped:
                errors.append(f"{path.relative_to(ROOT)}:{line_number - 1}: string crosses an unescaped newline")
                quote = None
            escaped = False
            continue
        if in_comment:
            continue
        if quote:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == quote:
                quote = None
            continue
        if char == "#":
            in_comment = True
        elif char in ('"', "'"):
            quote = char
        elif char in "([{":
            stack.append((char, line_number))
        elif char in ")]}":
            if not stack or stack[-1][0] != pairs[char]:
                errors.append(f"{path.relative_to(ROOT)}:{line_number}: unmatched {char}")
            else:
                stack.pop()

    if quote:
        errors.append(f"{path.relative_to(ROOT)}: unterminated string at EOF")
    if stack:
        errors.append(f"{path.relative_to(ROOT)}: unclosed delimiters {stack[-5:]}")

    lines = source.splitlines()
    for number, text in enumerate(lines, 1):
        indent = text[: len(text) - len(text.lstrip())]
        if "\t" in indent:
            errors.append(f"{path.relative_to(ROOT)}:{number}: tab indentation")
        if text.strip() and indent and len(indent) % 4:
            errors.append(f"{path.relative_to(ROOT)}:{number}: indentation is not a multiple of four")

    functions = re.findall(r"^func\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(", source, re.M)
    duplicate_functions = sorted({name for name in functions if functions.count(name) > 1})
    if duplicate_functions:
        errors.append(f"{path.relative_to(ROOT)}: duplicate functions {duplicate_functions}")
    return len(functions)


def main() -> int:
    errors: list[str] = []
    scripts = sorted(SCRIPT_ROOT.rglob("*.gd"))
    total_functions = 0
    classes: dict[str, str] = {}

    for path in scripts:
        total_functions += scan_source(path, errors)
        source = path.read_text(encoding="utf-8")
        for class_name in re.findall(r"^class_name\s+([A-Za-z_][A-Za-z0-9_]*)", source, re.M):
            if class_name in classes:
                errors.append(f"duplicate class {class_name}: {classes[class_name]} and {path.relative_to(ROOT)}")
            else:
                classes[class_name] = str(path.relative_to(ROOT))

    for label, (relative_path, required_text) in REQUIRED.items():
        path = ROOT / relative_path
        if not path.exists() or required_text not in path.read_text(encoding="utf-8"):
            errors.append(f"missing integration: {label}")

    if "4.3" not in (ROOT / "project.godot").read_text(encoding="utf-8"):
        errors.append("project.godot does not declare Godot 4.3 compatibility")

    print(f"GDScript files: {len(scripts)}")
    print(f"Function declarations: {total_functions}")
    print(f"Global classes: {len(classes)}")
    print(f"Integration assertions: {len(REQUIRED) - sum(1 for e in errors if e.startswith('missing integration'))}/{len(REQUIRED)}")
    print(f"Structural errors: {len(errors)}")
    for error in errors:
        print("ERROR:", error)
    if errors:
        return 1
    print("PASS — source structure only; this is not the Godot parser/runtime.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
