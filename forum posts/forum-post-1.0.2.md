**Mine-imator Reforged 1.0.2**

based on Mine-imator 2.0.2



Big content update: tons of new mobs, variants, babies and blocks for the Minecraft 26.2 assets.

**Download:** [Github Release](https://github.com/OmniNodeCo/Mine-imator/releases)

Available for Windows x64, Linux x64, and macOS x86_64.

**What's new**

- **Animal climate variants:** Cows, Pigs and Chickens now come in Temperate / Cold / Warm variants, matching the 26.2 biomes.
- **Wolf biome variants:** Ashen, Black, Chestnut, Rusty, Snowy, Spotted, Striped and Woods wolves, on top of the normal/tame/angry ones.
- **Baby animals:** baby versions of cows, pigs, chickens, wolves (every variant), sheep and all rabbit types — properly proportioned (big head, small body) using the official baby textures.
- **New mobs:** the Breeze, plus Bogged and Parched skeleton variants and the Sulfur Cube from 1.0.1.
- **65 new blocks:** the full copper families (bulb, grate, doors, torches, lanterns, chains, bars, golem statue — with all oxidation stages), cinnabar, sulfur, resin and tuff sets, the pale oak wood set and pale moss, bookshelves for every wood, and all the new plants (firefly bush, leaf litter, cactus flower, wildflowers, eyeblossoms, dried grasses...), plus creaking hearts, dried ghasts, trial spawners, vaults, crafters and heavy cores.
- All new blocks and mobs have proper English names; every 26.2 item texture was already included via the regenerated item sheets.

**Known limitations**

- Armadillo, Creaking, Copper Golem and Happy Ghast still need their rigs authored (their textures use brand-new layouts) — they're next on the list, along with wolf armor.

[spoiler="Show hidden contents — full changelog"]

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
