# Stage 14 — Adaptive layout specification

## Design coordinate system

- Reference canvas: `1280 × 720` (16:9 landscape).
- Every existing HUD widget remains authored in this design space.
- `ArenaMobileLayout` computes one uniform scale and a centered origin from the current viewport and the Android / iOS safe rectangle.
- Both the hero-selection `CanvasLayer` and match HUD `CanvasLayer` receive the same `Transform2D`.
- `SelectionBackdrop` is expanded behind the transformed design canvas so letterbox margins do not expose the arena.
- Touch coordinates are converted back into design coordinates before joystick-zone checks. Target selection keeps the original viewport coordinates for `Camera3D.unproject_position()`.

## Safe-area conversion

`DisplayServer.get_display_safe_area()` and `DisplayServer.screen_get_size()` are used only on Android / iOS. The physical safe rectangle is converted into viewport coordinates using independent X/Y ratios. Invalid or implausibly small safe rectangles fall back to the full viewport rather than hiding controls.

## Input zones

- Joystick start: design X `< 240`, design Y `> 350`.
- World target selection: X `243..1024`, Y `158..511`.
- Camera pinch: both fingers inside X `250..1030`, Y `150..535`.
- Two-finger gestures cancel a pending single-finger target tap.
- Pinch zoom range: `0.78..1.42` camera-offset multiplier.
- Desktop mouse wheel provides equivalent zoom-in / zoom-out steps.

## Display behavior

`window/stretch/mode = canvas_items` and `window/stretch/aspect = expand` keep 3D view coverage on wider landscape displays. HUD content preserves its 16:9 composition and is uniformly scaled into the safe rectangle; no non-uniform stretching is applied.
