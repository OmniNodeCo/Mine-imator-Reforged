**Mine-imator Reforged 1.1.13**

based on Mine-imator 2.0.2 (Continuation Build 1.0.15 Alpha 1)

The world generator now digs **caves and ore veins** into its terrain, adds **islands, mountains and flat worlds**, and can build **villages and cities** on it - snow-capped spruce peaks included.

(Coming from 1.1.11? 1.1.12 fixed the startup crash loop on low-end PCs - that fix is in this build too.)

**Download:** [Github Release](https://github.com/OmniNodeCo/Mine-imator-Reforged/releases)

Available for Windows x64, Linux x64, and macOS x86_64.

**New: caves and richer terrain in the world generator**

The generator's worlds are no longer plain heightmaps - the same seed and settings now produce:

- **Caves** - winding tunnel systems (two independent noise fields, carved where both pass their threshold - Minecraft 1.18's "spaghetti" recipe) plus deeper "cheese" caverns that grow with depth, with occasional entrances breaking through the surface. A new **Caves toggle** in the popup turns them off for flat building worlds, and caves never carve into or under water (the water is a static fill - no floating lakes).
- **Ore veins** - coal, iron, gold, redstone, lapis and diamond, placed as random-walk veins like Minecraft's features, rarer and deeper the more valuable they are (diamond only shows up near the bottom).
- **Stone variety** - blobs of gravel, andesite, granite and diorite through the stone layer, and **sandstone** under beaches and the sea floor.
- **A bedrock floor** with Minecraft's noisy 0 - 2 block edge.
- **Snow caps with spruces** - the tallest terrain gets a snow line, and trees on it grow as spruce with conical leaf crowns instead of oak blobs.
- Blocks your texture pack does not know simply skip their feature (ores, variants, snow, spruce...), so the generator keeps working with any pack.
- **Terrain types** - a new Terrain row in the popup: **Standard** (the classic rolling hills), **Island** (a lone island with a jittered coastline, surrounded by ocean), **Mountains** (ridged peaks - the snow line and spruces move in on them) and **Flat** (one constant ground level, a clean building base).
- **Structures** - a new Buildings row in the popup: **Village** scatters houses around a well (cobble foundations, log corners, plank walls with glass windows, a doorway facing the well, stepped plank roofs - each house levels its own pad), and **City** flattens a plateau and puts a cobble street grid with stone-brick towers on it (glass window rows, doorways to the street, flat roofs, varied heights, the occasional tree-lined park). The options combine freely - an island village or a mountain city work exactly as they sound.

**Fixed**

- **Nearby seeds generated near-identical worlds.** The seed entered the generator's position hashes additively, so seeds a few numbers apart (3 and 5, or 1 and -1) survived the scrambling as nearly the same random streams and came out as essentially the same world. The seed now runs through one extra decorrelating step. Side effect: the same seed produces a different layout than in previous versions.

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

[spoiler="Version 1.1.13 (2026-10-26)"]
[b]New features[/b]
- World generator: caves and a far richer terrain - winding tunnel systems plus deeper caverns with occasional surface entrances (a new Caves toggle in the popup, never carving into or under water), a bedrock floor with Minecraft's noisy edge, sandstone under beaches, random-walk ore veins (coal, iron, gold, redstone, lapis, diamond - rarer and deeper the more valuable), blobs of gravel/andesite/granite/diorite, and snow caps with spruce trees on the tallest terrain. Blocks the texture pack does not know skip their feature
- World generator: terrain types (Standard / Island / Mountains / Flat) and structures (Village / City) - two new option rows that combine freely; villages scatter leveled-pad houses with glass windows and stepped roofs around a cobble well, cities put a street grid with stone-brick towers and parks on a flattened plateau (kept solid - no caves underneath)

[b]Fixes[/b]
- Nearby seeds generated near-identical worlds: the seed entered the position hashes additively, so 3 and 5 (or 1 and -1) came out as essentially the same world; one extra LCG step decorrelates them (the layout of a given seed changes with this fix)

[b]Versioning[/b]
- Version bumped to Reforged 1.1.13 (full in-app version 2.0.2 Reforged 1.1.13)
[/spoiler]

[/spoiler]

**Downloads**

Portable zips and installers are attached to the [Github Release](https://github.com/OmniNodeCo/Mine-imator-Reforged/releases) (Windows x64, Linux x64, macOS x86_64). The download links in this post always point to the latest release.

If you find a bug, report it in this thread - and if you can, attach the project file or a screenshot of what happened.
