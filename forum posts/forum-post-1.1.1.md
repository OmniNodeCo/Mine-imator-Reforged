**Mine-imator Reforged 1.1.1**

based on Mine-imator 2.0.2 (Continuation Build 1.0.15 Alpha 1)

Physics and addons: bake real motion into your animations and install content packs in one click.

**Download:** [Github Release](https://github.com/OmniNodeCo/Mine-imator-Reforged/releases)

Available for Windows x64, Linux x64, and macOS x86_64.

**What's new**

- **Timeline physics:** Edit > Physics... bakes physics into every selected timeline object as keyframes, starting at the current frame. Four motions: Fall + bounce (gravity and bounciness until the object settles on a floor), Throw (initial velocity on all three axes), Pendulum swing (damped swing around the object's rotation origin), and Settle (spring onto a target height). You control duration and keyframe spacing, every field accepts expressions (try "0.5*2"), and the whole bake is one undoable step - undo removes exactly the keyframes it created, redo puts them back. The baked keyframes are ordinary keyframes: tweak them, ease them, keep them.
- **Addons:** File > Install addon... installs a content pack - a zip with an addon.json manifest and optional shaders/, particles/ and rigs/ folders. Shader packs appear in the camera's "Select shader..." menu, particle presets in the workbench, and rigs stay in the addon's own folder with an "Import rigs into project" button. The new File > Addons... browser lists what's installed, shows each addon's contents, and uninstalls cleanly (it removes exactly the files it installed). Re-installing an addon with the same name replaces it. The format is a few lines of JSON - documented in Data/Addons/README.md - and an example addon (frosty-night.miaddon, a cold moonlit camera grade) ships in the box.
- **Fix:** the downloadable Minecraft asset packages were missing 117 textures (all capes, the camera tripod, the shelf/bed block textures, two map items) - the asset pipeline now carries template textures over so every referenced texture resolves, and a new texture tester tool verifies packages in the browser.
- Version bumped to Reforged 1.1.1.

**Known limitations**

- Physics bakes keyframes; it is not a live simulation - after baking, the motion only changes if you edit the keyframes or bake again.
- Pendulum swing rotates around the object's own rotation origin; parent an object to a path point or another object to swing from a specific pivot.
- Addons can only install content Mine-imator already understands (shader packs, particle presets, rigs) - they cannot add new code or run scripts.
- Shader packs set the camera's effect values for the current frame (like editing them by hand); if your camera uses keyframed effects, apply the pack at each keyframe you want it on.
- The TV's audio plays in the editor; rendered video exports don't include the TV's audio track yet (only timeline audio tracks are mixed into exports).
- H.264 export on Linux works but encodes slower than it could (the bundled x264 is built without assembly for now).
- macOS is x86_64 only - it runs under Rosetta on Apple Silicon machines, but there is no native ARM build.
- The underlying Continuation Build base is alpha quality - expect the occasional rough edge.

[spoiler="Show hidden contents — full changelog"]

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
