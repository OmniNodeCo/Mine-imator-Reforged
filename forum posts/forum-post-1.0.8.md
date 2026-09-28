**Mine-imator Reforged 1.0.8**

based on Mine-imator 2.0.2 (Continuation Build 1.0.15 Alpha 1)

The rig center grows up: direct in-app downloads with progress, and a proper two-pane download GUI.

**Download:** [Github Release](https://github.com/OmniNodeCo/Mine-imator-Reforged/releases)

Available for Windows x64, Linux x64, and macOS x86_64.

**What's new**

- **Direct downloads with progress:** community rigs download straight into the app now. WinnyThailandFX's Character Model V3 and V2.3 and his Simple Easy Facial Rig V2 download directly from his Google Drive with a live progress bar, percentage and file size - no browser, no clicking through a download page. Rigs hosted on MediaFire (bWater's IK Rig, Roy Anims' pack) can't be fetched that way; they keep a clearly labeled "Open download page" button. Downloaded packs are verified to be real rig zips, and if a server sends a page instead of the file the app tells you and points you to the author's page.
- **Rig center redesign:** a two-pane download center - searchable list on the left with source tags and live per-rig progress, details on the right with the description, the rig's source, a Download button and the save location. Click a rig to select it, click it again (or hit Download) and choose where to save; the pack is a normal .zip with a .miobject inside that imports via File > Import. The rig library now downloads from the project's own GitHub releases.
- Fixed a stack of rig center issues: the search field overlapping the list, the refresh button sitting on the close button, the details pane and buttons rendering past the popup's bottom edge (which made text disappear), multi-line descriptions garbled by 2-4px line spacing, a failed download blanking the whole catalog, progress overflowing when the server doesn't report a file size, and reopening the window resetting a running download's progress.
- Version bumped to Reforged 1.0.8.

**Known limitations**

- The TV's audio plays in the editor; rendered video exports don't include the TV's audio track yet (only timeline audio tracks are mixed into exports).
- Videos are referenced by file path - if the file is moved or deleted, the TV shows its normal screen again.
- Videos with an aspect ratio other than the TV screen's are stretched to fit.
- H.264 export on Linux works but encodes slower than it could (the bundled x264 is built without assembly for now).
- macOS is x86_64 only - it runs under Rosetta on Apple Silicon machines, but there is no native ARM build.
- The underlying Continuation Build base is alpha quality - expect the occasional rough edge.

[spoiler="Show hidden contents — full changelog"]

[spoiler="Version 1.0.8 (2026-09-28)"]
[b]New features[/b]
- Direct rig downloads with progress: WinnyThailandFX's Character Model V3/V2.3 and Simple Easy Facial Rig V2 download straight into the app from the author's Google Drive (live progress bar, percentage, downloaded size). MediaFire-hosted rigs (bWater's IK Rig, Roy Anims' pack) keep a clearly labeled "Open download page" button. Every download is verified to be a real zip; if a server sends a page instead, the app says so and offers the author's page
- Rig center redesign: two-pane layout (searchable list + details pane with description, source and a proper Download button), source tags and live per-row progress in the list; the rig library downloads from the project's GitHub releases now

[b]Fixes[/b]
- Rig center: the search field overlapped the list and the refresh button sat on the close button
- The details pane, download buttons and the "And N more..." note rendered past the popup's bottom edge (the popup framework's height value overcounts on fixed-size popups), which also made their text disappear - the layout is now anchored to the popup's real bottom edge
- Wrapped text (rig descriptions, error messages) drew its lines only 2-4 pixels apart, garbling multi-line text; line spacing now matches the font height
- Long rig names no longer run under the author label in the list
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

[spoiler="Version 1.0.6 (2026-09-24)"]
[b]New features[/b]
- Curated community rig catalog: WinnyThailandFX's Character Model V3/V2.3 and Simple Easy Facial Rig V2, bWater's Studio's IK Rig and Roy Anims' rig pack open their official download pages; the open-source LapisFR face rig (feminine and masculine) and CC BY-NC-SA piglin models (Alchemist, Traveller) download directly. Reforged's mannequin (IK) and TV/monitor/billboard video screens stay. Full credits, sources and licenses in Rigs/CREDITS.md
- Linked rigs open the author's own download page in your browser (new url_open engine function) - rigs are never re-hosted without permission

[b]Fixes[/b]
- Fixed the TV screen's aspect being squashed to a square that overflowed the TV body (double-normalization in the rig generator)

[b]Versioning[/b]
- Version bumped to Reforged 1.0.6 (full in-app version 2.0.2 Reforged 1.0.6)
[/spoiler]

[spoiler="Version 1.0.5 (2026-09-11)"]
[b]New features[/b]
- Rig catalog doubled to 32 rigs: armor stand (posable arms), oak door (posable hinge), crafting table, furnace, torch, lantern, fence, oak tree, sofa, anvil, cauldron, hay bale, archery target, fire hydrant, stop sign, campfire
- Rig downloads save to a folder of your choice (save dialog, last folder remembered) instead of auto-importing; the pack is a normal .zip with a .miobject inside for easy importing

[b]Fixes[/b]
- Rig packs are proper Mine-imator object files now: every pack contains a .miobject (the Mine-imator object file) plus its .mimodel model and textures. Previously the packs carried a bare .json model, which the importer does not treat as a rig, so nothing imported
- Importing zipped objects/models now also finds .mimodel files inside archives, and prefers .miobject when a zip contains several importable files
- Fixed a crash ("Invalid id 0") when scrolling the rig center list to the bottom
- Video screens (TV, monitor, billboard) now show the full video frame instead of a cropped strip, and work on imported rigs

[b]Versioning[/b]
- Version bumped to Reforged 1.0.5 (full in-app version 2.0.2 Reforged 1.0.5)
[/spoiler]

[spoiler="Version 1.0.4 (2026-09-10)"]
[b]New features[/b]
- Video screens in animations (TVs): the "TV (video screen)" rig plays an attached video file (.mp4/.mov/.avi/.mkv/.webm) on its screen, synced to the animation timeline - scrub, playback and rendered exports all show the right frame. Per-TV volume, up to 8 simultaneous videos, undoable attach/remove, and any model rig with a part textured "screen.png" works as a video screen. FFmpeg decode streams frames into the screen part's texture (CppProject/Media/VideoPlayer.cpp)
- Downloadable rigs center: searchable online rig catalog (Rigs/index.json in the GitHub repo) with one-click download, progress bar and automatic import into the library. Reachable from File > Download rigs and from the workbench create panel. 16 launch rigs including the posable mannequin and stick figure (IK-ready limbs; the mannequin accepts player skins), three video screens (TV, monitor, billboard), furniture and props

[b]Versioning[/b]
- Version bumped to Reforged 1.0.4 (full in-app version 2.0.2 Reforged 1.0.4)
[/spoiler]

[spoiler="Version 1.0.3 (2026-09-07)"]
See the 1.0.3 announcement in this thread - rebuilt on mbanders' Mine-imator 2.0.2 Continuation Build 1.0.15 Alpha 1 with modern Minecraft assets (Armadillo, Creaking, Copper Golem, Happy Ghast, wolf armor, baby variants, climate and wolf biome variants), the pre-1.13 world import fix, restored CI on all three platforms, and the Reforged identity (logo, icon, splash art, gold accent).
[/spoiler]

[/spoiler]
