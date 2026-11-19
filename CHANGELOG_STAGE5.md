# Stage 5 changelog — hero roster and unique kits

- Added a pre-match champion selection screen for Warden, Nyxara and Grom.
- Delayed hero, HUD and wave spawning until a champion is selected.
- Added `hero_id` to actors and hero-specific base stats.
- Added distinct procedural 3D silhouettes for Nyxara and Grom.
- Added reusable `ArenaHeroKit` runtime controller for non-Warden heroes.
- Added data-driven Nyxara and Grom ability definitions.
- Implemented Nyxara Rift Step, Astral Snare, Starfall and Void Eclipse.
- Implemented Nyxara's Rift Echo passive.
- Implemented Grom Savage Leap, Blood Howl, Cleaving Arc and Warpath.
- Implemented Grom's Blood Scent passive and timed bleed damage.
- Added bleed kill attribution and health-bar refresh handling.
- Generalized the existing ability HUD to work with Warden and the new hero controller.
- Added hero-specific ability button palettes and expanded manual verification guidance.
- Retained the existing lane, wave, tower, Ancient, gold, XP, respawn and Warden systems.
