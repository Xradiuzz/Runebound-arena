# Stage 14 — Android graphics profiles

The in-match SETTINGS panel exposes three live quality profiles. These settings apply to the root viewport and the arena's directional sun, without changing combat values or AI cadence.

| Profile | MSAA 3D | Directional shadows | FPS cap |
|---|---:|---|---:|
| Low | Off | Off | 30 |
| Balanced | 2x | On | 60 |
| High | 4x | On | 60 |

Balanced is the default. Low removes the main shadow pass and MSAA; High selects 4x MSAA. The HUD remains at full canvas resolution in all three profiles.

The profiles are runtime-only in Stage 14. They are not persisted across application restarts yet. The FPS cap is an upper bound, not a guaranteed frame rate; V-Sync and display refresh rate can also constrain presentation. Device-specific FPS, thermals, GPU compatibility and visual quality must be measured on real Android hardware before selecting a permanent default.


The project intentionally retains the GL Compatibility renderer from the previous stages. Godot 4.3 documents 3D buffer scaling as a Forward+ / Mobile renderer feature, not a Compatibility feature, so Stage 14 does not expose a misleading render-scale slider. Moving to the Mobile renderer is a separate renderer migration and requires a device compatibility pass.
