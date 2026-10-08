**Mine-imator Reforged 1.1.7**

based on Mine-imator 2.0.2 (Continuation Build 1.0.15 Alpha 1)

A built-in **world generator** (no Minecraft world needed), an **exact Ctrl+Z fix for physics bakes**, and clearer physics settings. This release also carries the 1.1.6 ragdoll fix for characters and mobs (previously unreleased).

**Download:** [Github Release](https://github.com/OmniNodeCo/Mine-imator-Reforged/releases)

Available for Windows x64, Linux x64, and macOS x86_64.

**What's new**

- **World generator (File > Generate world...):** need a quick backdrop for a scene? Generate a random blocky landscape - layered hills with grass, dirt and stone, sandy shores, water and oak trees - and it lands straight on your workbench as a scenery. Pick the size (up to 96 x 96 blocks), the height (up to 64) and the roughness (flat plains to steep mountains), toggle trees and water, and hit Generate. The same seed always builds the same world; leave the seed alone and it rolls a fresh one each time. The world is saved as a standard .schematic file in the project's "Generated worlds" folder, so you can re-import, replace and share it like any world import - and it works with any texture pack (blocks your pack doesn't know are swapped for similar ones).
- **Physics settings made self-explanatory:** every motion type in the physics popup now shows a one-line plain-language description right under the radio buttons (what "Settle" does vs "Pendulum swing", what Scenery collapse touches, and so on) - no more guessing which of the six modes does what.

**Fixed**

- **Ctrl+Z after a physics bake crashed the build / destroyed the wrong keyframes.** Undo used to grab the *first* keyframe it found at each bake position and delete it. Since bake keyframes push existing keyframes a frame later, that "first match" was often *your* keyframe - so undo ate your animation and left the baked one behind, sometimes crashing outright. Physics undo/redo is now exact: the bake remembers every keyframe it created and every value it overwrote in keyframes you already had. Ctrl+Z removes exactly the bake's keyframes and restores your values; Ctrl+Y rebuilds the bake precisely. Your own keyframes are never touched - in every one of the six motions. Baking onto an existing keyframe no longer stacks a duplicate keyframe next to it either: the values are written into the keyframe you had and restored on undo.
- **Ragdoll now works on characters and mobs** (carried over from the unreleased 1.1.6): the rig itself falls and tips over while the full body-part tree flops around its joints, staggered by chain depth.

**Known limitations**

- The world generator makes heightmap landscapes (hills, water, trees) - no caves, structures or biomes; for real worlds keep using File > Import from world...
- World generator trees are simple oaks; trunk height and leaf shape vary per seed.
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

[spoiler="Version 1.1.7 (2026-10-08)"]
[b]New features[/b]
- World generator (File > Generate world...): builds a random heightmap landscape (grass/dirt/stone layers, sand shores, optional water and oak trees) from a seed and puts it on the workbench as a new scenery; size 8-96 x 8-96, height up to 64, roughness 0-100, trees/water toggles; same seed = same world, empty seed rolls a new one; writes a standard .schematic into the project's Generated worlds folder and loads it through the normal scenery pipeline (undo restores the previous bench scenery); blocks missing from the current texture pack fall back to similar ones
- Physics popup: one-line plain-language description under the motion radios for each of the six modes

[b]Fixes[/b]
- Ctrl+Z after a physics bake crashed the build / removed the wrong keyframes: undo searched for the first keyframe at each bake position while bakes push existing keyframes aside (tl_keyframe_add bumps positions), so undo destroyed the user's keyframes and left baked orphans behind; undo/redo is now exact - created keyframes are recorded by id and destroyed by id, overwritten values in pre-existing keyframes are recorded and restored, redo rebuilds the bake precisely; bakes reuse existing keyframes at the same position instead of stacking duplicates next to them; applies to all six motions (fall, throw, pendulum, settle, scenery collapse, ragdoll)

[b]Versioning[/b]
- Version bumped to Reforged 1.1.7 (full in-app version 2.0.2 Reforged 1.1.7)
[/spoiler]

[spoiler="Version 1.1.6 (2026-10-04)"]
[b]Fixes[/b]
- Ragdoll now works on characters and mobs: the 1.1.5 pass read a scenery-style flat part list (only direct parts, local positions treated as world heights, no whole-rig fall) - the rig itself now drops to the floor with gravity and an exact landing frame while tipping over, and the full body-part tree flops around its joints (local-space rotations, part positions untouched), staggered by chain depth; empty Floor Z = world ground (Z = 0); sceneries are no longer counted as rigs (use Scenery collapse)

[b]Versioning[/b]
- Version bumped to Reforged 1.1.6 (full in-app version 2.0.2 Reforged 1.1.6)
[/spoiler]

[/spoiler]

**Downloads**

Portable zips and installers are attached to the [Github Release](https://github.com/OmniNodeCo/Mine-imator-Reforged/releases) (Windows x64, Linux x64, macOS x86_64). The download links in this post always point to the latest release.

If you find a bug, report it in this thread - and if you can, attach the project file or a screenshot of what happened.
