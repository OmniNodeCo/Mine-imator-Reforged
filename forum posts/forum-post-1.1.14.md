**Mine-imator Reforged 1.1.14**

based on Mine-imator 2.0.2 (Continuation Build 1.0.15 Alpha 1)

The world generator learns new tricks: **islands, mountains and flat worlds** - and it can build **villages and cities** on them.

**Download:** [Github Release](https://github.com/OmniNodeCo/Mine-imator-Reforged/releases)

Available for Windows x64, Linux x64, and macOS x86_64.

**New: terrain types and structures in the world generator**

Two new option rows in the popup, combining freely with each other and the Caves / Trees / Water toggles - an island village or a mountain city work exactly as they sound:

- **Terrain: Standard, Island, Mountains or Flat** - Standard is the classic rolling hills; **Island** is a lone island with a jittered coastline, surrounded by ocean; **Mountains** adds ridged peaks (the snow line and spruces move in on them); **Flat** is one constant ground level above the water - a clean building base.
- **Buildings: None, Village or City** - a **Village** scatters houses around a well: cobble foundations, log corners, plank walls with glass windows, a doorway facing the well and a stepped plank roof, each house on its own leveled pad that fills valleys and shaves bumps. A **City** flattens a plateau, lays a cobble street grid on it and builds stone-brick towers with glass window rows, doorways to the street, flat roofs and varied heights - with the occasional park lot between them. The plateau is kept solid: no caves open up underneath the buildings.
- Blocks your texture pack does not know simply skip their feature, so the generator keeps working with any pack.

**Known limitations**

- Ragdoll is a per-part bake, not a live solver: parts swing on their joints but don't collide with each other or the ground plane beyond the Floor Z level.
- Physics bakes keyframes; it is not a live simulation - after baking, the motion only changes if you edit the keyframes or bake again.
- The seed engine is Minecraft's, the terrain is Reforged's: a seed won't reproduce the exact world vanilla Minecraft would make for it - but the same seed always gives the same Reforged world.
- The world generator makes heightmap landscapes (hills, caves, islands, mountains, flat land, water, trees) with simple villages and cities - no redstone, interiors or loot; for real worlds use File > Import from world...
- The bundled fonts cover English/Latin and the Chinese interface set; other scripts (e.g. Japanese, Korean, Cyrillic) display only what the regular fonts contain - a Japanese or Korean translation would need its own font subset bundled first.
- Translations are community-maintained and trail the newest features - the world generator, content center, physics, performance checker and addons menus will show in English until the translations catch up (the log lists exactly which keys are missing).
- The Chinese font subset covers the interface translation; rare Chinese characters typed into text fields may not display.
- Scenery collapse treats blocks as one-block cubes on a grid; rotated or scaled scenery blocks collapse by their block position, not their rotated shape.
- The performance verdict is a threshold on the stress-test score (45 FPS under load); refresh-rate quirks (e.g. a 30 Hz display) can make a capable PC read as low-end - check the score in the popup and pick the mode manually if needed.
- The Content center needs internet; offline it shows a per-menu error and the rest of the app works normally.
- Addons can only install content Mine-imator already understands (shader packs, particle presets, rigs) - they cannot add new code or run scripts.
- The TV's audio plays in the editor; rendered video exports don't include the TV's audio track yet (only timeline audio tracks are mixed into exports).
- H.264 export on Linux works but encodes slower than it could (the bundled x264 is built without assembly for now).
- macOS is x86_64 only - it runs under Rosetta on Apple Silicon machines, but there is no native ARM build.
- The underlying Continuation Build base is alpha quality - expect the occasional rough edge.

[spoiler="Show hidden contents — full changelog"]

[spoiler="Version 1.1.14 (2026-10-29)"]
[b]New features[/b]
- World generator: terrain types (Standard / Island / Mountains / Flat) and structures (Village / City) - two new option rows that combine freely; villages scatter leveled-pad houses with glass windows and stepped roofs around a cobble well, cities put a street grid with stone-brick towers and parks on a flattened plateau (kept solid - no caves underneath)

[b]Versioning[/b]
- Version bumped to Reforged 1.1.14 (full in-app version 2.0.2 Reforged 1.1.14)
[/spoiler]

[/spoiler]

**Downloads**

Portable zips and installers are attached to the [Github Release](https://github.com/OmniNodeCo/Mine-imator-Reforged/releases) (Windows x64, Linux x64, macOS x86_64). The download links in this post always point to the latest release.

If you find a bug, report it in this thread - and if you can, attach the project file or a screenshot of what happened.
