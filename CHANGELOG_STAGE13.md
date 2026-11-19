# Stage 13 changelog — Competitive Combat & Target Lock

## Added

- Added `ArenaTargeting`, a dedicated screen-space target-selection controller for enemy heroes, creeps, hostile towers / exposed Ancient, neutral camps and Elder Riftwarden.
- Added a gold selection ring and target HP panel with a clear-target action.
- Added touch-tap and desktop left-click selection with drag filtering and HUD exclusion zones.
- Added player attack-move: ATTACK / SPACE approaches the locked target and attacks when in range.

## Changed

- Direct joystick / WASD movement now overrides and cancels the player's attack-move order.
- Player death / respawn clears any stale attack-move order.
- The match HUD now explains tap-to-lock and attack-to-chase controls.

## Preserved

- Stage 12 5v5 roster, five roles, hero abilities, talents and bot loadouts.
- Stage 10 lane waves, siege minions, structures, Ancients and projectiles.
- Jungle camps, Elder Riftwarden, team blessings, shop, inventory, recipes and minimap.
- Bot AI cadence and team coordination are unchanged.
