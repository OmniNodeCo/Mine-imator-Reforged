# Changelog

## Unreleased

### Minecraft assets

* Bundled Minecraft assets updated from **1.20.2** to **26.2**: `26.2.zip` + `26.2.midata` (built with `Tools/fetch_minecraft_assets.py`, which now uses `26.2` as its template) replace the 1.20.2 package in `Data/Minecraft`
* Default assets version (`#macro minecraft_version`) and the GameMaker included-file list now point at `26.2`; the Settings dropdown picks up every bundled `*.midata` automatically
* Release workflow now anchors on any committed `Data/Minecraft/<version>.midata` instead of hardcoding `1.20.2.midata`

### Fixes

* About (credits) screen: clicking the "TRIAL" tag next to the version number now opens the in-app upgrade dialog (like the "Upgrade" button) instead of sending you to the website; the version number itself still links to the site
* Upgrade popup: entering a valid key after opening the popup directly (Help menu, toolbar) now closes/reverts properly instead of re-opening the upgrade popup via a stale revert target, and a previous "invalid key" warning is cleared on success

## Reforged 1.0.0 (2026-09-04)

First release of Mine-imator Reforged, based on Mine-imator 2.0.2.

### Rebrand

* Application renamed to **Mine-imator Reforged**, used in window titles, dialogs, and message boxes
* New logo lockup: the classic Mine-imator wordmark with a gold "REFORGED" tag, shown on the startup screen and in the About dialog
* App icons (Windows/macOS/Linux) and the loading-screen artwork recolored from green to the Reforged gold identity
* About dialog gains a Reforged section with maintainer credit and build version
* Crash reporter and log output identify Reforged and link to its repository

### Versioning

* Introduced the Reforged version line: full version reads `2.0.2 Reforged 1.0.0`
* Platform file versions updated to `2.0.2.1` (`<base version>.<build>`)
* Build system declares the base (`2.0.2`) and Reforged (`1.0.0`) versions in CMake
