# Changelog

This repository carries mbanders' Mine-imator 2.0.2 Continuation Build forward
under the Reforged identity. This changelog covers changes made on top of the
Continuation Build 1.0.15 Alpha 1 base (2026-08-19).

## Reforged on Continuation Build 1.0.15 Alpha 1 (2026-09-07)

### Fixes

* **CI builds failing on all platforms** (`Setup Qt` step): the restored build
  scripts targeted the old dependency pipeline (built FFmpeg 5.1.10 / x264 /
  Libzip 1.11.4 / OpenAL 1.24.3 from vendored sources), but this base's
  CppProject links the **precompiled libraries from `CppProject/External`**
  and only needs the header source trees — FFmpeg 5.0, FreeType 2.9.1,
  Libzip 1.9.2 and OpenAL Soft 1.22.0. The Setup scripts now extract exactly
  those sources into the `DEV_DIR` layout the CMake project expects
  (plus the generated `avconfig.h`/`zipconf.h` headers), the obsolete
  FFmpeg/x264/Libzip/OpenAL build pipelines were removed, and the matching
  source tarballs are vendored in `CppProject/External/Sources/`. OpenSSL
  (Qt on Windows), Jom and the committed Windows SSL libs and macOS
  `libomp.dylib` were restored so the cached Qt builds link again.
* `CppProject/CMakeLists.txt` adaptations for the CI-built Qt: resolve
  `/usr/bin/clang` instead of the missing `clang-12`, use the Qt 5.15.19
  `install` prefix built by the Setup scripts, resolve Homebrew libomp on
  macOS (with the committed x86_64 runtime), and a full installation layout
  (`cmake --install` now produces the packaged `Mine-imator/` folder).
  The project is now CXX-only with `find_package(OpenMP COMPONENTS CXX)` —
  Apple clang cannot supply the OpenMP C bindings the default language
  set demanded
* `CppProject/Asset/Script.hpp`: restored the `ExecuteFunction` function
  pointer alias so generated `Assets.cpp` (from the C++ CppGen) compiles
  against this base's `function<>`-based Script constructor
* Linux CI installs the system libraries this CppProject links
  (x264, gnutls, nettle, sndio, va, vdpau, bz2, lzma)

* **World import (pre-1.13 worlds, e.g. 1.12.2):** block ids of 256 and above
  are stored in the chunk section's `Add` array (the high bits of each id).
  The importer only read the low `Blocks` byte, so worlds containing such
  blocks (typical for Forge/modded 1.12.2 worlds) imported them as the
  vanilla block matching the wrapped low byte — appearing as random blocks
  scattered all over the import. `Add` is now parsed, and ids >= 256, which
  have no vanilla mapping, import as air instead of the wrong block.
  The same fix is applied to legacy `.schematic` imports, which have the
  equivalent `AddBlocks` array (WorldEdit format).

### Added

* Automated cross-platform CI/CD restored and adapted to this base: Build
  check workflow (CppGen validation, asset pipeline checks, Windows/Linux/
  macOS builds, auto-build after tag-triggered releases) and the Release
  workflow (version parsing for `Continuation Build X`, asset bundling from
  the bundled 26.3-snapshot-9 template)
* Build tooling restored: Setup.sh / Setup.ps1, Makefile, BUILD.md, and the
  cross-platform C++ CppGen (coexists with the C# CppGen; verified converting
  this tree's GML)
* Reforged identity restored: gold REFORGED logo lockup, app icon, Branding
  assets, and the gold loading-screen artwork recolors (continuation's new
  splashes kept)
* Theme: the Reforged gold is now the default UI accent color for new users

### Project

* README rewritten for the new base: version table (Mine-imator 2.0.2 →
  Continuation Build 1.0.15 Alpha 1 → bundled Minecraft 26.3-snapshot-9
  assets), build and release instructions, credits for the continuation
  upstream
