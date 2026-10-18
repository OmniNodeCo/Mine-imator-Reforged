**Mine-imator Reforged 1.1.10**

based on Mine-imator 2.0.2 (Continuation Build 1.0.15 Alpha 1)

Mine-imator Reforged now speaks **more than English** - and every Reforged menu shows the version it shipped in.

**Download:** [Github Release](https://github.com/OmniNodeCo/Mine-imator-Reforged/releases)

Available for Windows x64, Linux x64, and macOS x86_64.

**New**

- **Multiple language support.** Pick your language under Settings > Interface > Language:
  - **Simplified Chinese** (by 飒爽师叔, translated for the Continuation Build line - bundled via github.com/vlssu/Mine-imator-Chinese) covers about 94% of the texts, **Italian** (by Lorenzo Giannini - github.com/Loweredgames/Mine-imator_traduzione_ita) about 80%. Anything a translation is missing - mostly the newer Reforged features like the world generator and content center - simply shows in English; the log lists every missing key so translators can complete a file.
  - Drop any .milanguage file into the Data/Languages folder and it appears in the picker automatically - no import needed (the + button still imports from anywhere on disk). Community translations for 2.0.2-era Mine-imator work as-is.
  - A Chinese locale automatically switches the interface fonts to bundled Noto Sans SC subsets (~600 KB per weight, cut down to just the glyphs the interface needs, so the download and memory stay lightweight). Switching between Latin and Chinese languages saves your choice with a restart notice so the right fonts load.
  - Under the hood the language pipeline got fixed for real-world files: UTF-8 translations now load correctly (non-ASCII text is escaped for the parser - before, only specially pre-escaped files worked), and a chr() bug that truncated every Unicode code point above 255 (Chinese displayed as garbage) is fixed. Loading a partially-translated language no longer spams a dialog.
- **Version comments on the menus.** Every Reforged feature popup shows the version it shipped in, right in the title bar: Content center (Reforged 1.1.3), Timeline physics (1.1.1), Performance checker (1.1.4), World generator (1.1.7), Addons (1.1.1).

**Changed**

- Nothing else - this is a focused language + polish release on top of 1.1.9.

**Known limitations**

- The bundled fonts cover English/Latin and the Chinese interface set; other scripts (e.g. Japanese, Korean, Cyrillic) display only what the regular fonts contain - a Japanese or Korean translation would need its own font subset bundled first.
- Translations are community-maintained and trail the newest features - the world generator, content center, physics, performance checker and addons menus will show in English until the translations catch up (the log lists exactly which keys are missing).
- The Chinese font subset covers the interface translation; rare Chinese characters typed into text fields may not display.
- The seed engine is Minecraft's, the terrain is Reforged's: a seed won't reproduce the exact world vanilla Minecraft would make for it - but the same seed always gives the same Reforged world.
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

[spoiler="Version 1.1.10 (2026-10-18)"]
[b]New features[/b]
- Multiple language support (Settings > Interface > Language): bundled Simplified Chinese (~94% of texts, by 飒爽师叔 via github.com/vlssu/Mine-imator-Chinese, translated for the Continuation Build line) and Italian (~80%, by Lorenzo Giannini via github.com/Loweredgames/Mine-imator_traduzione_ita) alongside English; missing texts display in English and are listed in the log; any .milanguage dropped into Data/Languages appears in the picker automatically; Chinese locale switches the interface fonts to bundled Noto Sans SC subsets (~600 KB per weight, glyph-subset to stay lightweight), switching between Latin and Chinese saves with a restart notice; language pipeline fixes - UTF-8 translation files now load correctly (non-ASCII escaped for the parser, previously only pre-escaped files worked) and chr() no longer truncates Unicode code points above 255; partial translations no longer spam a missing-texts dialog (log only)
- Version comments on the Reforged feature popups' title bars: Content center (1.1.3), Timeline physics (1.1.1), Performance checker (1.1.4), World generator (1.1.7), Addons (1.1.1)

[b]Versioning[/b]
- Version bumped to Reforged 1.1.10 (full in-app version 2.0.2 Reforged 1.1.10)
[/spoiler]

[spoiler="Version 1.1.9 (2026-10-15)"]
[b]New features[/b]
- World generator: Minecraft seed engine - seeds parsed like Minecraft (plain number = world seed, other text = Java String.hashCode, empty = fresh random seed every generate), dice button to roll a seed into the field, seed shown in toast/log, Minecraft-style signed seed display; randomness is a faithful port of java.util.Random's 48-bit LCG seeded per position like Minecraft's feature placement (worldSeed + x * 341873128712 + z * 132897987541 + salt, structure-style salts per octave/feature), all in small exact double math (lightweight for Mine-imator); same seed + settings = same world, but seeds from 1.1.7/1.1.8 now generate different worlds
- Discord: startup screen header button + About popup button now open the Reforged community server (discord.gg/Kw9AGWBbK)

[b]Changes[/b]
- Loading screen: gold Reforged logo replaces the green Mine-imator mascot while assets load
- BETA badges removed from the popups (Content center, Physics, Performance checker, World generator, Addons browser)

[b]Fixes[/b]
- World generator: every world generated in a session was identical - the seed field only rolled a random seed while empty, and after the first roll it never was; an empty field now rolls a fresh seed on every generate, and the field shows a proper "Random (new seed every time)" placeholder (the old tip text used to sit in a field that was never empty)
[/spoiler]

[/spoiler]

**Downloads**

Portable zips and installers are attached to the [Github Release](https://github.com/OmniNodeCo/Mine-imator-Reforged/releases) (Windows x64, Linux x64, macOS x86_64). The download links in this post always point to the latest release.

If you find a bug, report it in this thread - and if you can, attach the project file or a screenshot of what happened. Translators: the log lists every text a translation is missing - translations for the 2.0.2 era are a great starting point, drop them in this thread and they can ship with the next update.
