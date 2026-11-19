# Stage 10 balance notes

| Role | HP | Damage | Range | Attack interval | Gold / XP |
|---|---:|---:|---:|---:|---:|
| Melee | 72 | 9 | 1.7 | 1.15 s | 18 / 24 |
| Ranged | 58 | 13 | 6.4 | 1.65 s | 22 / 30 |
| Siege | 360 | 46 | 8.4 | 2.20 s | 42 / 50 |
| Super | 260 | 29 | 2.15 | 0.98 s | 30 / 40 |

- Waves spawn immediately and repeat every 22 seconds.
- Every third wave is a siege wave.
- Wave scaling: +7% HP and damage every four waves, capped at +35%.
- Ten living minions per team per lane maximum; minion target acquisition is throttled to 0.22-second intervals.
- Siege engines deal 1.70x damage to structures and are the first tower target priority.
- Super minions spawn in a lane for the team that destroyed that lane's enemy tower.
- The Ancient remains invulnerable until all three lane towers belonging to its team are destroyed.

The cap and gradual scaling are deliberate mobile-performance safeguards. These values are initial balance targets and need playtesting in Godot before release.
