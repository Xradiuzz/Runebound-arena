# Stage 11 manual test plan

## Import and start
1. Open the project in Godot 4.3 or newer and run `Main.tscn`.
2. Select each hero in separate runs: Warden, Nyxara and Grom.
3. Confirm the selected hero spawns in Offlane, Mid or Carry respectively.

## Roster and roles
1. Confirm three blue heroes and three red heroes spawn.
2. Confirm blue team fills the two roles not occupied by the selected hero.
3. Confirm red team contains Ash Knight / Nyxara / Grom.
4. Confirm offlane uses the right outer lane, mid the centre lane, and carry the left outer lane.
5. Confirm the HUD shows alive team counts and role order; minimap hero markers show O / M / C.

## Combat and ability isolation
1. Observe allied and enemy heroes attack enemy creeps and heroes.
2. Confirm bots hold outside tower range until an allied minion wave reaches the structure, then join the siege.
3. Trigger player Q / W / E / R repeatedly. Confirm AI heroes do not cast all at once from the player's keyboard input.
4. Observe Warden, Nyxara and Grom bots use their own ability kits and spend their own mana / cooldowns.
5. Verify bot levels and ability ranks increase over match time.
6. Verify the hero passives work on AI copies: Warden shield proc, Nyxara echo, Grom bleed / Warpath.

## Team tactics
1. Bring at least two heroes from one team close to an enemy hero. Confirm both can focus the same target.
2. Reduce a focus target's health and verify the team score prefers the low-health target.
3. Damage Elder Riftwarden below 72% after 2:00 and verify mid bots rotate to contest it.
4. Reduce the boss below 34% and verify nearby offlane / carry heroes can join.
5. Lower a bot below 30% HP and verify it retreats to its own base, recovers, then returns above 68% HP.

## Camera / Android
1. Move the player across all three lanes and verify the camera follows smoothly.
2. Verify the joystick and ability buttons remain usable while the camera moves.
3. Test the project on an Android device at low / medium quality and profile frame time with full waves active.

Godot runtime, APK export and physical-device testing are not performed by the static validation script.
