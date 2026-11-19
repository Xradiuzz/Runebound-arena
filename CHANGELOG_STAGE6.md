# Stage 6 changelog — Field Armory

## Added
- Data-driven item catalog with nine items and individual prices/effects.
- Six-slot player inventory that survives death and respawn.
- Touch-friendly Field Armory panel with affordability and inventory-capacity checks.
- Passive income (+2 gold per second) and +100 gold for enemy tower takedowns.
- Blink Rune active teleport and Phoenix Core active heal/shield.
- Desktop item hotkeys F/G/H/J/K/L.
- Inventory stat aggregation for damage, health, armor, attack speed, movement, mana, mana regeneration, spell power, lifesteal and on-hit slow.

## Combat integration
- `ArenaActor.take_damage()` now returns actual health damage after shield absorption and armor mitigation.
- Armor reduces damage reaching health; shield points continue to absorb flat damage first.
- Lifesteal uses actual health damage rather than nominal attack damage.
- Frostbrand slow is applied on successful hero basic attacks.
- Item spell power scales Warden, Nyxara and Grom ability damage.

## Preserved
- Stage 5 hero selection and the Warden / Nyxara / Grom kits.
- Three-lane waves, towers, Ancient objectives, respawns, leveling and ability upgrades.
- Godot 4.3+ project layout and GL Compatibility renderer.

## Known limitations
- No item selling, combining/recipes, stash, neutral drops or enemy item builds yet.
- Only the player has an item inventory; Ash Knight remains a simple enemy hero.
- Item prices and stats are prototype balance values and need match telemetry/device playtesting.
- Godot parser, Android APK export and device testing are not verified in this environment.
