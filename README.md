# Runebound Arena — Stage 14: Adaptive Android Experience

Stage 14 builds on the Stage 13 5v5 project. It adds safe-area-aware HUD scaling, multi-touch camera zoom and live rendering profiles while preserving the existing combat / AI systems.

## Adaptive mobile layout

- `scripts/ui/arena_mobile_layout.gd` uses a 1280×720 reference canvas and a uniform scale / centered origin.
- Android and iOS use `DisplayServer.get_display_safe_area()` mapped into viewport coordinates. Desktop uses the full viewport.
- The hero-selection screen and in-match HUD receive the same `CanvasLayer` transform. The selection backdrop expands to cover the full viewport on wide landscape displays.
- The project uses `canvas_items` stretching with `aspect = expand`, allowing the 3D viewport to use wider landscape screens without stretching UI elements.
- Touch positions are converted back to design coordinates before joystick / gesture-zone checks. Target projection still receives the original viewport coordinates.

## Camera gestures

- **Two-finger pinch in the battlefield:** zoom camera in / out.
- **Mouse wheel:** equivalent zoom controls on desktop.
- Pinch is limited to the central battlefield zone. Gestures starting on the joystick, minimap, ability row or modal panels do not change camera zoom.
- A second active touch cancels a pending single-finger target tap, preventing accidental target locks during a pinch.
- Zoom is clamped to 0.78–1.42 and can be reset from SETTINGS.

## Android graphics profiles

Open **SETTINGS** during a match:

| Profile | MSAA | Shadows | FPS cap |
|---|---:|---|---:|
| Low | Off | Off | 30 |
| Balanced | 2x | On | 60 |
| High | 4x | On | 60 |

Balanced is the default. The project retains GL Compatibility for broad Android reach; Godot 4.3 does not provide 3D buffer scaling in that renderer, so no render-scale control is exposed. The profile affects MSAA, directional shadows and FPS cap only; it does not change hero stats, AI cadence, damage or match balance. Settings is mutually exclusive with SHOP and TALENTS and blocks world target selection behind the modal. The settings panel also reports live FPS and HUD scale. Profiles are runtime-only in Stage 14 and are not persisted across restarts.

## Run Stage 14

1. Open `Runebound_Arena` in Godot 4.3 or newer and run `Main.tscn`.
2. Select any hero. Confirm the selection cards remain centered and the backdrop covers the complete window.
3. Start a match and open SETTINGS. Cycle through Low, Balanced and High.
4. Pinch with two fingers in the central battlefield to zoom. Use the mouse wheel on desktop.
5. Test joystick + target selection simultaneously. A pinch must not trigger a target tap.
6. Run the Android device matrix in `STAGE14_TEST_PLAN.md`, especially phones with cutouts and wider landscape ratios.

## Stage 14 implementation files

- `scripts/ui/arena_mobile_layout.gd` — safe-area conversion, uniform CanvasLayer transform and backdrop fitting.
- `scripts/arena_performance_profile.gd` — Low / Balanced / High rendering profiles.
- `scripts/game.gd` — settings panel, pinch zoom and design-space joystick input.
- `scripts/arena_targeting.gd` — design-space world-tap filtering and multi-touch tap cancellation.
- `project.godot` — expanded landscape aspect handling.

Run `python tools/validate_stage14.py` for dependency-free source checks. These checks do not replace Godot's parser, runtime or physical-device testing. See `STAGE14_TEST_PLAN.md`, `STAGE14_LAYOUT_SPEC.md` and `STAGE14_ANDROID_PROFILE.md`.

## Apply Stage 14 patch to Stage 13

Extract `Runebound_Arena_Stage14_Patch.zip` into the root of the Stage 13 project, preserving folders and replacing updated files. Stage 14 adds the two new scripts and Stage 14 documentation / validator, and updates `project.godot`, `scripts/game.gd`, `scripts/arena_targeting.gd` and this README.

---

# Stage 13 — Competitive Combat & Target Lock

