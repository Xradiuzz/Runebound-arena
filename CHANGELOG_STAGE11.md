# Stage 11 changelog — Full 3v3 teams and coordinated hero AI

## Added
- `scripts/arena_team_director.gd`: team rosters, role-to-lane mapping, shared focus target selection, boss contest orders, and support / roamer order hooks.
- Two allied AI heroes and two additional red AI heroes. Matches now contain one player plus two allies against three enemy heroes.
- Warden / Nyxara / Grom hero-specific ability kits on AI-controlled heroes.
- Bot ability ranks and hero base stats scale with match time; bot levels now apply actual stat growth.
- Camera follow for the selected player hero.
- Team roster HUD and role letters on minimap hero markers.

## Changed
- `actor.gd` now stores a team role and supports hero identity / stats / visuals for AI heroes. Hero passives apply to AI-controlled heroes as well as the player.
- `arena_bot_brain.gd` now handles both teams, role-aware lane target selection, shared focus orders, retreat / recovery and hero-specific ability use. Ash Knight retains his bespoke spell logic.
- `game.gd` builds the 3v3 rosters from the selected player hero and assigns offlane / mid / carry roles.
- `warden_abilities.gd` and `arena_hero_kit.gd` read keyboard input only for the human-controlled actor, preventing all bot copies from reacting to the player's key presses.
- `arena_minimap.gd` labels hero markers with role initials.

## Balance / scope
- Active match size is 3v3. Offlane, Mid and Carry are the active roles. Support and Roamer hooks are present for a later 5v5 expansion but are not spawned in this stage.
- AI thinking cadence is 0.18 seconds; shared team-order refresh is 0.42 seconds.
