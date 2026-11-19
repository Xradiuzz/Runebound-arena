# Stage 8 — Jungle camps and tactical minimap

## Added

- Four neutral jungle camps placed symmetrically around the three-lane battlefield.
- Two neutral monster archetypes: Mossfang Stalker and Stonehide Brute.
- Neutral monster aggro, target selection, leash radius, attack cooldown, return-to-camp behavior and home regeneration.
- Camp respawn timers: 44 seconds for Stalkers and 58 seconds for Brutes.
- Player basic attacks can select neutral monsters; existing hero area abilities can damage and apply slow, stun or bleed to them.
- Blue-team jungle kills grant gold and XP through the shared hero progression flow.
- A top-right tactical minimap showing lanes, bases, living towers, cores, heroes, creeps, neutral camps and camp respawn countdowns.
- Minimap redraw throttling at approximately 8.3 updates per second and touch-input passthrough.
- Camp clearings are kept free of decorative tree meshes to avoid visual overlap.

## Integration

- Added `scripts/arena_neutral_camp.gd`.
- Added `scripts/arena_neutral_monster.gd`.
- Added `scripts/ui/arena_minimap.gd`.
- Updated `scripts/game.gd`, `scripts/actor.gd`, `scripts/heroes/warden_abilities.gd`, `scripts/heroes/arena_hero_kit.gd` and project documentation.

## Validation status

The Stage 7 archive was unpacked and used as the actual base. Source structure, duplicate declarations, delimiter/string balance, camp layout, reward values, minimap bounds, archive integrity and patch overlay equivalence were checked. Godot's own parser/runtime, Android export and physical-device performance are not confirmed because the Godot executable is unavailable in the working environment.