Stage 13 adds deliberate touch / mouse target selection and an attack-move order for the player hero. It builds directly on the Stage 12 5v5 project: the five-role roster, team AI, bot economies, lane waves, structures, neutral camps, Elder Riftwarden, talents, inventory and shop remain in place.

## Player combat controls

- **Tap / click a hostile hero or creep:** lock that target. The target panel shows its current and maximum HP, and a gold ring marks the selected unit.
- **Tap / click a hostile tower:** lock it when it is still standing. The Ancient can only be selected after all three defending lane towers have fallen.
- **Tap / click a neutral camp monster or Elder Riftwarden:** lock the neutral objective for a deliberate jungle / boss attack.
- **ATTACK / SPACE:** start an attack-move order against the locked target. The player hero walks into attack range and continues attacking while the order remains active.
- **Joystick / WASD:** direct movement overrides and cancels the current attack-move order without deleting the selected target.
- **CLEAR:** remove the current lock and stop the attack-move order. Tapping empty battlefield space also clears the lock.
- **Desktop:** left-click uses the same target-selection path as a screen tap.

## Implementation notes

- `scripts/arena_targeting.gd` owns screen-space picking, the target HP panel, selection ring and tap / mouse gesture filtering.
- Target picking is performed only on a completed tap. It projects the existing actor / structure / neutral groups through the active camera; it does not issue a physics query every frame and does not require new colliders on procedural towers.
- UI exclusion zones protect the joystick, minimap, top status panels, ability row, inventory and attack button from accidental world selection. Visible shop / talent modal rectangles are also excluded.
- `ArenaActor.player_attack_order` is player-only. Direct movement cancels it; bot orders and the existing AI decision loops are unchanged.
- A target lock is invalidated when the target dies, is removed, changes to an inaccessible Ancient state, or is no longer a valid hostile / neutral objective.

## Run Stage 13

1. Open `Runebound_Arena` in Godot 4.3 or newer and run `Main.tscn`.
2. Select any of the five heroes and start a match.
3. Tap a visible enemy hero or creep in the battlefield area. Confirm the gold selection ring and target HP panel appear.
4. Press ATTACK. Confirm the hero approaches the target and attacks once in range.
5. Move with the joystick while the attack order is active. Confirm direct movement takes priority.
6. Test a neutral monster, a lane tower, and the Ancient before / after the three lane towers are destroyed.
7. Tap CLEAR or empty battlefield space and confirm the target panel disappears.
8. Repeat with two simultaneous fingers: hold the joystick with one finger and select a target with the other.

## Stage 13 validation limits

Run `python tools/validate_stage13.py` from the project root for dependency-free source-structure checks. The source-level checks cover script structure, duplicate declarations, balanced delimiters / strings, required target-selection and attack-move integration points, UI exclusion geometry, archive CRC and patch overlay equivalence. A Godot executable is not available in this environment: Godot's own GDScript parser, live combat, Android export and physical-device input / FPS are not claimed as tested. See `STAGE13_TEST_PLAN.md` for the in-engine and device checks still required.

## Apply Stage 13 patch to Stage 12

Extract `Runebound_Arena_Stage13_Patch.zip` into the root of the Stage 12 project, preserving folders and replacing updated files. The patch adds `scripts/arena_targeting.gd` and updates `scripts/actor.gd`, `scripts/game.gd`, `project.godot` and Stage 13 documentation.

---

# Runebound Arena — Stage 12: The Fivefold War

Stage 12 expands the match from 3v3 to a complete 5v5 roster, adds two playable heroes (Elyra and Vaelis), and gives every AI hero an independent six-slot item economy. It builds on the Stage 11 project and retains the three lanes, waves, siege minions, jungle camps, Elder Riftwarden, talents, towers, Ancient objectives, touch controls and player shop.

## Stage 12 — five roles and autonomous team economies

