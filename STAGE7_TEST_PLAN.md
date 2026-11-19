# Stage 7 manual test plan

## Import and baseline
1. Open the project in Godot 4.3+ and run `Main.tscn`.
2. Confirm the hero selection screen still offers Warden, Nyxara and Grom.
3. Start a match with each hero and verify movement, attacks, Q/W/E/R, leveling and respawn.
4. Confirm the six inventory slots and Field Armory still appear and active items still work.

## Ash Knight AI
5. Approach the Ash Knight and observe it acquire the player or nearby minions rather than remaining idle.
6. Keep distance at roughly 3–9 units and observe Dread Lunge (Q), including its dash hit and stun.
7. Allow Ash Knight to fall below 64% health; verify Ashen Resolve (W) heals and grants a shield when available.
8. Cluster at least two allied actors near Ash Knight; verify Cinder Sweep (E) damages and slows them.
9. After enough match time for simulated level 6, cluster near Ash Knight and verify Ashen Dominion (R) damages and stuns in an area.
10. Reduce Ash Knight below 30% health. Verify it retreats toward the red base, recovers there, then resumes lane combat after exceeding 68% health.
11. Remove enemy actors from its vicinity and verify it advances toward an enemy tower; verify the Ancient is not selected before the tower gate opens.
12. Kill Ash Knight and verify normal respawn behavior resumes its AI afterward.

## Item recipes and selling
13. Buy Ember Edge and Bloodfang, then combine Runebound Edge. Verify both components disappear, the finished item occupies one slot, and the combine fee is charged.
14. Repeat for Ironleaf Vest + Guardian Sigil -> Aegis of Dawn.
15. Repeat for Swiftwind Boots + Aether Lens -> Tempest Core.
16. Enable SELL MODE and tap a populated inventory slot. Verify the item is removed and 60% of its total value is refunded.
17. Verify selling a crafted item refunds 60% of its full component-plus-combine value.
18. Fill all six slots with items including recipe components and verify the matching recipe can still combine into the freed slot.
19. Verify missing components, insufficient combine gold, duplicate finished items and normal full-inventory purchases are rejected.
20. Disable SELL MODE and verify tapping Blink Rune / Phoenix Core activates them again rather than selling them. Desktop item hotkeys should also sell while Sell Mode is enabled and activate while it is disabled.
21. Repeat shop and inventory interactions in landscape touch mode; ensure sell mode is visually obvious and does not block joystick or ability buttons.

## Performance and Android
22. Observe the match with all three lanes populated; check frame pacing on a representative Android device.
23. Confirm the AI decision rate remains approximately 5–6 decisions per second while movement stays smooth.
24. Export an Android debug APK with configured Godot export templates, Android SDK and JDK; installation/device testing must be recorded separately.
