# Stage 9 — manual test plan

## Import and match start

1. Open the project in Godot 4.3+ and run `Main.tscn`.
2. Confirm the pre-match hero selector still offers Warden, Nyxara and Grom.
3. Start one match with each hero and confirm the existing Q/W/E/R HUD, shop, inventory, joystick and minimap appear.

## Talent system

1. Gain XP until level 5. Confirm the TALENTS button reports that a choice is ready.
2. Open TALENTS and verify tier 1 offers exactly two hero-specific options.
3. Choose one option; verify its stat / mana effect applies once, the selected option is marked, and the other option becomes unavailable.
4. Die and respawn. Confirm the talent remains selected and its bonus is not re-applied.
5. Reach level 10 and repeat for tier 2. Confirm tier 2 remains locked before level 10.
6. Buy and sell a stat item after choosing a talent and while a team blessing is active. Confirm item recalculation does not erase talent / blessing bonuses.
7. Open SHOP and TALENTS in succession. Confirm only one overlay is visible and the minimap returns when both close.

## Elder Riftwarden

1. Start a match and wait for the 2:00 spawn timer. Confirm the boss appears at the central altar and the HUD / minimap update.
2. Approach and attack it with basic attacks. Confirm its health bar decreases and the player can target it.
3. Use Warden / Nyxara / Grom area abilities against it. With Nyxara, also test Rift Step and Astral Snare at boss range.
4. Reduce boss health below 65% and 30%. Confirm phase changes, HUD updates and increased boss pressure.
5. Observe Rift Slam's ground ring. Move outside the marked radius before impact; confirm no damage when outside and damage / stun when inside.
6. Kill the boss with blue last hit. Confirm +320 gold, +260 XP and the 90-second blessing for current allied units.
7. Spawn a new blue wave while the blessing is active; confirm new allied units receive the buff. Wait for expiry and confirm the modifiers are removed.
8. Confirm the boss respawns after 3:00. Repeat with red last hit if possible and confirm the red team receives the timed blessing.

## Regression / mobile

1. Verify jungle camps still aggro, leash, die and respawn.
2. Verify towers still gate the Ancient and match victory still ends the match.
3. On Android, check landscape layout, joystick movement, ATTACK, Q/W/E/R, inventory slots, SHOP and TALENTS taps.
4. Test low / medium graphics settings on a real device; boss mesh and telegraph effects are procedural and should not require external assets.

## Important

Static source checks do not replace this runtime plan. Godot parser / runtime, APK export and physical-device tests must be performed in Godot / Android tooling.
