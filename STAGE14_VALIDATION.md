# Stage 14 validation report

## Results

- Project files: 68
- GDScript files: 23
- Global `class_name` declarations: 22
- Function declarations: 329
- Stage 14 integration assertions: 17/17
- Responsive transform math cases: 5/5 (16:9, wide phone, 16:10 tablet, wide desktop, portrait fallback)
- Duplicate function declarations: 0
- Duplicate global class declarations: 0
- Unbalanced strings / delimiters: 0
- Indentation violations: 0
- Stage 13 regression assertions: 11/11

The patch was overlaid onto a clean Stage 13 archive. The resulting project was compared file-by-file against the Stage 14 full project; all files matched byte-for-byte. Both ZIP archives passed CRC verification.

## Limits

No Godot executable or GDScript parser is available in the build environment. These checks are structural and mathematical only; they do not claim Godot import, runtime, Android export, device safe-area behavior, FPS, thermal behavior or physical touch testing. The documented device matrix remains outstanding.
