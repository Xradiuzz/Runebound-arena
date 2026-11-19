# Stage 6 prototype balance sheet

These are initial test values, not final competitive balance.

## Economy
- Starting gold: 500
- Passive income: 2 gold/second after match start
- Enemy creep/hero bounty: existing Stage 5 actor reward values
- Enemy tower bounty: +100 gold
- Inventory: 6 slots, one copy of each item

## Combat formulas
- Armor mitigation: `incoming_health_damage × 100 / (100 + armor)` after flat shield absorption.
- Attack speed: `base_attack_rate / (1 + bonus_attack_speed)`; lower attack interval means faster attacks.
- Lifesteal: a fraction of actual health damage after shields and armor, not nominal damage.
- Spell power: multiplies ability damage by `1 + spell_power_bonus`.
- Frostbrand: applies an 18% movement slow for 1.1 seconds on hero basic attacks.

## Initial tuning targets
- First affordable item should be available at match start (Swiftwind Boots, 300 G).
- Mid-cost stat items require roughly 2–6 minutes of passive income plus combat rewards.
- Active artifact cooldowns: Blink Rune 32 seconds; Phoenix Core 60 seconds.
- Armor has diminishing percentage value through the standard hyperbolic formula above.

Revisit prices, item power and passive income after collecting match duration, kill and purchase telemetry on real Android devices.
