# Stage 11 balance notes

## Active roster

| Role | Lane | Typical hero | Tactical bias |
|---|---:|---|---|
| Offlane | 2 / outer | Warden / Ash Knight | Frontline, initiates nearby hero fights, contests towers |
| Mid | 1 / centre | Nyxara | Control mage, rotates to a weakened Elder Riftwarden |
| Carry | 0 / outer | Grom | Prioritizes same-lane melee / ranged / siege creeps and avoids unnecessary long chases |

The selected player hero occupies its natural role. The blue team fills the remaining two roles. The red team uses Ash Knight offlane, Nyxara mid and Grom carry.

## Bot progression

- Hero level is derived from match time: level 1 initially, then one level every 45 seconds, capped at 18.
- Each gained level applies the existing `ArenaActor.apply_level_up()` growth (+32 max HP, +48 current HP, +3.5 attack damage and +0.035 movement speed).
- Q / W / E ranks advance at levels 1, 6, 11 and 16. R advances at levels 6, 12 and 18.
- Hero ability kits keep their own mana and cooldown handling. The AI does not spend the player's shared skill points.

## Team coordination

- Team focus refresh: 0.42 seconds.
- Per-hero decision interval: 0.18 seconds.
- A shared gank target is selected only when at least two living allies are within 8.5 world units and the candidate is within 13 units of the closest ally.
- Target scoring favours low-health heroes and avoids diving into a numerical disadvantage.
- Retreat threshold: 30% HP. Resume threshold: 68% HP. Base recovery: 4.5% max HP per second inside 3.8 units of the team base.
- Mid / Roamer bots rotate toward Elder Riftwarden after 2:00 once the boss has fallen below 72% HP. Other roles join when the boss is below 34% and within 16 units.

These are prototype tuning values; runtime playtesting is required before treating them as final competitive balance.

## Siege discipline

- A bot only selects an enemy tower when at least one allied minion is within 7.5 units of that tower. The Ancient requires an allied minion from any lane within 10 units after all three lane towers fall.
- Without a wave escort, lane heroes hold around the centre skirmish line (blue Z=+1.5, red Z=-1.5), outside normal tower acquisition range.
- This keeps heroes from walking into tower fire before their wave arrives.
