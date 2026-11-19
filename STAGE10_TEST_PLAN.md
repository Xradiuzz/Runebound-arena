# Stage 10 manual test plan

## Import and startup
1. Open the project in Godot 4.3+.
2. Import the project and run `Main.tscn`.
3. Select each of Warden, Nyxara and Grom in separate runs.
4. Confirm the first wave spawns immediately and the wave HUD counts down from 22 seconds.

## Wave composition
1. Inspect all three lanes: each team should receive three melee and one ranged minion, subject to the ten-minion lane cap.
2. Confirm ranged minions hold distance and fire visible homing projectiles.
3. At wave 3, confirm siege engines spawn on each lane and fire slower golden projectiles.
4. Confirm siege damage against towers is 70% higher than ordinary minion damage.
5. Confirm each lane never exceeds ten living minions per team.

## Lane objectives
1. Destroy one enemy lane tower.
2. On the next wave, confirm the attacking team receives a super minion in that lane.
3. Confirm minions advance beyond the destroyed tower but do not damage the Ancient while another enemy tower remains.
4. Destroy all three enemy towers and confirm the Ancient becomes attackable.

## AI and minimap
1. Let Ash Knight leave the base and observe its lane choice.
2. Create a lane with allied minion advantage and confirm the bot favors its tower objective.
3. Bring an enemy siege engine near the bot and confirm it is considered a high-priority defensive target.
4. Confirm minimap markers differ for melee, ranged, siege and super minions.

## Regression
- Buy, combine, sell and activate items.
- Reach levels 5 and 10 and choose talents.
- Contest the Elder Riftwarden and confirm its phases and blessing still work.
- Test the virtual joystick and action buttons on an Android device after a real export.

## Not yet verified in this environment
Godot editor import, engine parser, runtime combat, Android APK export and physical-device frame rate require a Godot 4 installation and device test.