- **5v5 match:** each side fields Offlane, Mid, Carry, Support and Roamer. Blue uses Warden / Nyxara / Grom / Elyra / Vaelis, with the selected hero controlled by the player. Red mirrors the five roles, with Ash Knight as its signature Offlane.
- **Five playable choices:** hero selection now includes Warden, Nyxara, Grom, Elyra and Vaelis. Support and Roamer can be selected by the player; the blue team fills the remaining four roles automatically.
- **Elyra support kit:** Mending Ray heals and shields the most wounded ally, Sanctuary heals nearby allies, Binding Light roots enemies around a hostile target, and Dawn Chorus heals / shields the whole team.
- **Vaelis roamer kit:** Shadow Pounce closes distance, Hunter's Mark slows and wounds a target, Gale Cut damages and slows nearby enemies, and Nightfall teleports into a fight with an area stun.
- **Role-aware team behavior:** Support escorts the Carry or moves to a wounded ally; Roamer checks for nearby pick-off targets and periodically rotates toward the weaker side lane. Team focus still coordinates nearby heroes onto a shared target.
- **Bot item economy:** every AI hero receives personal passive gold and a share of team takedown / structure rewards. `ArenaBotLoadout` purchases role-prioritized items, combines recipes when components are owned, applies stat deltas without overwriting talents / team buffs, and uses Phoenix Core / Blink Rune when appropriate.
- **Role-specific builds:** Support favours health, mana and protection; Roamer favours movement, attack damage and pick-off tools; Offlane favours durability; Mid favours spell power; Carry favours attack damage and lifesteal.
- **Five-role HUD:** alive counts display `BLUE 5/5` and `RED 5/5`; the minimap already renders O / M / C / S / R role markers.
- **Mobile-aware AI cadence:** team focus remains on a low-frequency shared refresh, bot brains think at 0.18-second intervals, bot shopping checks every 2.5 seconds, and passive bot gold is ticked once per second.

### Active 5v5 roster

| Role | Blue team | Red team | Lane |
|---|---|---|---|
| Offlane | Warden or selected player | Ash Knight | Top |
| Mid | Nyxara or selected player | Nyxara | Middle |
| Carry | Grom or selected player | Grom | Bottom |
| Support | Elyra or selected player | Elyra | Bottom |
| Roamer | Vaelis or selected player | Vaelis | Rotates Mid / side lanes |

### Run Stage 12

1. Open the `Runebound_Arena` folder in Godot 4.3 or newer and run `Main.tscn`.
2. Select one of the five heroes. The chosen hero occupies its natural role; the blue AI fills the other four positions.
3. Confirm the HUD shows `BLUE 5/5` and `RED 5/5`, with all five role markers on the minimap.
4. Watch Elyra heal / shield injured allies and Vaelis rotate toward vulnerable side lanes.
5. Observe bot loadouts: each bot earns gold independently, buys role-prioritized items, combines recipes and activates Phoenix Core / Blink Rune.
6. Play a match with each of the five choices and verify the ability HUD, talent choices, shop and touch controls.

### Stage 12 validation limits

Static checks cover the five-role roster for every player choice, ability definitions / cast handlers, support healing and roamer combat handlers, role lanes, bot economy and item priorities, team-gold routing, duplicate declarations, balanced strings / delimiters, archive CRC and patch overlay equivalence. The Godot executable is not available in this environment, so Godot's own parser, live match, Android APK export and physical-device performance are not claimed as tested.

### Apply Stage 12 patch to Stage 11

Extract `Runebound_Arena_Stage12_Patch.zip` into the root of the Stage 11 project, preserving folders and replacing updated files. The patch adds `scripts/arena_bot_loadout.gd` and updates actor visuals / stats, hero ability catalogs and casts, talents, team director, bot brain, game roster / HUD and documentation.

---

# Runebound Arena — Stage 11: Full 3v3 teams and coordinated hero AI

Stage 11 was the 3v3 foundation. Stage 12 supersedes its three-role roster with five roles while retaining its shared team orders, hero ability systems and tactical minimap.

