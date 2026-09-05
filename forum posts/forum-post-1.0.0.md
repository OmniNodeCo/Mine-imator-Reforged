**Mine-imator Reforged 1.0.0**

based on Mine-imator 2.0.2



First release of Mine-imator Reforged, a continuation of Mine-imator 2.0.2.

**Download:** [Github Release](https://github.com/OmniNodeCo/Mine-imator/releases)

Available for Windows x64, Linux x64, and macOS x86_64.

**What's new**

- **New Reforged identity:** gold "REFORGED" logo lockup on the startup screen and in the About dialog, recolored app icons and loading artwork, a Reforged section in About with build info, and crash reports/logs that identify Reforged builds.
- **Fresh Minecraft assets in every release:** release builds download and bundle asset packages for Minecraft 1.21 through the newest release, plus the latest pre-release when the next version hasn't fully launched yet (currently 26.3-pre-2). Select them in Settings like any other version; 1.20.2 remains the built-in default.
- **Automated cross-platform builds:** every release is compiled clean on Windows, Linux, and macOS with the newest assets bundled, so downloads stay current without manual repacks.

**For builders**

- One-command setup: `./Setup.sh` (Linux/Mac) or `.\Setup.ps1` (Windows) builds Qt and the dependencies, then produces a Release build. Full steps are in [BUILD.md](http://BUILD.md).
- Builds run non-interactively with `SETUP_NON_INTERACTIVE=1`, which reuses an existing Qt build instead of asking to erase it.

**Known limitations**

- Newer Minecraft packages bring correct textures, but brand-new blocks and mobs stay unavailable until rig/spec data is authored for them. Missing entries fall back to placeholders gracefully instead of breaking anything.

[spoiler="Show hidden contents — full changelog"]
First release of Mine-imator Reforged, based on Mine-imator 2.0.2.

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
