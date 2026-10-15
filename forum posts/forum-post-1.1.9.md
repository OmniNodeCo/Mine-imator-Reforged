**Mine-imator Reforged 1.1.9**

based on Mine-imator 2.0.2 (Continuation Build 1.0.15 Alpha 1)

The world generator now runs on **Minecraft's seed engine** - and it actually rolls a new random world every time you generate.

**Download:** [Github Release](https://github.com/OmniNodeCo/Mine-imator-Reforged/releases)

Available for Windows x64, Linux x64, and macOS x86_64.

**New**

- **World generator: Minecraft seed engine.** Seeds are read exactly the way Minecraft reads them: a plain (optionally negative) number is used as the world seed, any other text (try `herobrine`) is hashed with Java's String.hashCode, and an empty seed field rolls a fresh random seed every time you generate. A dice button next to the field rolls a random seed into the box so you can keep or share it, the seed used shows up in the toast and the log, and seeds display like Minecraft's (big values as negative numbers). Under the hood the randomness is a faithful port of java.util.Random's 48-bit LCG, seeded per position the way Minecraft's worldgen feature placement does it (worldSeed + x * 341873128712 + z * 132897987541 + salt, with structure-style salts per noise octave and feature) - implemented with small exact double math so it stays lightweight on Mine-imator's system. Same seed + same settings = same world, always. (Because the engine changed, a seed from 1.1.7/1.1.8 now generates a different world.)
- **Discord.** The startup screen has a Discord button in the header, and the About popup's Discord button now opens the Reforged community server (discord.gg/Kw9AGWBbK).

**Changed**

- The loading screen now shows the gold Reforged logo instead of the green Mine-imator mascot while the Minecraft assets load.
- Removed the BETA badges from the popups (Content center, Physics, Performance checker, World generator, Addons browser) - those features have shipped.

**Fixed**

- **The world generator kept generating the same world.** The seed field only rolled a random seed while it was empty - and after the first roll it never was, so every world generated in a session came out identical. An empty field now rolls a fresh seed on every generate.

**Known limitations**

- The seed engine is Minecraft's, the terrain is Reforged's: a seed won't reproduce the exact world vanilla Minecraft would make for it (that needs the full Minecraft generation, far too heavy for Mine-imator) - but the same seed always gives the same Reforged world.
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

[spoiler="Version 1.1.9 (2026-10-15)"]
[b]New features[/b]
- World generator: Minecraft seed engine - seeds parsed like Minecraft (plain number = world seed, other text = Java String.hashCode, empty = fresh random seed every generate), dice button to roll a seed into the field, seed shown in toast/log, Minecraft-style signed seed display; randomness is a faithful port of java.util.Random's 48-bit LCG seeded per position like Minecraft's feature placement (worldSeed + x * 341873128712 + z * 132897987541 + salt, structure-style salts per octave/feature), all in small exact double math (lightweight for Mine-imator); same seed + settings = same world, but seeds from 1.1.7/1.1.8 now generate different worlds
- Discord: startup screen header button + About popup button now open the Reforged community server (discord.gg/Kw9AGWBbK)

[b]Changes[/b]
- Loading screen: gold Reforged logo replaces the green Mine-imator mascot while assets load
- BETA badges removed from the popups (Content center, Physics, Performance checker, World generator, Addons browser)

[b]Fixes[/b]
- World generator: every world generated in a session was identical - the seed field only rolled a random seed while empty, and after the first roll it never was; an empty field now rolls a fresh seed on every generate, and the field shows a proper "Random (new seed every time)" placeholder (the old tip text used to sit in a field that was never empty)

[b]Versioning[/b]
- Version bumped to Reforged 1.1.9 (full in-app version 2.0.2 Reforged 1.1.9)
[/spoiler]

[spoiler="Version 1.1.8 (2026-10-12)"]
[b]Fixes[/b]
- Import from world crashed instantly on opening a world: the world importer read chunk and section data without bounds checks in release builds - unrecognized palette entries were silently skipped (shrinking the palette while block indices still referenced the full one), decoded block-palette indices, light arrays, legacy biome arrays and raw region-file chunk headers were all read unchecked; any read past its buffer crashed the app the moment a region file loaded. Now: unreadable palette entries keep the palette aligned (imported as air), out-of-range palette indices fall back to the first entry, short/empty light/biome/Blocks arrays are skipped, chunk headers pointing outside the region file are skipped with a warning, truncated region files are rejected up front, Gzip refuses empty/invalid sizes
- Note: the "[WARNING] Variant: ToInt() invalid type String" log lines at startup are pre-existing (since 1.1.1) and harmless

[b]Versioning[/b]
- Version bumped to Reforged 1.1.8 (full in-app version 2.0.2 Reforged 1.1.8)
[/spoiler]

[/spoiler]

**Downloads**

Portable zips and installers are attached to the [Github Release](https://github.com/OmniNodeCo/Mine-imator-Reforged/releases) (Windows x64, Linux x64, macOS x86_64). The download links in this post always point to the latest release.

If you find a bug, report it in this thread - and if you can, attach the project file or a screenshot of what happened.