- `ArenaTeamDirector` introduced shared team focus and role-aware orders.
- Warden, Nyxara and Grom received coordinated bot ability usage; Ash Knight retained his bespoke kit.
- The camera followed the selected hero and the minimap displayed role letters.
- Stage 11's historical patch and test documents remain in the project for reference.

---

# Runebound Arena — Stage 10: Lane Warfare & Siege Waves

Stage 10 extends the Godot 4 prototype with lane warfare, a dedicated wave director, ranged / siege / super minions and strategic lane pressure. It retains the three heroes, talents, jungle camps, Ash Knight AI, Elder Riftwarden, towers, Ancient objectives, item shop, recipes and tactical minimap.


## Stage 10 — Lane warfare and siege waves

Stage 10 adds a dedicated wave director and distinct melee, ranged, siege and super minion roles. Waves arrive immediately when the match starts and then every 22 seconds. Every third wave includes siege engines; destroying an enemy lane tower unlocks a super minion for that lane on subsequent waves. Minion health and damage scale in small steps every four waves, capped at 35%, while each team is limited to ten living minions per lane to protect mobile performance.

Ranged and siege minions fire homing energy projectiles. Siege engines deal 70% bonus damage to structures, have long range and are prioritized by towers. The Ash Knight chooses lane objectives using lane pressure and tower health, and gives extra attention to enemy siege engines. The minimap uses distinct markers for ranged, siege and super minions. A wave status label displays the current wave, next-wave countdown and siege-wave state.

### Run Stage 10

1. Open the `Runebound_Arena` folder in Godot 4.3 or newer and run `Main.tscn`.
2. Select a hero. The first lane wave spawns immediately; later waves arrive every 22 seconds.
3. Every third wave contains siege engines. Their golden projectiles damage towers more efficiently, but towers prioritize them as targets.
4. Destroy a lane tower to unlock a super minion for that lane on subsequent waves. The Ancient remains invulnerable until all three enemy towers are destroyed.
5. Watch the minimap: melee, ranged, siege and super minions have distinct markers.

### Stage 10 validation limits

Static checks cover GDScript structure, duplicate declarations, wave composition / scaling rules, projectile integration, ZIP integrity and patch overlay equivalence. The Godot executable is not available in this environment, so Godot's own parser, runtime behavior, Android export and device performance are not claimed as tested.

### Apply Stage 10 patch to Stage 9

Extract `Runebound_Arena_Stage10_Patch.zip` into the root of the Stage 9 project, preserving folders and replacing updated files. The patch adds `scripts/arena_projectile.gd` and `scripts/arena_wave_director.gd`, and updates the actor, game, tower, bot brain, minimap, README and Stage 10 documentation.

---

## Stage 9 — major systems

### Elder Riftwarden boss

- The Elder Riftwarden awakens at the central rune altar after 2:00 of match time.
- It has 3,200 HP, armor, a melee attack, aggro / leash behavior and a large procedural 3D silhouette.
- At 65% and 30% HP it enters phases 2 and 3, increasing attack damage, attack rate and armor.
- Its Rift Slam uses a visible ground telegraph, then deals area damage and a short stun. The radius and damage increase by phase; players can move out of the marked area before impact.
- The boss resists hard control: stun / root duration and slow magnitude are reduced to 35% of their normal values.
- Killing it grants the last-hit team a 90-second blessing: +12 attack damage, +10% spell power and +0.45 movement speed for current and newly spawned allied units. A blue-team kill also grants the player 320 gold and 260 XP.
- The boss respawns 3:00 after defeat. The minimap and HUD show its location, phase, HP or respawn countdown.

### Hero talents

- Each hero has two talent tiers: tier 1 unlocks at level 5; tier 2 unlocks at level 10.
- Each tier offers two mutually exclusive options. A choice is permanent for the match and does not consume a normal ability skill point.
- Warden talents emphasize durability, mobility and spell / armor scaling; Nyxara talents improve mana, spell power and mobility; Grom talents improve sustain, durability and physical damage.
- The TALENTS panel is touch-operable, shows locked / ready / selected states and closes the minimap while open to avoid overlapping controls.

