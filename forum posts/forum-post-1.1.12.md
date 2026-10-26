**Mine-imator Reforged 1.1.12**

based on Mine-imator 2.0.2 (Continuation Build 1.0.15 Alpha 1)

Quick fix: **the startup crash loop on low-end PCs is fixed** - if the automatic performance detection didn't survive your GPU driver, the app now boots into low-end mode instead of crashing on every start.

**Download:** [Github Release](https://github.com/OmniNodeCo/Mine-imator-Reforged/releases)

Available for Windows x64, Linux x64, and macOS x86_64.

**Fixed**

- **Startup crash loop on low-end PCs.** The automatic performance detection (which runs once, silently, right after the very first start) crashed on machines with weak GPU drivers - and since the crash happened before any verdict was saved, the next start ran the test again and crashed again, trapping a fresh install in a crash loop. The detection now:
  - saves a provisional low-end verdict to settings **before** the stress load is ever drawn - if the app does not survive the test on a weak driver, the next start skips the test entirely and boots straight into low-end mode instead of crashing again. Settings > Program > Performance shows "low-end mode enabled (the automatic test could not complete)", and running the test manually from the popup still records the real verdict and unlocks the normal mode
  - renders the invisible test onto a depthless offscreen surface (depth-stencil renderbuffers are a common failure point on old drivers) - and when the surface cannot be created or bound at all, the test cancels gracefully and keeps the provisional verdict instead of ever drawing the stress load onto the live screen
  - frees the test surface when it finishes or cancels (it previously leaked for the whole session), and the shorter auto-test (60 frames vs. the visible test's 120) only counts frames the offscreen draw actually rendered

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

[spoiler="Version 1.1.12 (2026-10-19)"]
[b]Fixes[/b]
- Startup crash loop on low-end PCs: the automatic performance detection ran on the first start, crashed on weak GPU drivers, and never saved a verdict - so every start ran it again and crashed again. The detection now saves a provisional low-end verdict before the stress load is drawn (a crash mid-test lands in low-end mode, no re-run), renders the invisible test onto a depthless offscreen surface, cancels gracefully when the surface cannot be created or bound (never drawing the load on the live screen), frees the test surface on finish/cancel, and reports the provisional state as its own label in Settings > Program > Performance; the visible manual test is unchanged and always records the real verdict

[b]Versioning[/b]
- Version bumped to Reforged 1.1.12 (full in-app version 2.0.2 Reforged 1.1.12)
[/spoiler]

[/spoiler]

**Downloads**

Portable zips and installers are attached to the [Github Release](https://github.com/OmniNodeCo/Mine-imator-Reforged/releases) (Windows x64, Linux x64, macOS x86_64). The download links in this post always point to the latest release.

If you find a bug, report it in this thread - and if you can, attach the project file or a screenshot of what happened.
