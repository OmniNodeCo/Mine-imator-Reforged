**Mine-imator Reforged 1.0.1**

based on Mine-imator 2.0.2



Quick maintenance update to Mine-imator Reforged, shipping the biggest asset jump yet and fixing two trial-version annoyances.

**Download:** [Github Release](https://github.com/OmniNodeCo/Mine-imator/releases)

Available for Windows x64, Linux x64, and macOS x86_64.

**What's new**

- **Minecraft 26.2 assets built in:** the bundled asset package jumps from 1.20.2 straight to **26.2**, and 26.2 is now the default for new installs. That's hundreds of new block, item, entity and particle textures, plus all the new blockstates and models, with the texture lists fully regenerated. The old 1.20.2 package has been removed — Settings still lists every version you've downloaded.
- **Credits screen fix:** clicking the "TRIAL" tag next to the version number on the About screen now opens the in-app upgrade dialog — same as the Upgrade button — instead of dumping you on the website. The version number itself still links to the site.
- **Upgrade popup fixes:** opening the upgrade dialog from the Help menu or toolbar and entering a valid key now closes it properly (a stale revert target could make it re-open itself), and a previous "invalid key" warning clears once you upgrade successfully.

**For builders**

- The asset pipeline (`Tools/fetch_minecraft_assets.py`) now uses **26.2** as its template, so future versions inherit the fresh texture lists.
- The release workflow anchors on any committed `Data/Minecraft/<version>.midata` instead of hardcoding `1.20.2`, so future asset bumps can't break bundling.

**Known limitations**

- Textures Mojang renamed between 1.20.2 and 26.2 (and brand-new blocks/mobs) fall back to placeholder graphics until authored rig/spec data catches up — nothing breaks, they just render with stand-ins.

<details><summary><b>Show hidden contents — full changelog</b></summary>

### Minecraft assets

* Bundled Minecraft assets updated from **1.20.2** to **26.2**: `26.2.zip` + `26.2.midata` (built with `Tools/fetch_minecraft_assets.py`, which now uses `26.2` as its template) replace the 1.20.2 package in `Data/Minecraft`
* Default assets version (`#macro minecraft_version`) and the GameMaker included-file list now point at `26.2`; the Settings dropdown picks up every bundled `*.midata` automatically
* Release workflow now anchors on any committed `Data/Minecraft/<version>.midata` instead of hardcoding `1.20.2.midata`

### Fixes

* About (credits) screen: clicking the "TRIAL" tag next to the version number now opens the in-app upgrade dialog (like the "Upgrade" button) instead of sending you to the website; the version number itself still links to the site
* Upgrade popup: entering a valid key after opening the popup directly (Help menu, toolbar) now closes/reverts properly instead of re-opening the upgrade popup via a stale revert target, and a previous "invalid key" warning is cleared on success

### Versioning

* Version bumped to `Reforged 1.0.1` (full in-app version `2.0.2 Reforged 1.0.1`, platform file version `2.0.2.2`)

</details>

---

**If your forum uses BBCode instead of Markdown**, replace the `<details>` block above with this spoiler (everything else stays the same):

```
[spoiler="Show hidden contents — full changelog"]
[b]Minecraft assets[/b]
- Bundled Minecraft assets updated from 1.20.2 to 26.2: 26.2.zip + 26.2.midata (built with Tools/fetch_minecraft_assets.py, which now uses 26.2 as its template) replace the 1.20.2 package in Data/Minecraft
- Default assets version and the GameMaker included-file list now point at 26.2; the Settings dropdown picks up every bundled *.midata automatically
- Release workflow now anchors on any committed Data/Minecraft/<version>.midata instead of hardcoding 1.20.2.midata

[b]Fixes[/b]
- About (credits) screen: clicking the "TRIAL" tag next to the version number now opens the in-app upgrade dialog (like the "Upgrade" button) instead of sending you to the website; the version number itself still links to the site
- Upgrade popup: entering a valid key after opening the popup directly (Help menu, toolbar) now closes/reverts properly instead of re-opening the upgrade popup via a stale revert target, and a previous "invalid key" warning is cleared on success

[b]Versioning[/b]
- Version bumped to Reforged 1.0.1 (full in-app version 2.0.2 Reforged 1.0.1, platform file version 2.0.2.2)
[/spoiler]
```