### Boss interaction

- Basic attacks can select the boss through the existing neutral-monster targeting path.
- Warden, Nyxara and Grom area abilities already include neutral monsters; Nyxara's Rift Step and Astral Snare can now select the boss as a single target as well.
- Bosses appear as larger red-cyan objective markers on the minimap.

## Stage 9 source additions

- `scripts/arena_ancient_boss.gd` — Elder Riftwarden phases, telegraphed slam, control resistance and boss rewards callback.
- `scripts/heroes/arena_talent_system.gd` — hero-specific tier choices and stat application.

Updated integrations:

- `scripts/game.gd` — boss altar / spawn / respawn, timed team blessing, boss HUD, talent panel and level unlocks.
- `scripts/actor.gd` — timed team blessing modifiers that also apply to units spawned while the buff is active.
- `scripts/heroes/arena_hero_kit.gd` — Nyxara targeted Q/W can select the boss.
- `scripts/ui/arena_minimap.gd` — distinct boss objective marker.

## Run Stage 9

1. Open the `Runebound_Arena` folder in Godot 4.3 or newer.
2. Import the project and run `Main.tscn`.
3. Select Warden, Nyxara or Grom.
4. Reach level 5 and press **TALENTS** to choose one tier-1 talent. Reach level 10 for tier 2.
5. At 2:00, contest the central altar. Watch the ground telegraph and leave its marked radius before Rift Slam lands.
6. Secure the last hit to grant your team a 90-second blessing. The boss returns after 3:00.

## Stage 9 validation limits

The source is checked for balanced strings / delimiters, duplicate functions and global classes, key integration markers, ZIP integrity and patch overlay equivalence. This environment does not contain the Godot executable, so Godot's parser, runtime match, Android export and physical-device performance are not claimed as tested.

## Apply Stage 9 patch to Stage 8

Extract `Runebound_Arena_Stage9_Patch.zip` into the root of the Stage 8 project, preserving folders and replacing updated files. The patch adds the two Stage 9 scripts and updates `game.gd`, `actor.gd`, `arena_item_inventory.gd`, `arena_hero_kit.gd`, the minimap, README and Stage 9 documentation. Keep all other Stage 8 scripts and assets.

---

# Runebound Arena — Stage 8: Jungle camps, neutral monsters and tactical minimap

Stage 8 extends the Stage 7 Godot 4 prototype with a jungle layer and a live tactical minimap.

## Stage 8 — Jungle and tactical field map

Stage 8 extends the Stage 7 prototype with four neutral jungle camps and a lightweight live minimap. It keeps the existing three-lane match, hero selection, Ash Knight AI, six-slot inventory, recipes and active artifacts.

### Neutral camps

- Two symmetrical camp types appear on each side of the map: Mossfang Stalkers and Stonehide Brutes.
- Neutral monsters acquire nearby heroes or minions, chase within a leash radius, attack, return to camp and regenerate while home.
- Player basic attacks can select neutral monsters when no nearby enemy or valid structure has higher target priority.
- Warden, Nyxara and Grom area abilities can damage and apply control / bleed effects to neutral monsters.
- Blue-team kills grant gold and XP through the existing progression system.
- Camps respawn after their individual 44- or 58-second timer.

### Tactical minimap

- The top-right field map shows all three lanes, both bases, surviving towers, heroes, creeps and neutral camps.
- Neutral camp markers dim after a kill and display a respawn countdown.
- The player hero has a bright outer ring; team units use blue / red markers.
- The map redraws at approximately 8 Hz rather than every rendered frame and ignores touch input so it does not interfere with the virtual joystick or action buttons.
- The minimap hides while the Field Armory panel is open to avoid overlapping controls.

### Run Stage 8

