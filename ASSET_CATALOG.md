# Runebound Arena — generated asset catalog

All assets listed here were generated specifically for this project in the preparation environment. No external commercial game assets, copyrighted character artwork, or third-party sound recordings are bundled.

## Textures

| File | Size | Integration |
|---|---:|---|
| `assets/textures/moss_ground.png` | 512×512 | Arena ground material |
| `assets/textures/ancient_stone.png` | 512×512 | Three lane surfaces |

## Hero and ability icons

| File | Purpose |
|---|---|
| `assets/icons/hero_warden.png` | Warden selection portrait |
| `assets/icons/hero_nyxara.png` | Nyxara selection portrait |
| `assets/icons/hero_grom.png` | Grom selection portrait |
| `assets/icons/hero_elyra.png` | Elyra selection portrait |
| `assets/icons/hero_vaelis.png` | Vaelis selection portrait |
| `assets/icons/ability_q.png` | Q ability slot |
| `assets/icons/ability_w.png` | W ability slot |
| `assets/icons/ability_e.png` | E ability slot |
| `assets/icons/ability_r.png` | R ability slot |

## Audio (22,050 Hz, mono, 16-bit PCM WAV)

| File | Event |
|---|---|
| `assets/audio/ambient_loop.wav` | Ambient match music loop |
| `assets/audio/ui_select.wav` | Hero selection / UI confirmation |
| `assets/audio/sword_hit.wav` | Hero melee impact |
| `assets/audio/spell_cast.wav` | Player and bot ability cast |
| `assets/audio/hero_death.wav` | Hero death |
| `assets/audio/structure_break.wav` | Tower / Ancient destruction |

## Procedural 3D content

Heroes, lane minions, neutral monsters, towers and the Elder Riftwarden are assembled from Godot primitive meshes by their existing GDScript visual builders. The integrated pass adds rune obelisks, crystal clusters and subtle idle / locomotion motion. These are procedural mesh assemblies, not imported rigged character models; no skeletal animation clips are included.

## Verification

`python3 tools/validate_release.py` checks that all listed assets exist and that their PNG / WAV headers and dimensions are valid, in addition to source integration checks. Godot import, in-engine visuals/audio and Android export still require the GitHub Actions build.
