# Stage 8 source validation report

Base project: `Runebound_Arena_Stage7_Full_Project.zip` from the current conversation files. The archive was present in the active working container and passed CRC verification before extraction.

## Completed checks

- 14 GDScript files scanned; 13 unique global classes found.
- No duplicate function declarations or global class names found.
- GDScript delimiters and quoted strings balanced; no tab indentation found.
- Required Stage 8 integration markers found in camp, monster, minimap, game, actor and hero ability scripts.
- Four camp positions checked against world / minimap bounds and pairwise spacing.
- Camp reward values, monster stats, aggro / leash values and respawn times checked against `STAGE8_BALANCE.md`.
- Neutral monsters checked for group registration, player target acquisition, attack resolution, area damage, slow / stun / bleed handling and blue-team reward callbacks.
- Minimap integration checked for lane / structure / unit / camp drawing, 0.12-second redraw throttling, hidden-state pause and touch passthrough.
- Full project archive contains 32 files; patch archive contains 13 files.
- Stage 8 patch was overlaid on a fresh Stage 7 extraction. All 32 resulting project files matched the Stage 8 full project byte-for-byte; no missing, different or extra files remained.
- Both Stage 8 ZIP archives passed `ZipFile.testzip()` CRC checks.

## Not verified

- Godot GDScript parser / editor import.
- Main scene runtime behavior and in-engine physics.
- Android APK export or physical-device performance.

Reason: no `godot` / `godot4` executable is installed in the working environment. Installing `gdtoolkit` was also blocked because package network access was unavailable. Static source checks are not a substitute for Godot's own parser or a device test.
