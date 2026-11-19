# Stage 8 manual test plan

## Import and match start

1. Open the project in Godot 4.3 or newer and import `project.godot`.
2. Run `Main.tscn`; the champion selection screen should appear.
3. Select each of Warden, Nyxara and Grom in separate runs.
4. Confirm that four camp markers and four neutral monsters appear after the match starts.
5. Confirm that the minimap appears in the top-right corner.

## Neutral monster behavior

6. Approach a Mossfang Stalker and enter its aggro radius; it should pursue and attack the hero.
7. Leave its leash radius; it should stop chasing, return to its camp and regenerate only after reaching home.
8. Repeat with a Stonehide Brute and confirm its higher health / damage and slower movement.
9. Kill a camp monster with basic attacks; verify the gold and XP reward and hero level progression.
10. Use Warden Hammerfall / Chrono Bastion, Nyxara Starfall / Void Eclipse and Grom Cleaving Arc near a camp; verify neutral monsters take area damage.
11. Apply slow, stun and bleed to a neutral monster; verify movement, attack and health changes.
12. Verify the camp respawns after 44 seconds (Stalker) or 58 seconds (Brute), and that the minimap countdown returns to an active marker.
13. Verify that a red-team or neutral kill does not grant blue-player rewards.

## Minimap

14. Confirm three lane paths, both bases, surviving towers, heroes, creeps and neutral camp markers are visible.
15. Move the player and verify the bright player marker updates.
16. Kill a neutral monster and verify its camp marker dims and shows a countdown.
17. Destroy a tower and verify its marker disappears on the next minimap refresh.
18. Open the Field Armory; the minimap should hide to avoid overlap. Close the shop; the minimap should return.
19. Touch and drag the virtual joystick while the minimap is visible; the minimap must not intercept touch input.

## Android performance / export

20. Export a landscape Android debug APK using configured Godot export templates, Android SDK and JDK.
21. On a low/mid-range device, verify that minimap redraw stays smooth and does not cause noticeable frame spikes.
22. Check UI scaling, camp readability, touch controls and safe screen margins on the target device.

The working environment does not contain Godot, so steps 1–22 remain manual engine/device verification tasks; they are not claimed as completed.
