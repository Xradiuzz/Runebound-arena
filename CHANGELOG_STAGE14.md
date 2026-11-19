# Runebound Arena — Stage 14 changelog

## Adaptive Android experience

- Added `ArenaMobileLayout` to scale and center both hero selection and the match HUD into the current viewport safe rectangle.
- Added Android / iOS safe-area conversion using DisplayServer screen and safe-rectangle information.
- Added a design-space input conversion so the joystick and world-tap regions remain stable after HUD scaling.
- Expanded the selection backdrop to cover the entire viewport on wide landscape displays.
- Set canvas stretch aspect to `expand` so the 3D view uses wider landscape screens without stretching the HUD.

## Camera and performance

- Added two-finger camera pinch zoom, constrained to the battlefield, plus desktop mouse-wheel zoom.
- A multi-touch gesture cancels pending single-tap target selection. Pinch zoom is disabled while SHOP, TALENTS or SETTINGS is open.
- Added live LOW / BALANCED / HIGH graphics profiles with MSAA, directional shadows and FPS cap. 3D render scaling is intentionally omitted because this project retains GL Compatibility.
- Added a SETTINGS modal that excludes SHOP / TALENTS and blocks accidental world target selection.

## Preserved systems

The five-role roster, 5v5 team AI, bot loadouts, lane waves, siege units, neutral camps, Elder Riftwarden, structures, talents, player shop, target lock and attack-move remain in place.
