# Stage 13 test plan — Competitive Combat & Target Lock

## Target selection

1. Start a match as each of Warden, Nyxara, Grom, Elyra and Vaelis.
2. Tap / left-click an enemy hero. Confirm a gold ring appears, the target panel shows the correct name and HP, and the attack button changes to `ATTACK / LOCKED`.
3. Tap an enemy melee, ranged and siege creep. Confirm the panel identifies the selected unit and updates HP while it is being attacked.
4. Tap a hostile lane tower. Confirm it can be locked while alive.
5. Before all lane towers are destroyed, attempt to select the enemy Ancient. It must remain unselectable. Destroy the three lane towers and confirm the Ancient becomes selectable.
6. Select a neutral camp monster and Elder Riftwarden. Confirm neutral objectives can be locked and attacked.
7. Tap empty battlefield space and press CLEAR. Confirm the panel and ring disappear.

## Attack-move

1. Select an enemy outside the player's attack range and press ATTACK (or SPACE).
2. Confirm the hero moves toward the target, stops at attack range and attacks on cooldown.
3. While the order is active, use joystick / WASD. Confirm manual movement takes control and the attack-move order is cancelled.
4. Press ATTACK again to resume the order against the still-valid target.
5. Kill the target or let it be removed. Confirm the order stops and no stale target is retained.
6. Die while an attack order is active, then respawn. Confirm the old order is not resumed automatically.

## Input isolation and performance

1. Tap and drag the joystick. Confirm it does not select a world target.
2. Tap abilities, inventory slots, shop, minimap and attack controls. Confirm UI presses are not interpreted as world taps.
3. Hold the joystick with one finger and tap a target with another. Confirm both inputs work independently.
4. Drag across the battlefield without a deliberate tap. Confirm no target is selected.
5. Profile a 5v5 match with full creep waves on a low-end Android device. Target projection should run only on completed tap events; the target panel refreshes at 8.3 Hz.

## Desktop smoke test

- Left-click a target, SPACE to attack-move, WASD to override, and CLEAR to release the target.

## Acceptance criteria

- No target can be selected if it is friendly, dead, freed, or a still-protected Ancient.
- Target HP and target ring clear when the selected target becomes invalid.
- Manual movement always overrides player attack-move.
- Existing bot AI, 5v5 roster, abilities, shop, item slots, waves, towers and boss remain functional.

Godot runtime / Android device testing is still required; this plan is not a claim that those tests have already passed.
