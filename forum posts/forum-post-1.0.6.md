**Mine-imator Reforged 1.0.6**

based on Mine-imator 2.0.2 (Continuation Build 1.0.15 Alpha 1)

Two features headline this release: video screens you can put in your animation (TVs), and a downloadable rigs center.

**Download:** [Github Release](https://github.com/OmniNodeCo/Mine-imator-Reforged/releases)

Available for Windows x64, Linux x64, and macOS x86_64.

**What's new**

- **Video screens in animations (TVs):** download the "TV (video screen)" rig from the new rig center, drag it into your scene, select it and attach a video file - .mp4, .mov, .avi, .mkv or .webm - in the Info panel. The video plays right on the TV's screen: scrub the timeline and the TV shows that exact moment, hit play and it plays along with your animation, and rendered images and videos include the video on the screen. Each TV has its own volume control, up to 8 videos can play at the same time, and attaching or removing a video is undoable like any other edit.
- **Downloadable rigs center (File > Download rigs, or the "Download rigs" entry in the workbench create panel):** a curated rig catalog inside the app. The best community rigs are right there: WinnyThailandFX's Character Model V3 and V2.3 and his Simple Easy Facial Rig V2, bWater's Studio's IK Rig and Roy Anims' rig pack (clicking these opens the author's official download page in your browser), plus the open-source LapisFR face rig (feminine and masculine variants) and the CC-licensed Alchemist and Traveller piglin models, which download directly - you choose where to save them (save dialog, folder remembered), and the pack is a normal .zip you can import into any project afterwards via File > Import. The catalog also ships Reforged's own feature rigs: the posable mannequin with IK-ready limbs (works with player skins) and the TV, monitor and billboard video screens for the video feature. Full credits and sources are in the repository (Rigs/CREDITS.md) - big thanks to the rig authors. It will grow with future updates - rig authors can submit more via pull request or issue on GitHub.
- Rigs download to a folder of your choice; the pack contains a .miobject that imports cleanly via File > Import.
- The rig catalog is now a curated community catalog: WinnyThailandFX's Character Model V3/V2.3 and facial rig, bWater's IK Rig and Roy Anims' pack (linked to their official pages), the LapisFR face rig and CC-licensed piglin models (hosted), plus the mannequin and video screens.
- Version bumped to Reforged 1.0.6.

**Known limitations**

- The TV's audio plays in the editor; rendered video exports don't include the TV's audio track yet (only timeline audio tracks are mixed into exports).
- Videos are referenced by file path - if the file is moved or deleted, the TV shows its normal screen again.
- Videos with an aspect ratio other than the TV screen's are stretched to fit.
- H.264 export on Linux works but encodes slower than it could (the bundled x264 is built without assembly for now).
- macOS is x86_64 only - it runs under Rosetta on Apple Silicon machines, but there is no native ARM build.
- The underlying Continuation Build base is alpha quality - expect the occasional rough edge.

[spoiler="Show hidden contents — full changelog"]

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