1. Open the `Runebound_Arena` folder in Godot 4.3 or newer.
2. Import the project and run `Main.tscn`.
3. Select Warden, Nyxara or Grom.
4. Find the gold-ringed camps on the left and right sides of the jungle. Approach and press ATTACK / Space to engage a monster.
5. Use area abilities to clear camps faster; a blue-team kill grants gold and XP.
6. Watch the top-right minimap for camp availability and respawn timers.

### Stage 8 source additions

- `scripts/arena_neutral_camp.gd` — camp visuals, monster lifecycle and respawn timer.
- `scripts/arena_neutral_monster.gd` — neutral aggro, leash, combat, recovery and status effects.
- `scripts/ui/arena_minimap.gd` — low-frequency tactical minimap drawing.

### Stage 8 validation limits

The source archive is checked for file presence, ZIP integrity, balanced delimiters / strings, duplicate functions / classes, patch overlay equivalence and key integration markers. Godot's own GDScript parser, runtime match, Android export and physical-device performance are not claimed as completed unless separately run in Godot.

### Apply Stage 8 patch to Stage 7

Extract `Runebound_Arena_Stage8_Patch.zip` into the root of the Stage 7 project, preserving folders and replacing updated files. The patch adds the three Stage 8 scripts and updates the game, actor, hero area-damage controllers, project header, README and Stage 8 documentation.

Stage 5 extends the Stage 4 Godot 4 prototype with a playable pre-match hero selection screen and two additional hero kits.

## What's new

### Hero selection

A full-screen fantasy-styled roster appears before the match. Select one of three champions to start the battle:

- **Warden — Vanguard / Initiator:** retains the Stage 4 defensive control kit.
- **Nyxara — Arcane / Control Mage:** lower durability, longer basic-attack range and a star/void visual silhouette.
- **Grom — Bruiser / Berserker:** high health and damage, a heavy axe silhouette and a low-health combat frenzy.

The match, player hero, ability controller, HUD palette and character model are created after selection. Existing three lanes, creeps, towers, Ancient objectives, gold, XP, respawns and the Ash Knight opponent are retained.

### Nyxara ability kit

| Slot | Ability | Effect |
|---|---|---|
| Q | Rift Step | Blinks close to the nearest enemy in range, deals damage and briefly slows it. |
| W | Astral Snare | Damages and roots the nearest enemy. |
| E | Starfall | Damages enemies around a nearby target and slows them. |
| R | Void Eclipse | Damages and stuns enemies around Nyxara. |
| Passive | Rift Echo | Every third successful spell empowers the next basic attack and adds a short slow. |

### Grom ability kit

| Slot | Ability | Effect |
|---|---|---|
| Q | Savage Leap | Charges a nearby enemy, dealing damage and stunning it. |
| W | Blood Howl | Restores a percentage of missing health and grants a shield. |
| E | Cleaving Arc | Deals area damage and applies a damage-over-time bleed. |
| R | Warpath | Temporarily increases attack damage and movement speed. |
| Passive | Blood Scent | Every third basic attack applies bleed; below 35% health Grom attacks faster and hits harder. |

### Shared systems

- Nyxara and Grom use the same reusable `ArenaHeroKit` controller and data-driven `ArenaAbilityDefinition` resources as Warden's kit.
- Skill ranks, mana, cooldowns, skill points and level-gated ultimates are shared across the roster.
- Bleed is now a timed status effect with kill attribution, health-bar updates and normal death/reward handling.
- Hero-specific primitive 3D models, colors and spell pulses are generated procedurally; no external assets are required.
- Ability button colors change to match the selected champion.

## Project requirements

- Godot 4.3 or newer.
- Compatibility / GL Compatibility renderer.
- Landscape orientation.
- No external asset packs required.

## Run

1. Extract `Runebound_Arena_Stage5_Full_Project.zip`.
2. Open the `Runebound_Arena` folder in Godot 4.
3. Import the project and run `Main.tscn`.
4. Select Warden, Nyxara or Grom to begin the match.
5. Spend the initial skill point using the small **+** button above a skill button.

## Apply Stage 5 patch to Stage 4

