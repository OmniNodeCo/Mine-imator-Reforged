# Mine-imator Reforged

[![Build check](https://github.com/OmniNodeCo/Mine-imator-Reforged/actions/workflows/build.yml/badge.svg)](https://github.com/OmniNodeCo/Mine-imator-Reforged/actions/workflows/build.yml)

<p align="center">
  <img src="Branding/logo.png" width="600"/>
  <br/>
  <br/>
  <img src="https://www.mineimatorforums.com/uploads/monthly_2023_03/336815532_programview.png.9212aa1f6d1bed63411408aa5e905ce0.png" width="800"/>
</p>

**Mine-imator Reforged** — the community continuation of [Mine-imator](https://www.mineimator.com), the 3D movie maker based on the sandbox game Minecraft, with over 10 million downloads since its launch in 2012.

This repository carries mbanders' **Mine-imator 2.0.2 Continuation Build** forward with Reforged's gold identity, automated cross-platform builds, and a self-service Minecraft asset pipeline — while staying true to the original.

## Versioning

| Channel | Version | Date |
|---|---|---|
| Base Mine-imator | 2.0.2 | 2023.11.12 |
| Continuation Build ([mbanders](https://github.com/mbandersmc/Mine-imator-2.0.2-Continuation-Build)) | 1.0.15 Alpha 1 | 2026.08.19 |
| Bundled Minecraft assets | 26.3-snapshot-9 | 2026.08.14 |

The full in-app version reads `2.0.2 Continuation Build 1.0.15 (Alpha 1)`.

## What's different in Reforged

* **Reforged identity:** gold "REFORGED" logo lockup, app icons and loading-screen artwork, with the Reforged gold as the default UI accent
* **Automated cross-platform builds:** every push is compiled on Windows x64, Linux x64 and macOS x86_64 by the Build check workflow — no manual repacks
* **One-command releases:** push a `reforged-v*` tag and the Release workflow bundles the newest green build with freshly fetched Minecraft asset packages and publishes a GitHub Release (releases can also be run manually with an optional asset range)
* **Asset pipeline:** `Tools/fetch_minecraft_assets.py` builds Mine-imator asset packages (`<version>.zip` + `.midata`) for any Minecraft version, straight from Mojang's piston-meta service; `make assets` / `make check` wrap it
* **Two CppGen flavors:** the original C# CppGen for Visual Studio users, plus a cross-platform C++ CppGen used by the Setup scripts and CI

## Building

The software is written using GameMaker Language and converted to a separate C++ environment using a custom built GML parser (CppGen). The final executable is built for Windows, Mac OS and Linux using the Qt framework, DirectX/OpenGL rendering and various other libraries.

* **One command:** `./Setup.sh` (Linux/macOS) or `.\Setup.ps1` (Windows) builds Qt and the dependencies, then produces a Release build
* **Convenience targets:** `make release`, `make cppgen`, `make assets`, `make check`
* Full steps and requirements: see [BUILD.md](BUILD.md)

You can open `GmProject/Mine-imator.yyp` directly in GameMaker on Windows (it may need to be converted), but to support all features you must build and run the C++ project.

## Releases

1. Bump `#macro mineimator_version_sub` in `GmProject/scripts/macros/macros.gml`
2. Wait for a green [Build check](https://github.com/OmniNodeCo/Mine-imator-Reforged/actions/workflows/build.yml)
3. Push a tag matching the version, e.g. `git tag reforged-v1.0.15 && git push origin reforged-v1.0.15` — the Release workflow does the rest, and a completed release automatically builds its own tag commit so a re-run bundles fresh binaries

Downloads live on the [releases page](https://github.com/OmniNodeCo/Mine-imator-Reforged/releases).

## Links

* Original website and download: https://www.mineimator.com
* Continuation Build upstream: https://github.com/mbandersmc/Mine-imator-2.0.2-Continuation-Build
* Reforged repository: https://github.com/OmniNodeCo/Mine-imator-Reforged

## Credits

Mine-imator was created by David Andrei, with development by David, Nimi, Marvin and mbanders, and UI/branding by Voxy — see the in-app About dialog for the full credits including beta testers. The 2.0.2 Continuation Build is maintained by mbanders. Reforged is maintained by [OmniNodeCo](https://github.com/OmniNodeCo). Minecraft is a trademark of Mojang Synergies AB; this is an unofficial community continuation, not affiliated with Mojang or Microsoft.
