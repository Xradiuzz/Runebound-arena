# Stage 12 manual test plan

## Project and roster

1. Import the project in Godot 4.3+ and run `Main.tscn`.
2. Confirm the hero selection screen shows five cards without horizontal clipping at 1280×720.
3. Start one match with each of Warden, Nyxara, Grom, Elyra and Vaelis.
4. Confirm both teams spawn exactly five heroes and the HUD reports `5/5` before combat.
5. Verify role assignment: Offlane / Mid / Carry / Support / Roamer. Confirm Carry and Support share bottom lane with lateral offsets; Roamer begins Mid.
6. Confirm each hero respawns at its own original spawn point and remains registered in the same team roster.

## New hero abilities

7. Select Elyra. Test Mending Ray on a wounded ally, Sanctuary with multiple injured nearby allies, Binding Light against a grouped enemy wave, and Dawn Chorus when two or more allies are wounded.
8. Select Vaelis. Test Shadow Pounce and Hunter's Mark against a hero, Gale Cut against a group, and Nightfall against at least two clustered enemies.
9. Confirm all four skills show correct names, rank, cooldown and mana state. Confirm ultimate rank gates remain level 6 / 12 / 18.
10. Reach levels 5 and 10 and verify Elyra / Vaelis talent options and stat changes.

## Team behavior

11. Observe Elyra follow the Carry when no ally is critically wounded and move toward the most wounded nearby teammate when healing is needed.
12. Observe Elyra use team-wide Dawn Chorus when multiple allies across the map are injured.
13. Observe Vaelis search for nearby isolated enemies and rotate between Mid and the weaker side lane when no target is available.
14. Confirm the team director coordinates focus targets without making all heroes abandon their roles for distant fights.

## Bot item economy

15. Wait for passive gold and verify each AI hero's loadout purchases according to its role.
16. Verify components are consumed when a recipe is combined and the final item stats replace component stats without doubling bonuses.
17. Verify Phoenix Core activates below its health threshold and respects its cooldown.
18. Verify Blink Rune only activates when a valid target is between 5.5 and 13 units away and respects its cooldown.
19. Confirm bot item bonuses remain after talent selection, team blessing refresh and hero respawn.

## Regression and Android

20. Re-test waves, siege units, neutral camps, Elder Riftwarden, tower targeting, Ancient protection, player shop, player inventory, touch joystick, attack button, abilities and camera follow.
21. Export a debug APK with the Android template, install it on a physical device, and test the five-card selection screen at the target Android orientation and screen aspect ratios.
22. Profile 10 heroes plus lane waves and neutral monsters. Check frame time, memory and touch latency on a low / mid-range device.

Godot import, runtime behavior, APK export and physical-device tests are still pending until these steps are performed in the engine / on Android hardware.