Extract `Runebound_Arena_Stage5_Patch.zip` into the root of the Stage 4 project, preserving folders and replacing files when prompted. The patch contains:

- `scripts/game.gd`
- `scripts/actor.gd`
- `scripts/heroes/arena_hero_kit.gd` (new)
- `scripts/heroes/hero_ability_kit_catalog.gd` (new)
- updated README and Stage 5 changelog

Do not delete the existing Warden ability scripts or `scripts/combat/ability_definition.gd`.

## Controls

- WASD / arrow keys — move.
- Space — basic attack.
- 1 / 2 / 3 / 4 — cast Q / W / E / R.
- Touch devices — virtual joystick, ATTACK and Q/W/E/R buttons.
- Tap **+** above a skill to learn or upgrade it.

## Balance notes

- Nyxara trades durability for range, mobility and control. Rift Echo rewards spell weaving rather than repeated basic attacks.
- Grom has the highest base health and attack damage, but lower mana capacity and regeneration. Bleed and Warpath are his sustained-fight tools.
- Ultimate ranks remain gated at hero levels 6, 12 and 18.
- These are initial prototype values; the next balance pass should use actual match telemetry and device testing.

## Manual test checklist

1. Project imports in Godot 4.3+ and opens `Main.tscn`.
2. The champion selection screen appears before the match starts.
3. Selecting Warden starts the original Stage 4 match and preserves Warden's Q/W/E/R kit.
4. Selecting Nyxara creates the mage model, uses the purple HUD palette and loads Rift Step / Astral Snare / Starfall / Void Eclipse.
5. Every third successful Nyxara spell primes Rift Echo; her next basic attack consumes it.
6. Selecting Grom creates the berserker model, uses the red/orange HUD palette and loads Savage Leap / Blood Howl / Cleaving Arc / Warpath.
7. Every third Grom attack applies bleed; bleed ticks reduce HP and can award the kill to Grom's team.
8. Blood Howl heals and grants a temporary shield; Warpath increases movement and attack output for its duration.
9. All three heroes can move, attack, level up, respawn and damage structures.
10. Touch selection, joystick, attack, ability and upgrade buttons respond in landscape mode.

## Validation status and limitations

- ZIP integrity, source-file paths, delimiter/string balance, duplicate function names and required feature markers are checked by the build script used for this artifact.
- The environment used to prepare this archive does not contain the Godot executable. GDScript parsing by Godot, scene launch, Android export and physical-device testing are **not confirmed**.
- This remains a local prototype: the player has three selectable hero kits while the opposing side is a fixed Ash Knight NPC with its own tactical ability kit. There is no network play, final animation rig or talent tree yet.
- Android APK export still requires Android export templates and a configured SDK/JDK in Godot.

---

# Stage 6 — Field Armory and item economy

Stage 6 builds on the Stage 5 hero roster and adds a six-slot item inventory, a touch-friendly in-match shop, passive gold income, item stat bonuses and two active artifacts.

## New gameplay systems

- **Field Armory:** open the SHOP panel during a match and purchase from nine items.
- **Six inventory slots:** items persist through death and respawn. Empty slots remain disabled until purchased.
- **Economy:** the player starts with 500 gold, gains 2 passive gold per second, earns creep/hero kill rewards, and receives 100 gold for destroying an enemy tower.
- **Passive item stats:** health, armor, attack damage, attack speed, movement speed, mana, mana regeneration, spell power, lifesteal and on-hit slow.
- **Active artifacts:** Blink Rune teleports toward the nearest enemy (or forward if none is nearby); Phoenix Core restores health and grants a temporary shield.
- **Keyboard and touch:** tap inventory slots on mobile; desktop hotkeys F/G/H/J/K/L activate slots 1–6.
- **Combat integration:** armor reduces health damage after shield absorption; lifesteal is based on actual health damage; spell power scales hero ability damage.

## Item roster

