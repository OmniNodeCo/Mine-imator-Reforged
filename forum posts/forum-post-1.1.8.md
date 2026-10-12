**Mine-imator Reforged 1.1.8**

based on Mine-imator 2.0.2 (Continuation Build 1.0.15 Alpha 1)

Fixes the **instant crash when opening a world** in Import from world (and makes the whole world importer crash-proof against unusual or slightly corrupt world data).

**Download:** [Github Release](https://github.com/OmniNodeCo/Mine-imator-Reforged/releases)

Available for Windows x64, Linux x64, and macOS x86_64.

**Fixed**

- **Import from world crashed instantly when opening a world.** The importer trusted the world's data everywhere: a block-palette entry it did not recognize was silently skipped (which shifted every block after it), decoded palette indices, light arrays, legacy biome arrays and raw region-file chunk headers were all read without bounds checks - the first value that pointed outside its buffer took the whole app down the moment a region loaded. Every one of those reads is now validated or safely clamped: unrecognized palette entries keep the palette aligned (imported as air), out-of-range palette indices fall back to the first entry, malformed light/biome/Blocks arrays are skipped, chunk headers pointing outside the region file are skipped with a log warning, and truncated region files are rejected up front. A world that used to crash now logs what it skipped and imports the rest.
- If your world still fails to import after this, check `log.txt` for `Invalid section` / `Invalid chunk` lines and post them in this thread - they now say exactly what the importer could not read.

**Known limitations**

- If a world's chunk format drifts from what the importer expects (e.g. a brand-new Minecraft snapshot renaming palette fields), affected sections import as air instead of crashing - the log lists them.
- The world generator makes heightmap landscapes (hills, water, trees) - no caves, structures or biomes; for real worlds use File > Import from world...
- Ragdoll is a per-part bake, not a live solver: parts swing on their joints but don't collide with each other or the ground plane beyond the Floor Z level.
- Scenery collapse treats blocks as one-block cubes on a grid; rotated or scaled scenery blocks collapse by their block position, not their rotated shape.
- Physics bakes keyframes; it is not a live simulation - after baking, the motion only changes if you edit the keyframes or bake again.
- The performance verdict is a threshold on the stress-test score (45 FPS under load); refresh-rate quirks (e.g. a 30 Hz display) can make a capable PC read as low-end - check the score in the popup and pick the mode manually if needed.
- The Content center needs internet; offline it shows a per-menu error and the rest of the app works normally.
- Addons can only install content Mine-imator already understands (shader packs, particle presets, rigs) - they cannot add new code or run scripts.
- The TV's audio plays in the editor; rendered video exports don't include the TV's audio track yet (only timeline audio tracks are mixed into exports).
- H.264 export on Linux works but encodes slower than it could (the bundled x264 is built without assembly for now).
- macOS is x86_64 only - it runs under Rosetta on Apple Silicon machines, but there is no native ARM build.
- The underlying Continuation Build base is alpha quality - expect the occasional rough edge.

[spoiler="Show hidden contents — full changelog"]

[spoiler="Version 1.1.8 (2026-10-12)"]
[b]Fixes[/b]
- Import from world crashed instantly on opening a world: the world importer read chunk and section data without bounds checks in release builds - unrecognized palette entries were silently skipped (shrinking the palette while block indices still referenced the full one), decoded block-palette indices, light arrays, legacy biome arrays and raw region-file chunk headers were all read unchecked; any read past its buffer crashed the app the moment a region file loaded. Now: unreadable palette entries keep the palette aligned (imported as air), out-of-range palette indices fall back to the first entry, short/empty light/biome/Blocks arrays are skipped, chunk headers pointing outside the region file are skipped with a warning, truncated region files are rejected up front, Gzip refuses empty/invalid sizes
- Note: the "[WARNING] Variant: ToInt() invalid type String" log lines at startup are pre-existing (since 1.1.1) and harmless

[b]Versioning[/b]
- Version bumped to Reforged 1.1.8 (full in-app version 2.0.2 Reforged 1.1.8)
[/spoiler]

[spoiler="Version 1.1.7 (2026-10-08)"]
[b]New features[/b]
- World generator (File > Generate world...): builds a random heightmap landscape (grass/dirt/stone layers, sand shores, optional water and oak trees) from a seed and puts it on the workbench as a new scenery; Small (32) / Medium (64) / Large (96) size presets like the world import selection or a custom size (8-96 x 8-96), height up to 64, roughness 0-100, trees/water toggles; same seed = same world, empty seed rolls a new one; writes a standard .schematic into the project's Generated worlds folder and loads it through the normal scenery pipeline (undo restores the previous bench scenery); blocks missing from the current texture pack fall back to similar ones
- Physics popup: one-line plain-language description under the motion radios for each of the six modes
- Extras: walk & run cycle generators (offline HTML tools in the extras folder) that export .miframes character animation with sliders and a live preview; walk generator originally by eysnaafo (Discord, file was truncated - completed), run generator new on the same core (knee drive, flight phase, pumping elbows that open on the back swing and close on the forward swing, lean); presets, editable values, scrub bar, Space/click to pause; fixed the inherited double head/arm bob on default rigs (head/arms are body children and now ride the body's bob, Flat rig option for custom root-level rigs)

[b]Fixes[/b]
- Ctrl+Z after a physics bake crashed the build / removed the wrong keyframes: undo searched for the first keyframe at each bake position while bakes push existing keyframes aside (tl_keyframe_add bumps positions), so undo destroyed the user's keyframes and left baked orphans behind; undo/redo is now exact - created keyframes are recorded by id and destroyed by id, overwritten values in pre-existing keyframes are recorded and restored, redo rebuilds the bake precisely; bakes reuse existing keyframes at the same position instead of stacking duplicates next to them; applies to all six motions (fall, throw, pendulum, settle, scenery collapse, ragdoll)
- World generator: the generated world never loaded - the Generate button closed the popup right after queueing the scenery load, and closing it cancelled the loading screen (which runs the load) before it started; the loading screen now takes over and closes itself when done; roughness is rounded to a whole number and the generated file name includes the roughness/trees/water settings

[b]Versioning[/b]
- Version bumped to Reforged 1.1.7 (full in-app version 2.0.2 Reforged 1.1.7)
[/spoiler]

[/spoiler]

**Downloads**

Portable zips and installers are attached to the [Github Release](https://github.com/OmniNodeCo/Mine-imator-Reforged/releases) (Windows x64, Linux x64, macOS x86_64). The download links in this post always point to the latest release.

If you find a bug, report it in this thread - and if you can, attach the project file or a screenshot of what happened.
