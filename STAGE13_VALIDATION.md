# Stage 13 validation report

## Scope

Stage 13 is based on the supplied `Runebound_Arena_Stage12_Full_Project.zip`. The project was extracted, updated in place, and packaged as a full archive plus a delta patch.

## Implemented source changes

- Added `scripts/arena_targeting.gd` for tap / mouse target picking, target HP UI, selection ring, target invalidation and input-zone filtering.
- Updated `scripts/game.gd` to create the targeting controller, route input events to it and display the new target-lock hint.
- Updated `scripts/actor.gd` with player-only attack-move behavior. ATTACK / SPACE approaches and attacks the locked target; direct movement cancels the order.
- Updated `project.godot` project description.

## Checks

The build script verifies:

- GDScript source files are readable UTF-8 and have balanced brackets / parentheses / braces outside strings and comments.
- No duplicate `class_name` declarations or duplicate function names within a script.
- The target picker, UI exclusion checks (including visible shop / talent modal rectangles), selection panel, target ring, target invalidation and attack-move integration points exist.
- 21 GDScript files, 305 function declarations and 20 unique global classes were scanned; 11/11 integration assertions passed.
- The patch contains exactly the changed project files and documentation.
- Overlaying the patch onto a clean Stage 12 extraction reproduces every file in the Stage 13 full project byte-for-byte.
- Both ZIP archives pass CRC validation.

## Environment limitation

No `godot` / `godot4` executable is installed in the build environment. Installing `gdtoolkit` was also unavailable because package-network access failed. Therefore this report does **not** claim Godot parser validation, scene execution, combat simulation, APK export, Android input testing or FPS profiling. Those remain in `STAGE13_TEST_PLAN.md`.
