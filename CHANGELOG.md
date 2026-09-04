# Changelog

## Continuation Build 1.0.0 (2026-09-04)

First release of the Mine-imator Continuation Build (Mine-imator CB), based on Mine-imator 2.0.2.

### Rebrand

* Application renamed to **Mine-imator Continuation Build**, with the short name **Mine-imator CB** used in window titles, dialogs, and message boxes
* New logo lockup: the classic Mine-imator wordmark with a gold "CONTINUATION BUILD" tag, shown on the startup screen and in the About dialog
* App icons (Windows/macOS/Linux) and the loading-screen artwork recolored from green to the Continuation Build gold identity
* About dialog gains a Continuation Build section with maintainer credit and build version
* Crash reporter and log output identify the Continuation Build and link to its repository

### Versioning

* Introduced the Continuation Build version line: full version reads `2.0.2 Continuation Build 1.0.0`
* Platform file versions updated to `2.0.2.1` (`<base version>.<build>`)
* Build system declares the base (`2.0.2`) and Continuation Build (`1.0.0`) versions in CMake
