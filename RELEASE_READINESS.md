# Runebound Arena — Integrated Release Readiness

## Target release

- Engine: Godot 4.3+ / GL Compatibility renderer.
- Platform: Android first; desktop editor builds remain useful for validation.
- Mode: offline single-player 5v5 against bots. Online multiplayer is intentionally out of scope for the first release.
- Match loop: hero selection → 5v5 match → lane waves / jungle / towers / Ancient → victory or defeat → match summary → hero selection.

## Existing Stage 14 foundation

The imported Stage14 foundation contained 23 GDScript files and 22 global script classes. This integrated package adds an audio director and generated art/audio assets; the current counts are reported by `python tools/validate_release.py`. It includes five playable heroes, five team roles, bot brains and loadouts, three lanes, wave spawning, neutral camps, the Elder Riftwarden, towers / Ancients, hero abilities, talents, items, target selection, a minimap, mobile controls and adaptive UI scaling.

## Integrated additions in this preparation pass

- Team hero kill / death counters, excluding lane minions.
- Team tower destruction counters.
- Elder Riftwarden takedown counters.
- Short-lived kill feed notifications.
- Match-end summary with winner, duration and objective statistics.
- Return-to-hero-selection action after the match.
- Match-end freeze for actors, structures, neutral monsters, projectiles and world-target input.
- Persistent graphics quality setting stored at `user://runebound_settings.cfg`.
- Android export preset targeting ARM64 with a debug signature.
- GitHub Actions workflow for Godot project import and a separate workflow to produce a downloadable debug APK artifact.

## Art, models and audio included in this package

- Original generated 512×512 moss/ground and ancient-stone tile textures, wired into the arena ground and lane materials.
- Five original hero portrait emblems and four ability-slot icons, wired into hero selection and the Q/W/E/R HUD.
- Original generated WAV audio: a soft ambient match loop plus UI selection, melee impact, spell cast, hero defeat and structure-break cues. The audio director uses a small player pool to avoid creating an AudioStreamPlayer for every event.
- Existing heroes, minions, neutral monsters, towers and boss are built from procedural Godot 3D meshes in the GDScript source. This package adds rune obelisks, glowing crystal outcrops and subtle procedural idle / locomotion motion.
- Bot target scoring now considers role, vulnerable targets, local ally/enemy numbers and isolated pick-off opportunities.

**Model limitation:** there are no imported rigged character meshes, skeletal animation clips or motion-captured animations in this package. Hero and creature silhouettes remain procedural mesh assemblies, with lightweight procedural motion. A future art pass can replace these with licensed rigged models without changing the combat systems.

## Validation completed in this environment

- `python tools/validate_stage13.py` — passed.
- `python tools/validate_stage14.py` — passed.
- Generated asset presence and integration assertions — checked by `python tools/validate_release.py`.
- New release hooks and settings persistence — source assertions passed.
- Project source layout — `project.godot` and `Main.tscn` are at the Godot project root inside the archive's `Runebound_Arena/` wrapper, matching the existing repository expansion workflow.
- Android preset and GitHub Actions workflow files — authored and checked for expected configuration entries; remote execution is still pending.
- Upload procedure is compatible with the repository's existing `Expand Stage14 project` workflow: replace the root archive with this package using the same filename, expand it, then run the APK workflow.

These are structural checks only. They are not a substitute for Godot's parser, scene import, gameplay execution, Android export or physical-device testing.

## Required before calling the release build verified

1. Open/import with Godot 4.3 or newer and resolve any parser or resource-import errors.
2. Run a full match and test all five playable heroes, all roles, ability casts, items, talents, respawns, waves, jungle camps, boss phases and Ancient victory.
3. Verify that the match summary counts are correct for both teams and that returning to hero selection starts a clean match.
4. Verify graphics quality survives an app restart.
5. Export and install a debug APK on a physical Android device; test touch input, safe areas, thermal behavior and sustained FPS.
6. Confirm the final GitHub Actions workflow can build the same project from a clean checkout.

## Important limitations

No Godot executable is installed in the current preparation environment. No GDScript parser run, Godot runtime test, Android export or APK installation is claimed. This file is a live readiness checklist, not a declaration that the release is finished.
