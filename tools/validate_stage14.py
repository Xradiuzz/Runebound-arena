#!/usr/bin/env python3
"""Dependency-free structural checks for Runebound Arena Stage 14."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
SCRIPT_ROOT = ROOT / "scripts"
REQUIRED = {
    "mobile layout class": ("scripts/ui/arena_mobile_layout.gd", "class_name ArenaMobileLayout"),
    "safe-area API": ("scripts/ui/arena_mobile_layout.gd", "DisplayServer.get_display_safe_area()"),
    "viewport resize handling": ("scripts/ui/arena_mobile_layout.gd", "get_viewport().size_changed.connect(_apply_layout)"),
    "canvas layer transform": ("scripts/ui/arena_mobile_layout.gd", "hud_layer.transform = _ui_transform"),
    "design-space input conversion": ("scripts/game.gd", "mobile_layout.to_design_position(viewport_position)"),
    "two-finger pinch": ("scripts/game.gd", "_apply_camera_pinch()"),
    "pinch and wheel zoom blocked by modals": ("scripts/game.gd", "func _is_modal_ui_open() -> bool:"),
    "pinch tap cancellation": ("scripts/game.gd", "targeting.cancel_pending_touch()"),
    "mouse wheel zoom": ("scripts/game.gd", "MOUSE_BUTTON_WHEEL_UP"),
    "performance profile class": ("scripts/arena_performance_profile.gd", "class_name ArenaPerformanceProfile"),
    "low-power MSAA profile": ("scripts/arena_performance_profile.gd", "viewport.msaa_3d = Viewport.MSAA_DISABLED"),
    "MSAA profile": ("scripts/arena_performance_profile.gd", "Viewport.MSAA_4X"),
    "shadow profile": ("scripts/arena_performance_profile.gd", "shadow_enabled = shadows_enabled"),
    "settings modal": ("scripts/game.gd", "func _toggle_settings() -> void:"),
    "live FPS readout": ("scripts/game.gd", "Engine.get_frames_per_second()"),
    "targeting blocks modal taps": ("scripts/arena_targeting.gd", "if _is_modal_open():"),
    "expanded canvas aspect": ("project.godot", 'window/stretch/aspect="expand"'),
}


def scan_source(path: Path, errors: list[str]) -> int:
    source = path.read_text(encoding="utf-8")
    stack: list[tuple[str, int]] = []
    quote = None
    escaped = False
    in_comment = False
    pairs = {")": "(", "]": "[", "}": "{"}
    line_number = 1

    for char in source:
        if char == "\n":
            line_number += 1
            in_comment = False
            if quote and not escaped:
                errors.append(f"{path.relative_to(ROOT)}:{line_number - 1}: string crosses newline")
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
        errors.append(f"{path.relative_to(ROOT)}: unterminated string")
    if stack:
        errors.append(f"{path.relative_to(ROOT)}: unclosed delimiters {stack[-5:]}")

    for number, line in enumerate(source.splitlines(), 1):
        indent = line[: len(line) - len(line.lstrip())]
        if "\t" in indent:
            errors.append(f"{path.relative_to(ROOT)}:{number}: tab indentation")
        if line.strip() and indent and len(indent) % 4:
            errors.append(f"{path.relative_to(ROOT)}:{number}: indentation not multiple of four")

    functions = re.findall(r"^func\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(", source, re.M)
    duplicates = sorted({name for name in functions if functions.count(name) > 1})
    if duplicates:
        errors.append(f"{path.relative_to(ROOT)}: duplicate functions {duplicates}")
    return len(functions)


def verify_layout_math() -> int:
    cases = [
        ((1280.0, 720.0), (0.0, 0.0, 1280.0, 720.0)),
        ((2400.0, 1080.0), (36.0, 0.0, 2328.0, 1080.0)),
        ((1920.0, 1200.0), (0.0, 28.0, 1920.0, 1144.0)),
        ((1600.0, 900.0), (0.0, 0.0, 1600.0, 900.0)),
        ((720.0, 1280.0), (0.0, 32.0, 720.0, 1216.0)),
    ]
    passed = 0
    for viewport, safe in cases:
        vx, vy = viewport
        sx, sy, sw, sh = safe
        scale = max(0.1, min(sw / 1280.0, sh / 720.0))
        content_w = 1280.0 * scale
        content_h = 720.0 * scale
        ox = sx + (sw - content_w) * 0.5
        oy = sy + (sh - content_h) * 0.5
        epsilon = 1e-6
        if ox + epsilon >= sx and oy + epsilon >= sy and ox + content_w <= sx + sw + epsilon and oy + content_h <= sy + sh + epsilon:
            sample = (ox + 417.0 * scale, oy + 263.0 * scale)
            restored = ((sample[0] - ox) / scale, (sample[1] - oy) / scale)
            if abs(restored[0] - 417.0) < epsilon and abs(restored[1] - 263.0) < epsilon:
                passed += 1
    return passed


def main() -> int:
    errors: list[str] = []
    scripts = sorted(SCRIPT_ROOT.rglob("*.gd"))
    total_functions = 0
    classes: dict[str, str] = {}

    for path in scripts:
        total_functions += scan_source(path, errors)
        for class_name in re.findall(r"^class_name\s+([A-Za-z_][A-Za-z0-9_]*)", path.read_text(encoding="utf-8"), re.M):
            if class_name in classes:
                errors.append(f"duplicate class {class_name}: {classes[class_name]} and {path.relative_to(ROOT)}")
            else:
                classes[class_name] = str(path.relative_to(ROOT))

    passed = 0
    for label, (relative_path, required_text) in REQUIRED.items():
        path = ROOT / relative_path
        if path.exists() and required_text in path.read_text(encoding="utf-8"):
            passed += 1
        else:
            errors.append(f"missing integration: {label}")

    project = (ROOT / "project.godot").read_text(encoding="utf-8")
    if '"4.3"' not in project:
        errors.append("project.godot does not declare Godot 4.3 compatibility")

    print(f"GDScript files: {len(scripts)}")
    print(f"Function declarations: {total_functions}")
    print(f"Global classes: {len(classes)}")
    layout_cases = verify_layout_math()
    if layout_cases != 5:
        errors.append(f"responsive transform math cases passed {layout_cases}/5")
    print(f"Stage 14 integration assertions: {passed}/{len(REQUIRED)}")
    print(f"Responsive transform math: {layout_cases}/5")
    print(f"Structural errors: {len(errors)}")
    for error in errors:
        print("ERROR:", error)
    if errors:
        return 1
    print("PASS — structural checks only; Godot parser/runtime not available.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
