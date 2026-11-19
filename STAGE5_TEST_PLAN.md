# Stage 5 smoke-test plan

Run in Godot 4.3+ with the Compatibility renderer. This is a manual plan; no Godot runtime is available in the archive-generation environment.

## Startup and selection

- [ ] Main scene opens without missing scripts.
- [ ] Selection overlay blocks match controls until a champion is chosen.
- [ ] Each of the three cards starts exactly one match.
- [ ] Player label, stats, model and skill palette match the chosen hero.
- [ ] Wave spawning begins only after selection.

## Shared progression

- [ ] One skill point is available at level 1.
- [ ] Q/W/E can be learned at level 1; R remains locked until level 6.
- [ ] Each level grants one skill point and updates hero stats.
- [ ] Mana regenerates; cooldowns decrease; respawn restores the hero.

## Nyxara

- [ ] Q blinks to the nearest enemy within range and applies damage/slow.
- [ ] W damages and roots one nearby enemy.
- [ ] E damages and slows enemies around the selected target.
- [ ] R damages and stuns enemies around Nyxara.
- [ ] Every third successful spell primes one empowered basic attack.

## Grom

- [ ] Q charges into a nearby enemy and applies damage/stun.
- [ ] W heals Grom and adds shield points.
- [ ] E damages nearby enemies and applies bleed ticks.
- [ ] R increases movement and attack damage for the configured duration.
- [ ] Every third basic attack applies bleed.
- [ ] Below 35% HP, Grom's attacks gain the Blood Scent bonuses.
- [ ] A bleed kill awards gold/XP to Grom's team and removes the victim correctly.

## Android touch

- [ ] Selection buttons respond to taps.
- [ ] Virtual joystick remains independent from the skill buttons.
- [ ] Attack and Q/W/E/R buttons respond without keyboard input.
- [ ] HUD remains within bounds at the target device's landscape resolution.
