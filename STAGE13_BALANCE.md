# Stage 13 balance and input tuning

Stage 13 is a control / combat usability update. It does not change hero base stats, item costs, creep scaling, tower damage, respawn timers, bot income or team reward values.

## Target-pick tuning

| Candidate | Screen-space pick radius | Tie-break bias |
|---|---:|---:|
| Hero | 48 px | 0 |
| Melee / ranged / siege creep | 34 px | +5 |
| Tower / Ancient | 54 px | +9 |
| Neutral monster / Elder Riftwarden | 46 px | +12 |

The closest projected candidate wins; small role biases resolve near-overlapping silhouettes in favor of heroes, then creeps, structures and neutral objectives. The tap must land within the candidate radius.

## Gesture tuning

| Setting | Value | Purpose |
|---|---:|---|
| Maximum tap drift | 14 px | Ignore drags and joystick movement |
| Target panel refresh | 0.12 s | 8.3 Hz HP display without per-frame UI work |
| World tap horizontal zone | 19–80% viewport width | Excludes left joystick and right-side HUD / minimap |
| World tap vertical zone | 22–71% viewport height | Excludes top panels and bottom action controls |

These are initial prototype values for a 1280×720 logical viewport. Re-tune after testing on 16:9, 20:9 and tablet aspect ratios, especially when Android safe-area handling is added.

## Attack-move rules

- Attack-move is opt-in through ATTACK / SPACE.
- It follows the currently valid player target and uses the hero's existing attack range / cooldown.
- Any direct movement input cancels the order immediately.
- Death, target invalidation and CLEAR cancel the order.
- Bot brains are not affected by this player-only state.
