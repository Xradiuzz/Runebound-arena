# Stage 6 manual test plan

## Import and startup
1. Open the project in Godot 4.3+ and import it.
2. Run `Main.tscn`.
3. Confirm the hero selection screen still offers Warden, Nyxara and Grom.
4. Select each hero in separate runs and confirm the existing ability kit and HUD remain available.

## Shop and economy
1. Start a match and confirm the player starts with 500 gold.
2. Confirm gold increases by 2 per second.
3. Open SHOP and confirm all nine items are listed with prices and descriptions.
4. Buy Swiftwind Boots (300) and confirm gold decreases by 300 and the first inventory slot shows BOOTS.
5. Try to buy an item with insufficient gold; confirm the purchase is rejected and gold is unchanged.
6. Fill all six slots and confirm further purchases are disabled/rejected.
7. Kill an enemy creep/hero and confirm the existing kill reward still grants gold and XP.
8. Destroy an enemy tower and confirm +100 gold is granted.

## Passive stats
1. Buy Ironleaf Vest and confirm max/current health increase by 120 and armor by 8.
2. Take damage before and after buying armor; confirm the armored hit removes less health.
3. Buy Ember Edge and confirm attacks deal more damage and occur faster.
4. Buy Swiftwind Boots and confirm movement speed increases.
5. Buy Aether Lens and confirm maximum mana and mana regeneration increase; confirm ability damage is higher.
6. Buy Bloodfang and attack an enemy actor; confirm actual health damage restores a portion of player health.
7. Buy Frostbrand and hit an enemy actor; confirm it receives a slow status.

## Active artifacts
1. Buy Blink Rune, move within range of an enemy and tap its inventory slot; confirm the hero blinks close to the nearest enemy and the cooldown appears.
2. With no nearby enemy, activate Blink Rune and confirm it blinks forward.
3. Buy Phoenix Core, take damage, then activate it; confirm health restoration and a temporary shield.
4. Confirm active items can also be activated with F/G/H/J/K/L on desktop.

## Persistence and regressions
1. Die and respawn; confirm purchased items and their passive stats remain.
2. Confirm item cooldowns continue to tick and do not reset on respawn.
3. Confirm Warden, Nyxara and Grom still move, attack, cast abilities, level up and damage structures.
4. Confirm the shop panel can be opened and closed without blocking the joystick, attack or ability controls when closed.
5. Repeat the touch tests in landscape Android orientation.

## Validation boundary
Source-level checks and ZIP integrity are automated for this artifact. Godot parsing, scene runtime, APK export and physical Android tests must still be performed in Godot with Android export templates and a configured SDK/JDK.

6. Try to buy the same item twice; confirm duplicate copies are rejected.
7. Tap one of the leftmost inventory slots; confirm it activates the item and does not move the joystick.
8. Destroy either Ancient; confirm the shop closes and further purchases/activations are blocked.
