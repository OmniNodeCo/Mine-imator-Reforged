**Mine-imator Reforged 1.1.6**

based on Mine-imator 2.0.2 (Continuation Build 1.0.15 Alpha 1)

Ragdoll physics fixed: it now properly crumples characters and mobs.

**Download:** [Github Release](https://github.com/OmniNodeCo/Mine-imator-Reforged/releases)

Available for Windows x64, Linux x64, and macOS x86_64.

**What's new**

- **Ragdoll works on characters and mobs (and ModelBench/model rigs):** the 1.1.5 ragdoll read a scenery-style flat part list, so on characters it missed every nested body part and made parts sink through each other while the rig never actually fell. Reworked: the rig itself drops to the floor with gravity and an exact landing frame, tipping over as it falls, while the full body-part tree flops around its joints like damped pendulums, staggered by chain depth (torso first, limbs whip after). Amplitude, period and damping are configurable, each part gets its own swing phase, and leaving Floor Z empty drops the rig onto the world ground (Z = 0) - set it when your rig starts above higher ground. Sceneries keep their own mode (Scenery collapse).

**Known limitations**

- Ragdoll is a per-part bake, not a live solver: parts swing on their joints but don't collide with each other or the ground plane beyond the Floor Z level.
- Scenery collapse treats blocks as one-block cubes on a grid; rotated or scaled scenery blocks collapse by their block position, not their rotated shape.
- The performance verdict is a threshold on the stress-test score (45 FPS under load); refresh-rate quirks (e.g. a 30 Hz display) can make a capable PC read as low-end - check the score in the popup and pick the mode manually if needed.
- Physics bakes keyframes; it is not a live simulation - after baking, the motion only changes if you edit the keyframes or bake again.
- The Content center needs internet; offline it shows a per-menu error and the rest of the app works normally.
- Addons can only install content Mine-imator already understands (shader packs, particle presets, rigs) - they cannot add new code or run scripts.
- The TV's audio plays in the editor; rendered video exports don't include the TV's audio track yet (only timeline audio tracks are mixed into exports).
- H.264 export on Linux works but encodes slower than it could (the bundled x264 is built without assembly for now).
- macOS is x86_64 only - it runs under Rosetta on Apple Silicon machines, but there is no native ARM build.
- The underlying Continuation Build base is alpha quality - expect the occasional rough edge.

[spoiler="Show hidden contents — full changelog"]

[spoiler="Version 1.1.6 (2026-10-04)"]
[b]Fixes[/b]
- Ragdoll now works on characters and mobs: the 1.1.5 pass read a scenery-style flat part list (only direct parts, local positions treated as world heights, no whole-rig fall) - the rig itself now drops to the floor with gravity and an exact landing frame while tipping over, and the full body-part tree flops around its joints (local-space rotations, part positions untouched), staggered by chain depth; empty Floor Z = world ground (Z = 0); sceneries are no longer counted as rigs (use Scenery collapse)

[b]Versioning[/b]
- Version bumped to Reforged 1.1.6 (full in-app version 2.0.2 Reforged 1.1.6)
[/spoiler]

[spoiler="Version 1.1.5 (2026-10-03)"]
[b]New features[/b]
- Ragdoll physics: sixth physics mode - every body part of the selected rigs falls with gravity and flops around its joint like a damped pendulum, staggered by chain depth (root first, limbs whip after); per-part swing phase, configurable amplitude/period/damping, exact landing frame, parts at floor level only flop, empty Floor Z = the rig's lowest point; fully undoable
- Popup checker dev server: Tools/popup-checker audits all 19 popups (language keys, field initialization, script references, icons, caption keys, custom popup headers, fixed-height dh layout bug class) + a global every-language-key pass, serving a live report on port 8391

[b]Fixes[/b]
- Content center + Addons popups: custom popups never showed their title or BETA badge (framework draws no caption for custom popups) - both now render their own header with icon, title and badge
- Frame editor transition dropdown: looked up "menu"+name keys that don't exist (every item showed fallback text) - now uses the transition* key family with ease direction templates
- Template editor: Block/Model list captions had no language keys
- Watermark align, text align and color picker mode toggle buttons: names had no language keys
- Mac/Linux keybind list: Command/Super/media/search key names had no language keys

[b]Versioning[/b]
- Version bumped to Reforged 1.1.5 (full in-app version 2.0.2 Reforged 1.1.5)
[/spoiler]

[spoiler="Version 1.1.4 (2026-10-03)"]
[b]New features[/b]
- Performance checker: live frame-time monitor (rolling 2-second window) feeding live FPS / average / worst frame stats and a color-coded frame-time graph with the 60 FPS budget line in the new Performance popup; a stress test (blended overdraw + per-quad submission) measures the PC under load and reports a score with a verdict
- Low-end PC mode: automatic first-run detection (invisible test + toast) picks Normal or Low-end; low-end mode disables interface micro-animations, toast/panel animations, popup/panel shadows and foliage wind, and makes editor RENDER views use the fast render path (exports stay full quality); mode is remembered and can be overridden in Settings > Program > Performance (Auto-detect / Normal / Low-end PC + quick switch + last test result)
- FPS counter: optional overlay in the window's top-right corner (Settings > Program > Performance), turns red below 45 FPS

[b]Changes[/b]
- GUI polish: popup captions now support a leading icon (Physics: beaker, Content center: download, Addons: library, Performance: rocket)

[b]Versioning[/b]
- Version bumped to Reforged 1.1.4 (full in-app version 2.0.2 Reforged 1.1.4)
[/spoiler]

[spoiler="Version 1.1.3 (2026-10-01)"]
[b]New features[/b]
- Real gravity (Z axis): the physics baker simulates along the world's up axis - gravity pulls timeline objects down along Z with sub-stepped simulation between keyframes; fall/bounce, throw, pendulum and settle bake true Z motion; the floor parameter is now Floor Z (empty in collapse mode = the scenery's lowest block level)
- Scenery collapse: new fifth physics mode - blocks in the air of a selected scenery fall with gravity onto the block or floor below them (exact landing frame), while floor- or block-supported blocks keep still and get no keyframes
- Content center: File > Content center... (BETA) replaces the rig center - one popup with Rigs / Shader packs / Addons / Particles menus served from flat catalogs on the project's releases; shader packs, addons and particle presets install straight into the app, rigs download to a chosen folder; live progress, search, direct/page sources; Tools/content-server mirrors the layout as a temp dev server

