# Stage 8 balance sheet

| Camp | Monster | HP | Attack | Armor | Gold | XP | Respawn |
|---|---|---:|---:|---:|---:|---:|---:|
| Blue Grove / Red Grove | Mossfang Stalker | 285 | 18 | 8 | 50 | 58 | 44 s |
| Blue Quarry / Red Quarry | Stonehide Brute | 520 | 29 | 16 | 86 | 96 | 58 s |

## AI parameters

| Parameter | Stalker | Brute |
|---|---:|---:|
| Movement speed | 3.1 | 2.65 |
| Aggro radius | 5.8 | 6.4 |
| Leash radius | 10.5 | 11.5 |
| Attack range | 1.9 | 2.2 |
| Attack interval | 1.35 s | 1.55 s |
| Home regeneration | 3.5% max HP / s | 3.5% max HP / s |

## Design intent

- Stalkers are quicker, weaker and suitable for early jungle farming.
- Brutes are slower and tougher, with a larger reward.
- Monsters prefer heroes over minions when both are inside their aggro radius.
- A monster abandons a chase outside its leash radius and returns to its camp; it regenerates only after reaching home.
- Area damage and damage-over-time effects work on neutral monsters. Hero-targeted dashes remain focused on enemy heroes / minions in this stage.
- Rewards are granted only when the last-hit team is BLUE, matching the current single-player progression model.

These are prototype values and require match telemetry and Android playtesting before final balancing.