| Item | Cost | Effect |
|---|---:|---|
| Ironleaf Vest | 350 | +120 health, +8 armor |
| Ember Edge | 450 | +22 attack damage, +10% attack speed |
| Swiftwind Boots | 300 | +0.9 movement speed |
| Aether Lens | 500 | +120 mana, +3 mana regen, +12% spell power |
| Guardian Sigil | 650 | +240 health, +14 armor |
| Bloodfang | 700 | +26 attack damage, 12% lifesteal |
| Frostbrand | 600 | +16 attack damage, +8% attack speed, 18% slow on hit |
| Blink Rune | 550 | Active blink, 32-second cooldown |
| Phoenix Core | 750 | +160 health, +8 armor; active heal and shield, 60-second cooldown |

## Run and controls

1. Open the `Runebound_Arena` project in Godot 4.3 or newer.
2. Run `Main.tscn` and select Warden, Nyxara or Grom.
3. Press **SHOP** at the top of the match HUD.
4. Buy an item; the purchase is rejected if gold is insufficient or all six slots are occupied.
5. Tap an active item slot on mobile, or press F/G/H/J/K/L on desktop.

Existing movement, attack and ability controls remain unchanged.

## Stage 6 patch

Extract `Runebound_Arena_Stage6_Patch.zip` into the root of the Stage 5 project, preserving the folder structure and replacing updated files. The patch includes the updated game, actor and hero ability controllers, plus the new `scripts/items/` directory.

## Validation status

The Stage 6 source files and ZIP archives are checked for structural consistency, balanced delimiters/strings, duplicate function and class names, required item definitions, patch completeness and archive integrity. A Godot executable is not available in the build environment, so Godot's own parser, scene execution, Android export and physical-device testing are not claimed as completed.

---

# Stage 7 — Ash Knight tactics and item progression

Stage 7 upgrades the fixed red-side Ash Knight from a proximity attacker into a tactical lane opponent and extends Field Armory with recipes and selling.

## Ash Knight combat AI

- `scripts/arena_bot_brain.gd` runs a lightweight decision loop every 0.18 seconds; movement and attack resolution still use `ArenaActor`.
- Target scoring favors the player hero and vulnerable targets, then nearby minions. When no enemy actor is nearby, Ash Knight advances toward an enemy tower and respects the Ancient tower gate.
- NPC abilities: Dread Lunge (Q), Ashen Resolve (W), Cinder Sweep (E) and Ashen Dominion (R).
- The bot retreats below 30% health, uses its heal/shield, regenerates near its base and returns to combat above 68% health.
- Simulated bot level scales with match time; the ultimate unlocks at simulated levels 6 / 12 / 18.

## Recipes and selling

The Field Armory now includes three upgrades:

| Upgrade | Components | Combine fee |
|---|---|---:|
| Runebound Edge | Ember Edge + Bloodfang | 380 G |
| Aegis of Dawn | Ironleaf Vest + Guardian Sigil | 450 G |
| Tempest Core | Swiftwind Boots + Aether Lens | 350 G |

Buy both components first, then use the COMBINE button. Components are consumed and replaced by one finished item. Crafted item stats are recalculated from the resulting inventory. A finished item can be sold for 60% of its total component-plus-combine value.

To sell, open SHOP, switch **SELL MODE: OFF** to **SELL MODE: ON**, then tap an occupied inventory slot. Switch sell mode off or close the shop to return to the normal tap-to-activate behavior for Blink Rune and Phoenix Core.

## Stage 7 patch

Extract `Runebound_Arena_Stage7_Patch.zip` into the root of the Stage 6 project, preserving folder structure and replacing updated files. The patch adds `scripts/arena_bot_brain.gd` and updates actor AI integration, game HUD/shop integration, item catalog and inventory logic.

## Validation status

The Stage 7 archive includes source-level checks for script structure, recipe definitions and totals, patch overlay equivalence and ZIP integrity. Godot's own parser/runtime, Android APK export and physical-device testing are not confirmed in this environment. Use `STAGE7_TEST_PLAN.md` for the in-engine and device checks still required.