[b]Changes[/b]
- The old rig center popup and its server integration were removed - the content center serves every menu including rigs

[b]Versioning[/b]
- Version bumped to Reforged 1.1.3 (full in-app version 2.0.2 Reforged 1.1.3)
[/spoiler]

[spoiler="Version 1.1.2 (2026-10-01)"]
[b]New features[/b]
- Beta badges: features that are still being tested (timeline physics, addons, the Minecraft shaderpack import) are marked with a BETA badge - in the File and Edit menus, on the Physics and Addons popups, and next to imported packs in the camera's shader menu; shader pack authors can opt in with "beta": true in their .mishader

[b]Versioning[/b]
- Version bumped to Reforged 1.1.2 (full in-app version 2.0.2 Reforged 1.1.2)
[/spoiler]

[spoiler="Version 1.1.1 (2026-09-30)"]
[b]New features[/b]
- Timeline physics: Edit > Physics... bakes physics (fall + bounce, throw, pendulum swing, settle) into all selected timeline objects as keyframes from the current frame, with configurable gravity, bounciness, floor, velocities, swing angle, period, damping, duration and keyframe spacing; expressions accepted in every field; the bake is a single undoable step (undo removes the created keyframes, redo restores them)
- Addons: File > Install addon... installs a zip with an addon.json manifest and optional shaders/, particles/ and rigs/ folders (shader packs -> camera shader menu, particle presets -> workbench, rigs -> the addon's folder); File > Addons... browser lists installed addons with contents, "Import rigs into project" and uninstall; re-installing the same name replaces it; format documented in Data/Addons/README.md, example addon frosty-night.miaddon ships with the app

[b]Fixes[/b]
- Asset packages: release Minecraft packages were missing 117 textures referenced by the manifest (capes, camera tripod, shelf/bed block textures, two renamed map items); the pipeline now carries template-only assets over when the jar lacks them, and Tools/texture-tester verifies every texture of a package in the browser (mirror check + download for missing files)

[b]Versioning[/b]
- Version bumped to Reforged 1.1.1 (full in-app version 2.0.2 Reforged 1.1.1)
[/spoiler]

[spoiler="Version 1.1.0 (2026-09-30)"]
[b]New features[/b]
- Shader packs: File > Install shaders... imports a .mishader pack (small JSON document) into the app's Shaders folder; every camera gets a "Select shader..." menu in the frame editor. Applying a pack resets all effect values to defaults, then applies the pack (tonemapper, exposure, bloom, lens dirt, depth of field, color correction, film grain, vignette, chromatic aberration, distortion) as one undoable step. Five packs ship (Cinematic, Vintage Film, VHS Tape, Dreamy Glow, Bright & Punchy); the format is documented in Data/Shaders/README.md
- Minecraft shaderpack import (Iris/OptiFine): real shaderpack zips (BSL, Complementary, SEUS, Sildur's Vibrant, Chocapic, Photon...) can be installed too; the GLSL cannot run in Mine-imator, so the app generates a hand-tuned look-alike preset per known pack family (generic Minecraft shader look for unknown packs)

[b]Versioning[/b]
- Version bumped to Reforged 1.1.0 (full in-app version 2.0.2 Reforged 1.1.0)
[/spoiler]

[spoiler="Version 1.0.9 (2026-09-28)"]
[b]Fixes[/b]
- Rig center layout: the details pane, download buttons and the "And N more..." note rendered past the popup's bottom edge (the popup framework's height value overcounts on fixed-size popups), which made their text disappear - the layout is now anchored to the popup's real bottom edge
- Wrapped text (rig descriptions, error messages) drew its lines only 2-4 pixels apart, garbling multi-line text; line spacing now matches the font height
- Long rig names no longer run under the author label in the list

[b]Versioning[/b]
- Version bumped to Reforged 1.0.9 (full in-app version 2.0.2 Reforged 1.0.9)
[/spoiler]

[spoiler="Version 1.0.8 (2026-09-28)"]
[b]New features[/b]
- Direct rig downloads with progress: WinnyThailandFX's Character Model V3/V2.3 and Simple Easy Facial Rig V2 download straight into the app from the author's Google Drive (live progress bar, percentage, downloaded size). MediaFire-hosted rigs (bWater's IK Rig, Roy Anims' pack) keep a clearly labeled "Open download page" button. Every download is verified to be a real zip; if a server sends a page instead, the app says so and offers the author's page
- Rig center redesign: two-pane layout (searchable list + details pane with description, source and a proper Download button), source tags and live per-row progress in the list; the rig library downloads from the project's GitHub releases now

[b]Fixes[/b]
- Rig center: the search field overlapped the list and the refresh button sat on the close button
- A failed rig download no longer blanks the whole catalog with an "offline" error - failures show next to the rig and the list stays usable
- Download progress no longer overflows when the server doesn't report a file size (shows downloaded amount + pulsing bar)
- Reopening the rig center during a download keeps the progress instead of resetting it

[b]Versioning[/b]
- Version bumped to Reforged 1.0.8 (full in-app version 2.0.2 Reforged 1.0.8)
[/spoiler]

[spoiler="Version 1.0.7 (2026-09-24)"]
[b]Upgraded assets[/b]
- Minecraft 26.3 final: bundled assets upgraded from the 26.3 snapshot 9 preview to the full 26.3 release, with the final textures and models (including the copper chests and copper golem statues). 26.3 is the default on a fresh install; 26.2 ships alongside it, both selectable in Settings
- Self-hosted asset updates: the in-app asset updater now checks this project's own GitHub releases instead of mineimator.com, so new Minecraft versions can be downloaded straight from the app (Update notification -> download) without shipping a new build

[b]Fixes[/b]
- When the default Minecraft asset version is missing (e.g. a development build without the release assets), the app now falls back to the newest available version in Data/Minecraft instead of failing to start

[b]Versioning[/b]
- Version bumped to Reforged 1.0.7 (full in-app version 2.0.2 Reforged 1.0.7)
[/spoiler]

[/spoiler]
