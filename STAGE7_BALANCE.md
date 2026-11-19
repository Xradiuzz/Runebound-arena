# Stage 7 balance reference

## Ash Knight NPC kit

| Slot | Ability | Cost | Starting effect | Base cooldown |
|---|---|---:|---|---:|
| Q | Dread Lunge | 55 mana | 119 damage at rank 1, up to 6.55-unit dash, 0.60s stun | 11s |
| W | Ashen Resolve | 75 mana | 15.5% max-health heal plus 73 shield for 3.85s | 22s |
| E | Cinder Sweep | 70 mana | 92 area damage, 1.85s slow | 13s |
| R | Ashen Dominion | 145 mana | 200 area damage and 0.98s stun at rank 1 | 95s |

- Bot simulated level: `1 + floor(match_time / 45s)`, capped at 18.
- Q/W/E rank increases every five simulated levels; R ranks unlock at levels 6, 12 and 18.
- Retreat threshold: 30% health. Resume threshold: 68% health.
- Base recovery: 4.5% maximum health per second within 3.8 units of the red home position.
- AI decision interval: 0.18 seconds; movement is updated every physics frame by `ArenaActor`.

## Crafted items

| Upgrade | Components | Combine fee | Total value | Sell refund (60%) |
|---|---|---:|---:|---:|
| Runebound Edge | Ember Edge + Bloodfang | 380 | 1,530 | 918 |
| Aegis of Dawn | Ironleaf Vest + Guardian Sigil | 450 | 1,450 | 870 |
| Tempest Core | Swiftwind Boots + Aether Lens | 350 | 1,150 | 690 |

Sell refunds are rounded down to whole gold. The component items are consumed when a recipe is completed; no component value is refunded separately.

All values are prototype tuning values and need match telemetry and Android playtesting.
