# Stage 11 validation report

## Source baseline
- Base archive: `Runebound_Arena_Stage10_Full_Project.zip`.
- Stage 10 baseline: 44 project files.
- Stage 11 adds one new team-director script and four Stage 11 documentation files; existing files are updated in place.

## Static checks
- 19 GDScript files, 18 unique global classes and 266 function declarations scanned (6,537 GDScript lines).
- GDScript string / comment / bracket balance.
- No duplicate function declarations within a script.
- No duplicate global `class_name` declarations.
- Four-space indentation; no tab-indented GDScript lines.
- 16 / 16 Stage 11 integration assertions passed.
- `Main.tscn` script path resolves.
- Actor setup call sites use the extended optional hero-id / role parameters safely.
- All three player selections produce exactly three unique blue roles and three red roles.
- Role-to-lane mapping is Offlane=2, Mid=1, Carry=0; Support=0 and Roamer=1 are reserved for future 5v5.
- Both hero ability scripts gate keyboard input behind `hero.is_player`.
- Bot brains are attached to both allied bots and all three red heroes; Warden / Nyxara / Grom AI copies receive their corresponding ability kit.
- Team focus refresh is 0.42 seconds and individual bot think interval is 0.18 seconds.
- Structure target selection requires allied minion escort; without a wave, bots hold outside tower aggro range.
- Camera follow, team HUD and minimap role markers are present.

## Archive checks
- Full and patch ZIP archives pass CRC integrity checks.
- Stage 11 patch is applied to a clean Stage 10 extraction and compared file-by-file with the full Stage 11 project.

## Not verified
Godot is not installed in this environment. Godot's own GDScript parser, editor import, runtime match, Android APK export and physical-device performance have not been tested. Static checks are not a substitute for an engine import / run.
