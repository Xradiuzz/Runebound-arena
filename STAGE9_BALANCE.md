# Stage 9 — initial balance sheet

## Elder Riftwarden

| Parameter | Value |
|---|---:|
| Initial spawn | 02:00 |
| Respawn after defeat | 03:00 |
| Health | 3,200 |
| Base armor | 24 |
| Base attack damage | 44 |
| Base attack interval | 1.45 s |
| Aggro radius | 13.0 |
| Leash radius | 20.0 |
| Phase 2 threshold | 65% HP |
| Phase 3 threshold | 30% HP |
| Phase 2 / 3 damage scaling | +22% / +44% |
| Phase 2 / 3 armor | 29 / 34 |

## Rift Slam

| Phase | Telegraph | Radius | Damage | Stun | Cooldown |
|---|---:|---:|---:|---:|---:|
| 1 | 1.15 s | 4.20 | 62 | 0.48 s | 11 s |
| 2 | 0.97 s | 4.95 | 86 | 0.60 s | 9 s |
| 3 | 0.79 s | 5.70 | 110 | 0.72 s | 7 s |

The boss reduces incoming stun / root duration and slow magnitude to 35% to keep the objective threatening without making it immune to control.

## Team blessing

- Duration: 90 seconds.
- +12 attack damage, +0.10 spell power, +0.45 movement speed.
- Applies to all current allied actors and any allied actors spawned before the timer expires. Re-applying refreshes duration without stacking the numeric bonuses.
- Blue last-hit reward: 320 gold and 260 XP to the player. Red last-hit receives the team blessing; the prototype does not yet have a separate red-team gold / XP wallet.

## Talent tiers

| Hero | Tier 1 (level 5) | Tier 2 (level 10) |
|---|---|---|
| Warden | +180 max HP / +0.7 move speed | +12% spell power / +18 armor |
| Nyxara | +120 max mana and +2 regen / +14% spell power | +1 move speed / +8% spell power and +40 mana |
| Grom | +8% lifesteal / +170 max HP | +20% attack speed / +28 attack damage |

Talent numbers are prototype starting values, not final competitive balance. Validate with actual match telemetry and Android device testing before tuning.
