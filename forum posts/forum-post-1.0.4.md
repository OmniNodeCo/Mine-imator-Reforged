**Mine-imator Reforged 1.0.4**

based on Mine-imator 2.0.2 (Continuation Build 1.0.15 Alpha 1)

Two features headline this release: an in-app video player, and a downloadable rigs center.

**Download:** [Github Release](https://github.com/OmniNodeCo/Mine-imator-Reforged/releases)

Available for Windows x64, Linux x64, and macOS x86_64.

**What's new**

- **Video player (File > Video player):** open a video file - .mp4, .mov, .avi, .mkv or .webm - and play it right inside Mine-imator. No more alt-tabbing to an external player when you need reference footage for an animation. Play/pause with the button or the spacebar, click or drag the seek bar to scrub (with a time readout), and adjust the volume. Video and audio are decoded with the same FFmpeg setup the app already uses for sound and video export, so anything you can export, you can play back.
- **Downloadable rigs center (File > Download rigs):** browse a small online rig library from inside the app, search it by name, author or description, and download rigs with one click - a progress bar shows the download and the rig is imported into your project automatically. Downloaded rigs are saved to the Rigs folder next to the executable, so they can be re-imported any time. The catalog ships with three starter rigs (wooden crate, traffic cone, speaker) and will grow with future updates. Rig authors: the catalog is just a folder in the GitHub repository - submit more rigs via pull request or issue.
- Version bumped to Reforged 1.0.4.

**Known limitations**

- H.264 export on Linux works but encodes slower than it could (the bundled x264 is built without assembly for now).
- macOS is x86_64 only - it runs under Rosetta on Apple Silicon machines, but there is no native ARM build.
- The video player is a playback/reference tool - videos are not embedded into the animation or the timeline.
- The underlying Continuation Build base is alpha quality - expect the occasional rough edge.

[spoiler="Show hidden contents — full changelog"]

[spoiler="Version 1.0.4 (2026-09-10)"]
[b]New features[/b]
- In-app video player (File > Video player): play .mp4, .mov, .avi, .mkv and .webm files inside the app, with play/pause (button or spacebar), a click/drag seek bar with time display, and volume controls. FFmpeg decode streams frames to a texture with smooth scaling; the file's audio plays through the regular sound system and drives the playback clock (frame-delta fallback for silent files). Backed by 14 new video_* GML functions.
- Downloadable rigs center (File > Download rigs): searchable online rig catalog with one-click download, progress bar and automatic import into the project's resources. Rigs land in the Rigs folder next to the exe. Catalog lives at Rigs/ in the GitHub repo - starter rigs: wooden crate, traffic cone, speaker.

[b]Versioning[/b]
- Version bumped to Reforged 1.0.4 (full in-app version 2.0.2 Reforged 1.0.4)
[/spoiler]

[spoiler="Version 1.0.3 (2026-09-07)"]
See the 1.0.3 announcement in this thread - rebuilt on mbanders' Mine-imator 2.0.2 Continuation Build 1.0.15 Alpha 1 with modern Minecraft assets (Armadillo, Creaking, Copper Golem, Happy Ghast, wolf armor, baby variants, climate and wolf biome variants), the pre-1.13 world import fix, restored CI on all three platforms, and the Reforged identity (logo, icon, splash art, gold accent).
[/spoiler]

[/spoiler]
