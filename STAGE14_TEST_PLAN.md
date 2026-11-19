# Stage 14 — test plan

## Godot editor / desktop checks

1. Open the project in Godot 4.3 or newer and run `Main.tscn`.
2. Confirm the hero-selection backdrop fills the complete window at 16:9 and at a wider resizable aspect ratio.
3. Resize the window repeatedly. The five hero cards must remain proportionally scaled and centered; text and buttons must not stretch non-uniformly.
4. Select each hero once. Confirm the match HUD uses the same scale and remains aligned.
5. Open SETTINGS. Change LOW → BALANCED → HIGH. Confirm the label, description, live FPS and HUD-scale readout update, and the game remains playable.
6. Confirm LOW disables the directional sun shadow and 3D MSAA, Balanced restores 2x MSAA, and High selects 4x MSAA. Do not expect 3D render-scale changes while the Compatibility renderer is active.
7. Use the mouse wheel over the battlefield. Confirm the camera zooms in/out and remains centered on the player.
8. Confirm opening SETTINGS closes SHOP / TALENTS and that target picking cannot pass through the settings panel.

## Android device matrix

Test at minimum:

- 16:9 landscape phone without a display cutout.
- 19.5:9 or 20:9 landscape phone with a cutout / rounded corners.
- Landscape tablet (16:10 or 4:3).
- A low / mid-range GPU and a recent high-end GPU.

For each device:

1. Verify joystick, minimap, ability row, inventory, ATTACK, target panel and SETTINGS remain inside the safe rectangle.
2. Rotate only if the export orientation is intentionally changed; the current project remains landscape-oriented.
3. Hold the joystick with one finger and tap a target with the other. Confirm movement and target selection coexist.
4. Pinch with two fingers in the battlefield. Confirm zoom changes smoothly and does not issue a target tap.
5. Try a pinch that starts on the joystick or HUD. It must not change camera zoom. Pinching while SHOP, TALENTS or SETTINGS is open must also be ignored.
6. Compare LOW / BALANCED / HIGH for average FPS, 1% low FPS, device temperature and battery drain over a 10-minute match.
7. Verify no black bars reveal the 3D scene behind the hero-selection backdrop on wide displays.

## Acceptance criteria

- No HUD element crosses the reported safe rectangle.
- UI scale remains uniform; no independent X/Y scaling.
- Two-finger pinch never triggers a single-finger target lock.
- Settings modal blocks world taps and mutually excludes SHOP / TALENTS.
- All three quality profiles change only rendering / frame-cap settings, not gameplay balance.
- Android APK export and physical-device results are recorded separately; static validation is not a substitute.
