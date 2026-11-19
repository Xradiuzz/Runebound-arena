# Stage 10 changelog — Lane Warfare & Siege Waves

## Added
- Dedicated `ArenaWaveDirector` with immediate first wave, 22-second cadence, wave number and siege-wave schedule.
- Four minion roles: melee, ranged, siege and super.
- Ranged and siege minions fire homing projectiles; siege engines deal 70% bonus damage to structures.
- Siege waves every third wave.
- Super minions unlock in a lane after that lane's enemy tower is destroyed.
- Minion stat scaling increases by 7% every four waves, capped at 35%.
- Ten living minions per team per lane cap and 0.22-second minion target-scan cadence for mobile performance.
- Lane pressure scoring for Ash Knight's tower selection and siege-minion defensive priority.
- Tower target priority now focuses siege engines, then ordinary minions, then heroes.
- Lane-aware minion advance after a tower falls; the Ancient remains gated until all three towers are down.
- Distinct minimap markers and wave countdown HUD.

## Preserved
- Warden, Nyxara and Grom; hero abilities and talents.
- Ash Knight combat kit, jungle camps, Elder Riftwarden, team blessing, item shop, recipes and inventory.
- Three lanes, towers, Ancient objectives, touch joystick and Android-compatible GL Compatibility renderer.

## Validation boundary
The source was statically inspected and archive / patch equivalence checks were run. Godot's parser, runtime match, Android APK export and physical-device testing were not available and are not claimed.
