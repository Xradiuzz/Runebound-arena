# Stage 12 changelog — The Fivefold War

## Added

- Expanded both teams from three heroes to five roles: Offlane, Mid, Carry, Support and Roamer.
- Added playable Elyra (Support) and Vaelis (Roamer), including procedural 3D visual identities, hero stats, ability kits and talent trees.
- Added Elyra's Mending Ray, Sanctuary, Binding Light and Dawn Chorus abilities.
- Added Vaelis's Shadow Pounce, Hunter's Mark, Gale Cut and Nightfall abilities.
- Added autonomous six-slot AI loadouts with personal passive gold, team bounty shares, role-based build priorities, recipe combining and active item usage.
- Added roamer side-lane rotation and support carry-escort / wounded-ally selection.
- Expanded the hero selection screen and HUD to five playable choices and 5v5 team counts.

## Changed

- Updated actor stats and visuals for Elyra / Vaelis.
- Updated `ArenaTeamDirector` to register five-role rosters and provide role-offset lane positions.
- Updated `ArenaBotBrain` with support healing decisions and roamer pick-off behavior.
- Updated game spawn logic, team-gold routing and structure reward distribution.
- Updated README and added Stage 12 balance, test and validation documents.

## Preserved

- Stage 10 lane waves, ranged / siege / super minions and projectiles.
- Stage 8 jungle camps and tactical minimap.
- Stage 9 Elder Riftwarden, blessings and talent framework.
- Player shop, six-slot inventory, item recipes, hero abilities, towers, Ancients and touch controls.
