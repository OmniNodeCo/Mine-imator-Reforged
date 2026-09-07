**Mine-imator Reforged 1.0.3**

based on Mine-imator 2.0.2 (Continuation Build 1.0.15 Alpha 1)



Biggest update yet: Reforged is now built on mbanders' Mine-imator 2.0.2 Continuation Build, an actively maintained continuation of Mine-imator with up-to-date Minecraft support - so everything 1.0.2 was still missing is finally in, natively. On GitHub this release is named Mine-imator Reforged 1.0.15, after the Continuation Build version it ships.

**Download:** [Github Release](https://github.com/OmniNodeCo/Mine-imator/releases)

Available for Windows x64, Linux x64, and macOS x86_64.

**What's new**

- **New base - Continuation Build 1.0.15 Alpha 1:** years of maintenance work on top of Mine-imator 2.0.2: Minecraft asset support through the latest 26.x snapshots, block model fixes (rotation, "all" textures, nocull, flat elements), a particle spawning delay fix and a .mimodel texture scroll feature.
- **Everything 1.0.2 was missing is in, natively:** Armadillo, Creaking, Copper Golem and Happy Ghast characters, wolf armor, and baby versions across the roster (wolf biome variants, all rabbit colors, sheep, horses, climate variants, armadillo, happy ghast and more). No hand-authored stand-ins anymore - the continuation's asset package covers the full modern roster.
- **Variants and new blocks are native now:** temperate/cold/warm animal variants and the eight wolf biome variants come straight from the asset package, replacing 1.0.2's hand-authored rigs, and the copper families, pale oak set, trial spawners, vaults, crafters and heavy cores are all proper native block entries.
- **Old world import fixed:** pre-1.13 worlds (think 1.12.2 Forge/modded) imported blocks with ids of 256 and higher as random wrong blocks - those ids live in a separate array the importer never read. It is read now: modded blocks import correctly, and anything without a vanilla counterpart imports as air instead of the wrong block. Same fix for .schematic imports (WorldEdit's AddBlocks array).
- **Reforged identity on the new base:** the gold logo, app icon and loading-screen artwork are back on this base (the continuation's new splash lines kept), and Reforged gold is the default UI accent color for new users.

**For builders**

- CI is green on all three platforms - Windows x64, Linux x64 and macOS x86_64 - for the first time on this base; the Build check (GML to C++ validation, asset pipeline self-tests, real Release builds) and the Release workflow are fully restored.
- Building from source is documented again: BUILD.md and Setup.ps1 / Setup.sh set up everything, the dependency sources are vendored in the repo (FFmpeg 5.0, FreeType 2.9.1, Libzip 1.9.2, OpenAL Soft 1.22.0), and Qt 5.15.19 LTS is built from source and cached by CI.

**Known limitations**

- H.264 export on Linux works but encodes slower than it could (the bundled x264 is built without assembly for now).
- macOS is x86_64 only - it runs under Rosetta on Apple Silicon machines, but there is no native ARM build.
- The Continuation Build labels itself Alpha 1 - expect the occasional rough edge.
- The About-screen trial tag and upgrade popup fixes from Reforged 1.0.1/1.0.2 were patches to the old codebase and have not been re-applied to this base yet.

[spoiler="Show hidden contents — full changelog"]

[spoiler="Version 1.0.3 (2026-09-07)"]
[b]New base[/b]
- Rebuilt on mbanders' Mine-imator 2.0.2 Continuation Build 1.0.15 Alpha 1 (2026-08-19), carried forward under the Reforged identity
- Continuation maintenance included: modern Minecraft asset support (the dev tree tracks 26.3-snapshot-9), block rotation and "all" texture fix, rotation fix for inverted block models, "nocull" block texture property, flat block elements fix, particle spawning delay fix, .mimodel texture scroll feature

[b]Mobs and blocks[/b]
- Bundled 26.2 asset package generated natively by the continuation's pipeline; the dev template tracks 26.3-snapshot-9 (68 characters, 311 blocks)
- Armadillo, Creaking, Copper Golem and Happy Ghast characters are in - the entire "not yet included" list from 1.0.2 - plus wolf armor
- Native baby versions: wolf biome variants, all rabbit colors, sheep, horses, climate variants, armadillo, happy ghast and more
- Climate variants (temperate/cold/warm) and the eight wolf biome variants are native, replacing 1.0.2's hand-authored rigs; the Sulfur Cube is native too
- Copper families, pale oak set, trial spawners, vaults, crafters, heavy cores and the rest of 1.0.2's hand-added blocks are native block entries now

[b]Fixes[/b]
- World import (pre-1.13 worlds, e.g. 1.12.2 Forge/modded): block ids of 256 and above are stored in the chunk section's Add array, which the importer never read - such blocks imported as the wrong vanilla block, scattering random blocks across the world. Add is now parsed, and ids without a vanilla mapping import as air instead of the wrong block. The same fix applies to legacy .schematic imports (WorldEdit's AddBlocks array)

[b]Build system[/b]
- Build check green on Windows x64, Linux x64 and macOS x86_64 - the first all-green build on this base. CI adapted to the continuation's precompiled External libraries, with the dependency sources vendored in-repo (FFmpeg 5.0, FreeType 2.9.1, Libzip 1.9.2, OpenAL Soft 1.22.0)
- macOS: clang, OpenMP and libomp fixes plus a full install layout; Linux: a static x264 matching the bundled FFmpeg's API (fixes the link on current distros)
- Setup scripts, Makefile, BUILD.md and the cross-platform C++ CppGen restored alongside the original C# CppGen

[b]Versioning[/b]
- The forum line continues as Reforged 1.0.3; the app identifies as "2.0.2 Continuation Build 1.0.15 (Alpha 1)" and the downloads are named Mine-imator-Reforged-1.0.15, following the Continuation Build's version
[/spoiler]

[spoiler="Version 1.0.2 (2026-09-07)"]
[b]Mobs[/b]
- Climate variants for Cow, Pig and Chicken (Temperate / Cold / Warm) as variant states
- Wolf biome variants (Ashen, Black, Chestnut, Rusty, Snowy, Spotted, Striped, Woods) on top of the existing normal/tame/angry
- Baby versions for Cow, Pig, Chicken, Wolf (all variants), Sheep, and all 8 Rabbit variants - scaled rigs with bigger heads using the official baby textures
- Bogged and Parched skeleton variants
- New Breeze character (head + swirling wind base, emissive)

[b]Blocks[/b]
- 65 new block entries for everything added since 1.20.2: full copper families (bars, bulb, chain, grate, lantern, torch, trapdoor, door, chiseled, golem statue, lightning rod - each with Exposed/Weathered/Oxidized stages), cinnabar, sulfur, resin, tuff families, pale oak wood set + pale moss, shelves (all woods), new plants (bush, firefly bush, leaf litter, grasses, cactus flower, wildflowers, golden dandelion, eyeblossoms), creaking heart, dried ghast, trial spawner, vault, crafter, heavy core, and more
- All new blocks and variants have English display names; items were already covered by the regenerated item texture lists

[b]Not yet included[/b]
- Armadillo, Creaking, Copper Golem, Happy Ghast rigs; wolf armor; baby versions of the remaining mobs
[/spoiler]

[spoiler="Version 1.0.1 (2026-09-05)"]
[b]Minecraft assets[/b]
- Bundled Minecraft assets updated from 1.20.2 to 26.2, now the default for new installs
- New Sulfur Cube character (the 26.2 sulfur slime): authored sulfur_cube.mimodel rig (translucent outer shell + inner core) using the split sulfur_cube_outer/sulfur_cube_inner textures
- Release workflow now anchors on any committed Data/Minecraft/<version>.midata instead of hardcoding 1.20.2.midata

[b]Fixes[/b]
- About (credits) screen: clicking the "TRIAL" tag next to the version number now opens the in-app upgrade dialog (like the "Upgrade" button) instead of sending you to the website; the version number itself still links to the site
- About (credits) screen: dialog enlarged so the Reforged credits no longer crowd the link buttons at the bottom
- Upgrade popup: entering a valid key after opening the popup directly (Help menu, toolbar) now closes/reverts properly instead of re-opening the upgrade popup via a stale revert target, and a previous "invalid key" warning is cleared on success

[b]Versioning[/b]
- Version bumped to Reforged 1.0.1 (full in-app version 2.0.2 Reforged 1.0.1, platform file version 2.0.2.2)
[/spoiler]

[spoiler="Version 1.0.0 (2026-09-04)"]
[b]Rebrand[/b]
- Application renamed to Mine-imator Reforged, used in window titles, dialogs, and message boxes
- New logo lockup: the classic Mine-imator wordmark with a gold "REFORGED" tag, shown on the startup screen and in the About dialog
- App icons (Windows/macOS/Linux) and the loading-screen artwork recolored from green to the Reforged gold identity
- About dialog gains a Reforged section with maintainer credit and build version
- Crash reporter and log output identify Reforged and link to its repository

[b]Versioning[/b]
- Introduced the Reforged version line: full version reads 2.0.2 Reforged 1.0.0
- Platform file versions updated to 2.0.2.1 (<base version>.<build>)
- Build system declares the base (2.0.2) and Reforged (1.0.0) versions in CMake
[/spoiler]

[/spoiler]
