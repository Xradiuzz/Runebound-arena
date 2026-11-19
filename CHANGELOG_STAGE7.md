# Stage 7 — Ash Knight tactics and item progression

## Added: tactical enemy AI
- Added `scripts/arena_bot_brain.gd`, a decision layer attached to the red-side Ash Knight.
- Enemy hero target selection evaluates nearby heroes and minions, prioritizes exposed/low-health targets, and falls back to lane structures.
- Ash Knight now has four NPC-only abilities: Dread Lunge (Q), Ashen Resolve (W), Cinder Sweep (E), and Ashen Dominion (R).
- Ability ranks scale with match time; the ultimate unlocks at simulated hero level 6 and gains ranks at 12 and 18.
- The bot retreats below 30% health, heals/shields, recovers at its base, and re-enters combat above 68% health.
- The bot advances toward the nearest valid enemy tower and only selects an Ancient after its team's tower gate is open.
- Decision selection is throttled to 0.18-second intervals; movement and attack execution remain in `ArenaActor` to preserve existing collision/status behavior.

## Added: item recipes and selling
- Added Runebound Edge (Ember Edge + Bloodfang + 380 gold), Aegis of Dawn (Ironleaf Vest + Guardian Sigil + 450 gold), and Tempest Core (Swiftwind Boots + Aether Lens + 350 gold).
- Crafting consumes the listed components and replaces them with one finished item; stat aggregation recalculates from the resulting inventory.
- Selling returns 60% of the item's total acquisition value, including the combine fee for crafted items.
- Added an in-shop Sell Mode toggle. While enabled, tapping an occupied inventory slot sells that item; when disabled, the existing tap-to-activate behavior remains.
- Recipe upgrades can be completed from a full six-slot inventory when the required components occupy at least two slots.

## Preserved
- Stage 6 nine-item catalog, six-slot inventory, passive income, active artifacts and shop.
- Stage 5 hero selection and Warden / Nyxara / Grom player kits.
- Three lanes, minion waves, towers, Ancient gates, respawns, leveling and mobile joystick/buttons.
- Godot 4.3+ and GL Compatibility renderer target.

## Validation boundary
- Source structure, recipe arithmetic, patch overlay equivalence and ZIP integrity are checked in this artifact.
- Godot's parser/runtime, Android APK export and physical-device performance are not verified in this environment.
