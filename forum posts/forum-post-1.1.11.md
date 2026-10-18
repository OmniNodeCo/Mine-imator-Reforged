**Mine-imator Reforged 1.1.11**

based on Mine-imator 2.0.2 (Continuation Build 1.0.15 Alpha 1)

Quick fix: **ragdoll physics now works on characters and mobs.**

**Download:** [Github Release](https://github.com/OmniNodeCo/Mine-imator-Reforged/releases)

Available for Windows x64, Linux x64, and macOS x86_64.

**Fixed**

- **Ragdoll refused characters and mobs.** The rig check only accepted player characters and model rigs - but mobs are their own timeline type in Mine-imator (special blocks), so with a mob (zombie, creeper, ...) selected the popup said "no rig selected" and Apply stayed disabled. Mobs now count as rigs. Selecting a limb also counts: the workbench selects the body part you click, not the rig root, so ragdolling a character by clicking its arm was refused too - a selected part now resolves to the rig it belongs to and the whole rig is ragdolled as before (never double-counted, even with the root and several limbs selected at once).

**Known limitations**

- Ragdoll is a per-part bake, not a live solver: parts swing on their joints but don't collide with each other or the ground plane beyond the Floor Z level.
- Physics bakes keyframes; it is not a live simulation - after baking, the motion only changes if you edit the keyframes or bake again.
- The seed engine is Minecraft's, the terrain is Reforged's: a seed won't reproduce the exact world vanilla Minecraft would make for it - but the same seed always gives the same Reforged world.
- The bundled fonts cover English/Latin and the Chinese interface set; other scripts (e.g. Japanese, Korean, Cyrillic) display only what the regular fonts contain - a Japanese or Korean translation would need its own font subset bundled first.
- Translations are community-maintained and trail the newest features - the world generator, content center, physics, performance checker and addons menus will show in English until the translations catch up (the log lists exactly which keys are missing).
- The Chinese font subset covers the interface translation; rare Chinese characters typed into text fields may not display.
- The world generator makes heightmap landscapes (hills, water, trees) - no caves, structures or biomes; for real worlds use File > Import from world...
- Scenery collapse treats blocks as one-block cubes on a grid; rotated or scaled scenery blocks collapse by their block position, not their rotated shape.
- The performance verdict is a threshold on the stress-test score (45 FPS under load); refresh-rate quirks (e.g. a 30 Hz display) can make a capable PC read as low-end - check the score in the popup and pick the mode manually if needed.
- The Content center needs internet; offline it shows a per-menu error and the rest of the app works normally.
- Addons can only install content Mine-imator already understands (shader packs, particle presets, rigs) - they cannot add new code or run scripts.
- The TV's audio plays in the editor; rendered video exports don't include the TV's audio track yet (only timeline audio tracks are mixed into exports).
- H.264 export on Linux works but encodes slower than it could (the bundled x264 is built without assembly for now).
- macOS is x86_64 only - it runs under Rosetta on Apple Silicon machines, but there is no native ARM build.
- The underlying Continuation Build base is alpha quality - expect the occasional rough edge.

[spoiler="Show hidden contents — full changelog"]

[spoiler="Version 1.1.11 (2026-10-18)"]
[b]Fixes[/b]
- Ragdoll refused characters and mobs: the rig check only accepted player characters and model rigs, but mobs are their own timeline type (special blocks) - with a mob selected the popup said "no rig selected" and Apply stayed disabled; mobs now count. Selecting a limb also counts (the workbench selects the body part you click, not the rig root) - a selected part resolves to its rig, the whole rig is ragdolled as before, never double-counted

[b]Versioning[/b]
- Version bumped to Reforged 1.1.11 (full in-app version 2.0.2 Reforged 1.1.11)
[/spoiler]

[/spoiler]

**Downloads**

Portable zips and installers are attached to the [Github Release](https://github.com/OmniNodeCo/Mine-imator-Reforged/releases) (Windows x64, Linux x64, macOS x86_64). The download links in this post always point to the latest release.

If you find a bug, report it in this thread - and if you can, attach the project file or a screenshot of what happened.
