# Changelog — Stage 9

## Added

- Added the Elder Riftwarden neutral objective with 3,200 HP, armor, aggro / leash, melee attacks and a procedural 3D boss model.
- Added three boss phases at 65% and 30% health, scaling attacks and armor.
- Added Rift Slam with a visible ground telegraph, delayed area damage, phase-scaled radius / damage and stun.
- Added boss control resistance against stun, root and slow.
- Added 2:00 initial spawn and 3:00 respawn timers, boss HUD state and a distinct minimap marker.
- Added a 90-second team blessing on boss defeat: +12 attack damage, +10% spell power and +0.45 movement speed. The buff is applied to existing allied actors and units spawned while it remains active.
- Added hero-specific tiered talents: level 5 and level 10 each unlock one mutually exclusive choice.
- Added touch-operable talent panel and talent selection state. Talent choices persist through hero death and do not consume ability skill points.
- Extended Nyxara Rift Step and Astral Snare target selection to include neutral monsters / the boss.

## Updated

- `game.gd`: boss altar, lifecycle, rewards, team buffs, HUD and talent UI / unlock integration.
- `actor.gd`: timed team blessing modifier application and expiry.
- `items/arena_item_inventory.gd`: item-stat deltas preserve non-item bonuses from talents and team blessings.
- `arena_hero_kit.gd`: neutral target lookup for Nyxara's single-target Q/W abilities.
- `ui/arena_minimap.gd`: boss-specific objective marker.

## Preserved

- Warden, Nyxara and Grom; all existing ability kits; Ash Knight bot; three lanes; creeps; towers and Ancients; jungle camps; gold / XP / levels; inventory, recipes and active items; mobile joystick and combat buttons.
