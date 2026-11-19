# Stage 12 balance notes

## Hero baselines

| Hero | Role | HP | Move speed | Attack damage | Range | Attack interval |
|---|---|---:|---:|---:|---:|---:|
| Warden | Offlane | 690 (bot) / 700 (player) | 5.25 / 5.6 | 58 / 62 | 2.7 | 0.82 / 0.72 |
| Nyxara | Mid | 555 / 570 | 5.7 / 5.9 | 43 / 49 | 7.1 / 7.2 | 0.96 / 0.88 |
| Grom | Carry | 810 / 850 | 4.95 / 5.0 | 69 / 74 | 2.8 | 0.88 / 0.86 |
| Elyra | Support | 620 / 650 | 5.05 / 5.2 | 40 / 42 | 6.5 / 6.6 | 1.08 / 1.02 |
| Vaelis | Roamer | 620 / 640 | 6.2 / 6.35 | 52 / 54 | 2.7 / 2.75 | 0.86 / 0.84 |

The first value in each stat cell is the AI baseline; the second is the player baseline.

## New ability values

- Elyra Mending Ray heals 95 / 125 / 155 / 185 and adds a rank-scaled shield.
- Sanctuary heals 65 / 90 / 115 / 140 in a 6-unit radius and grants shields.
- Binding Light deals 55 / 80 / 105 / 130 in a 4.4-unit radius and roots for 1.0–1.6 seconds.
- Dawn Chorus heals 180 / 250 / 320 to each eligible allied hero and adds a shield; it unlocks at levels 6 / 12 / 18.
- Vaelis Shadow Pounce deals 105 / 145 / 185 / 225 and slows the target.
- Hunter's Mark deals 65 / 95 / 125 / 155 and applies slow + bleed.
- Gale Cut deals 80 / 115 / 150 / 185 in a 4.8-unit radius.
- Nightfall deals 175 / 255 / 335 in a 5.8-unit radius and stuns; it unlocks at levels 6 / 12 / 18.

## Bot economy

- Starting bot gold: 350.
- Passive bot income: 1.25 gold / second.
- AI purchase evaluation: every 2.5 seconds.
- Team takedown gold share: `max(1, floor(victim bounty / 10))` per AI teammate.
- Neutral camp gold share: `max(1, floor(camp bounty / 12))` per AI teammate.
- Enemy tower reward to AI allies: 20 gold per bot; player still receives the existing 100-gold reward.
- Six inventory slots; item stats are applied as deltas so talent and team-buff bonuses remain intact.

## Build priorities

- Support: Ironleaf Vest → Aether Lens → Swiftwind Boots → Phoenix Core → Guardian Sigil → Aegis of Dawn.
- Roamer: Swiftwind Boots → Ember Edge → Frostbrand → Blink Rune → Bloodfang → Runebound Edge.
- Offlane: Ironleaf Vest → Guardian Sigil → Swiftwind Boots → Aegis of Dawn → Frostbrand → Phoenix Core.
- Mid: Aether Lens → Swiftwind Boots → Ember Edge → Tempest Core → Runebound Edge → Blink Rune.
- Carry: Ember Edge → Swiftwind Boots → Bloodfang → Frostbrand → Runebound Edge → Blink Rune.

These are prototype tuning values, not final competitive balance. They require in-engine match observation and later telemetry-based adjustment.
