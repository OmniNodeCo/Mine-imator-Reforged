# Changelog

This repository carries mbanders' Mine-imator 2.0.2 Continuation Build forward
under the Reforged identity. This changelog covers changes made on top of the
Continuation Build 1.0.15 Alpha 1 base (2026-08-19).

## Reforged 1.1.7 (2026-10-08)

### New features

* **World generator.** File > Generate world... builds a random blocky
  landscape - layered hills with grass, dirt and stone, sandy shores,
  optional water and oak trees - and puts it straight onto the workbench
  as a new scenery. Pick a size with the Small (32) / Medium (64) /
  Large (96) presets - like the world import's selection sizes - or type
  a custom size (8 - 96 blocks square), a height (up to 64) and a
  roughness; the same seed always produces the same world, and an empty
  seed rolls a fresh one every time. The world is written as a standard
  .schematic file in the project's `Generated worlds` folder (so it can
  be re-imported, replaced and shared like any world import), then
  loaded through the normal scenery pipeline. Blocks the current
  texture pack does not know are swapped for similar ones, so the
  generator works with any pack. Fully undoable: undo puts the previous
  bench scenery back on the bench
* **Physics popup: plain-language motion descriptions.** Every motion
  type now shows a one-line description of what it does right under the
  radio buttons, so the six modes are self-explanatory without trying
  them one by one

### Fixes

* **Ctrl+Z after a physics bake could crash the build (and destroy the
  wrong keyframes).** Undo used to search each timeline for the *first*
  keyframe at the bake's position and destroy it - but adding a bake
  keyframe at an occupied position shifts any existing keyframe one
  frame later, so after a couple of bakes the "first match" was the
  user's own keyframe: undo ate it and left the baked ones behind,
  sometimes crashing outright. Physics undo/redo is now exact: the bake
  records every keyframe it creates (by id) and every value it
  overwrites inside keyframes you already had; undo removes exactly the
  created keyframes and restores the overwritten values, redo rebuilds
  the bake precisely - your own keyframes are never touched. Applies to
  all six motions (fall, throw, pendulum, settle, scenery collapse,
  ragdoll). Bakes onto existing keyframes no longer stack duplicate
  keyframes next to them either: the values are written into the
  keyframe you had, and restored on undo
* **World generator: the generated world never loaded.** The Generate
  button closed the generator popup right after starting the scenery
  load - but the load runs through the loading-screen popup, and
  closing it cancelled the load before a single block was read (the
  resource sat in the load queue forever and the bench never changed).
  The loading screen now takes over cleanly and closes itself when the
  world is in. The generated file name now also includes the roughness,
  trees and water settings, so different settings with the same seed
  produce separate, clearly named files

## Reforged 1.1.6 (2026-10-04)

### Fixes

* **Ragdoll now works on characters and mobs.** The 1.1.5 ragdoll read a
  rig's flat part list - a scenery-style structure - so on characters
  and mobs it only caught the direct body parts (missing every nested
  subpart) and treated the parts' local positions as world heights,
  making them sink through each other while the rig as a whole never
  fell. Reworked: the rig itself (character, mob or model rig) now
  drops to the floor with gravity and an exact landing frame, tipping
  over as it falls, while the *full* body-part tree flops around its
  joints like damped pendulums, staggered by chain depth - rotations
  are baked in each part's local space (the joint rotation), part
  positions stay untouched. Empty Floor Z drops the rig onto the world
  ground (Z = 0); set it when the rig starts above higher ground.
  Selecting a scenery no longer counts as a rig (use Scenery collapse
  for sceneries)

## Reforged 1.1.5 (2026-10-03)

### New features

* **Ragdoll physics.** The physics popup's sixth mode crumples player and
  character rigs part by part: every body part falls with gravity and
  flops around its joint like a damped pendulum, staggered by chain
  depth - the root drops first and the limbs whip after it, so a
  selected rig collapses like a puppet instead of moving as one block.
  Swing amplitude, period and damping are configurable, each part gets
  its own swing phase, the fall lands on an exact frame, parts at floor
  level only flop, and an empty Floor Z drops parts onto the rig's own
  lowest point. Fully undoable like every other bake
* **Popup checker dev server.** `Tools/popup-checker` audits every popup
  of the app (19 today) and serves a live report in the browser
  (`python3 Tools/popup-checker/server.py`, port 8391): language keys,
  field initialization, script references, icons, caption keys, custom
  popup headers and the fixed-height `dh` layout bug class - plus a
  global pass over every literal language key used anywhere in the
  sources. The report regenerates from the code on every refresh

### Fixes (found by the popup checker audit)

* **Content center + Addons popups showed no title or BETA badge.** Both
  are custom popups, and the popup framework draws no caption for those
  - their badge was set but never rendered. Both popups now render
  their own header: icon, title and the BETA badge
* **Frame editor transition dropdown showed fallback text for every
  transition.** It looked up `"menu" + name` language keys that do not
  exist; it now uses the `transition*` key family, with the ease
  direction templates ("Quadratic (Ease in)" and friends)
* **Template editor:** the Block and Model list captions had no
  language keys (Body part existed alone)
* **Watermark align, text align and color picker mode buttons:** toggle
  button names without language keys
* **Mac/Linux keybind list:** Command, Super, media and search key
  names had no language keys - the keybind settings showed fallback
  text for those keys on macOS and Linux

## Reforged 1.1.4 (2026-10-03)

### New features

* **Performance checker.** A live performance monitor now runs under the
  interface: every frame time is recorded into a rolling two-second
  window, and the new **Performance** popup (Settings > Program >
  Performance > **Run performance test...**) shows live FPS, average and
  worst frame time, a color-coded frame-time graph with the 60 FPS
  budget line, and a stress test that measures the PC under real load
  (blended overdraw + per-quad submission - the same costs heavy camera
  effects have) and reports a score with a clear verdict
* **Low-end PC mode, detected automatically.** On the very first start
  the checker runs its test invisibly and picks the mode for you: a
  capable PC keeps the full interface, a low-end PC gets low-end mode -
  interface micro-animations, toast and panel animations off, popup and
  panel shadows off, foliage wind off, and editor RENDER views using the
  fast render path (full-quality rendering still applies to every
  export). The result is remembered, reported with a toast, and can be
  overridden anytime: **Settings > Program > Performance** has the mode
  (Auto-detect / Normal / Low-end PC), a quick low-end switch, the last
  test result, and the test button
* **FPS counter.** Settings > Program > Performance can pin a small FPS
  counter to the top-right corner of the window; it turns red when the
  framerate drops below 45

### Changes

* **GUI polish:** popups now show an icon next to their caption -
  Physics a beaker, the Content center a download arrow, Addons a
  library and the new Performance popup a rocket - with the BETA badge
  still following the title

## Reforged 1.1.3 (2026-10-01)

### New features

* **Real gravity (Z axis).** The physics baker now simulates along the
  world's actual up axis: gravity pulls timeline objects down along Z
  towards the ground plane, with sub-stepped simulation between
  keyframes so fast falls and bounces land exactly where they should.
  Fall/bounce, throw, pendulum and settle all bake true Z motion, and
  the floor parameter is now **Floor Z** (leave it empty in scenery
  collapse to use the scenery's own lowest block level)
* **Scenery collapse.** The physics popup's new fifth mode drops every
  block of the selected sceneries that is *in the air* onto the block
  or floor below it - a block resting on the floor or on another block
  keeps perfectly still and gets no keyframes at all. Import a world or
  schematic, select it, bake: unsupported columns crumble with real
  gravity and an exact landing frame, supported ones stand still
* **Content center.** The rig center grew into a full content center
  (**File > Content center...**, still BETA): one popup with four menus
  - **Rigs**, **Shader packs**, **Addons** and **Particles** - each
  served from flat catalogs on the content server. Rigs download to a
  location of your choice; shader packs, addons and particle presets
  install straight into the app in one click, with live download
  progress, search across every menu, and direct-download or
  open-the-author's-page handling per item. The Release workflow now
  stages all four catalogs, and `Tools/content-server` mirrors the
  whole layout as a temp dev server for local development

### Changes

* The old rig center popup and its server integration were removed -
  the content center serves every menu including rigs (the workbench
  "Download rigs" button and the File menu entry open it on the rigs
  menu)

## Reforged 1.1.2 (2026-10-01)

### New features

* **Beta badges.** Features that are still being tested - timeline physics,
  addons and the Minecraft shaderpack import - are marked with a BETA badge
  in the menus, on the Physics and Addons popups, and next to imported packs
  in the camera's shader menu (shader pack authors can opt in with
  `"beta": true` in their pack)

## Reforged 1.1.1 (2026-09-30)

### New features

* **Timeline physics.** **Edit > Physics...** bakes physics motion into every
  selected timeline object as keyframes, starting at the current frame: drop
  an object with gravity and bounciness until it settles on a floor, throw
  it with an initial velocity, swing it like a damped pendulum, or let it
  settle onto a target with a spring. Duration and keyframe spacing are
  configurable, every parameter accepts expressions, and the whole bake is
  a single undoable step - the keyframes it created are removed on undo and
  restored on redo, ready to hand-tune afterwards
* **Addons.** **File > Install addon...** installs an addon - a zip with an
  `addon.json` manifest and optional `shaders/`, `particles/` and `rigs/`
  folders. Shader packs land in the camera's **Select shader...** menu,
  particle presets in the workbench, and rigs stay in the addon's folder
  with an **Import rigs into project** button. The new **File > Addons...**
  browser lists installed addons with their contents and uninstall;
  re-installing an addon with the same name replaces it. The format is
  documented in `Data/Addons/README.md` and an example addon
  (`frosty-night.miaddon`, a cold moonlit camera grade) ships with the app

### Fixes

* **Asset packages: missing textures in generated Minecraft packages.** The
  asset pipeline only overlaid the authored rigs from its template, so
  release packages lacked 117 textures the manifest references: every cape
  and the camera tripod, the authored shelf/bed block textures, and two
  map-item textures renamed upstream. Template assets are now carried over
  whenever the target version's jar doesn't contain them, and the new
  `Tools/texture-tester` verifies every texture of a package in the browser
  (with a mirror check and download for genuinely missing files)

## Reforged 1.1.0 (2026-09-30)

### New features

* **Shader packs.** Installable shader presets for the camera: **File >
  Install shaders...** imports a `.mishader` pack (a small JSON document)
  into the app's `Shaders` folder, and every selected camera gains a
  **Select shader...** menu in the frame editor. Applying a pack resets all
  effect values to their defaults and then applies the pack - tonemapper,
  exposure, bloom, lens dirt, depth of field, color correction, film grain,
  vignette, chromatic aberration and distortion - as a single undoable
  step, exactly like editing the values by hand. Five packs ship with the
  app (Cinematic, Vintage Film, VHS Tape, Dreamy Glow, Bright & Punchy),
  and the `Data/Shaders/README.md` documents the format so anyone can make
  their own
* **Minecraft shaderpack import (Iris/OptiFine).** File > Install
  shaders... now also accepts real Minecraft shaderpack zips - BSL,
  Complementary, SEUS, Sildur's Vibrant, Chocapic, Photon and any other
  pack in the Iris/OptiFine format (the zip needs its `shaders` folder at
  the root). Mine-imator cannot execute the packs' GLSL - it is written
  for Minecraft's rendering pipeline - so the import reads the pack and
  generates a Reforged preset that approximates its signature look with
  the camera's own effects: known pack families are hand-tuned, unknown
  packs get a generic Minecraft shader look. The generated preset is a
  normal `.mishader` you can keep tweaking

## Reforged 1.0.9 (2026-09-28)

### Fixes

* **Rig center layout: missing text and bottom-edge overflow.** The details
  pane, download buttons and the "And N more..." note rendered past the
  popup's bottom edge (the popup framework's height value overcounts on
  fixed-size popups), which made their text disappear - the layout is now
  anchored to the popup's real bottom edge
* Wrapped text (rig descriptions, error messages) drew its lines only 2-4
  pixels apart, garbling multi-line text; line spacing now matches the font
  height
* Long rig names no longer run under the author label in the list

## Reforged 1.0.8 (2026-09-28)

### New features

* **Direct rig downloads with progress.** The rig center no longer just
  opens a web page for community rigs: WinnyThailandFX's Character Model
  V3 and V2.3 and the Simple Easy Facial Rig V2 now download straight
  into the app from the author's Google Drive, with a live progress bar,
  percentage and downloaded size. Rigs hosted on MediaFire (bWater's IK
  Rig, Roy Anims' pack) can't be fetched directly and keep a clearly
  labeled "Open download page" button. Every downloaded pack is verified
  to be a real zip - if a server sends a page instead, the app says so
  and offers the author's page instead
* **Rig center redesign.** The download center is now a two-pane
  browser: a searchable list on the left (source tags, live per-row
  progress) and a details pane on the right with the description, the
  rig's source, a proper Download button and the save location. Click a
  row to select it, click again (or press Download) to save it where you
  want. The rig library itself now downloads from this project's GitHub
  releases instead of a source branch

### Fixes

* The rig center search field and its label overlapped the rig list,
  and the refresh button sat on top of the popup's close button
* A failed rig download blanked the whole catalog with an "offline"
  error - failures now show next to the rig and the list stays usable
* Download progress no longer overflows when the server doesn't report
  a file size; it shows the downloaded amount and a pulsing bar instead
* Reopening the rig center while a download runs keeps showing its
  progress instead of resetting it

## Reforged 1.0.7 (2026-09-24)

### Upgraded assets

* **Minecraft 26.3 final.** The bundled Minecraft assets are upgraded from
  the 26.3 snapshot 9 preview to the full 26.3 release, with the final
  textures and models (including the copper chests and copper golem
  statues). 26.3 is the default on a fresh install; 26.2 ships alongside
  it and both are selectable in Settings
* **Self-hosted asset updates.** The in-app asset updater now checks this
  project's own GitHub releases instead of mineimator.com, so new
  Minecraft versions can be downloaded straight from the app (Update
  notification -> download) without shipping a new build. Future releases
  publish the `versions.midata` feed next to the per-version asset files

### Fixes

* When the default Minecraft asset version is missing (e.g. a development
  build without the release assets), the app now falls back to the newest
  available version in `Data/Minecraft` instead of failing to start

## Reforged 1.0.6 (2026-09-24)

### New features

* **Curated community rig catalog.** The download center now carries the
  community's best rigs instead of generated props. Linked entries open
  the author's official download page in your browser (new `url_open()`
  engine function): WinnyThailandFX's Character Model V3 and V2.3,
  Winny's Simple Easy Facial Rig V2, bWater's Studio's IK Rig and Roy
  Anims' rig pack. Hosted entries download directly: the open-source
  LapisFR face rig (feminine and masculine) and the CC BY-NC-SA 4.0
  Alchemist and Traveller piglin models. Reforged's feature rigs stay:
  the posable mannequin (IK) and the TV, monitor and billboard video
  screens. Every author, source and license is documented in
  `Rigs/CREDITS.md`, including a takedown policy for rig authors

### Fixes

* The TV screen had its aspect scale squashed to 1.0 by a
  double-normalization in the rig generator, making the screen square and
  overflowing the TV body. The TV model is now defined entirely in the
  generator (`Tools/generate_rigs.py` generates the feature rigs)

## Reforged 1.0.5 (2026-09-11)

### New features

* **Rig catalog doubled to 32 rigs.** New: armor stand (posable arms),
  oak door (posable hinge — rotate it open), crafting table, furnace,
  torch, lantern, fence, oak tree, sofa, anvil, cauldron, hay bale,
  archery target, fire hydrant, stop sign and campfire — joining the
  mannequin/stick figure (IK), video screens (TV, monitor, billboard),
  furniture and street props
* **Rig downloads save where you want.** Clicking a rig in the download
  center opens a save dialog — pick any folder and the rig pack (.zip) is
  downloaded there (the last used folder is remembered). The pack contains
  a `.miobject` plus its `.mimodel` and textures, so you can import it
  into any project afterwards with File ▸ Import. Rigs are no longer
  imported automatically

### Fixes

* Rig packs ship as proper Mine-imator object files: each download
  contains a `.miobject` (the importable object) plus its `.mimodel`
  model and textures. (Previously the packs carried a bare `.json` model,
  which the importer does not treat as a rig — nothing imported.)
* Importing zipped objects/models now also finds `.mimodel` files inside
  archives, and `.miobject` files are preferred when a zip contains
  several importable files
* Fixed a crash ("Invalid id 0") when scrolling the rig center list to the
  bottom — the scroll offset was capped for a smaller list than the popup
  shows, so the last rows read past the end of the results
* Video screens (TV, monitor, billboard) now show the **full** video
  frame: the engine squares every part's texture grid, so the screen parts
  are built as square faces that span the whole texture with a scale for
  the aspect ratio, instead of cropping the frame to a strip. Screen
  detection also works for imported rigs (it previously only matched
  Minecraft block models), and the video frame updates every frame on the
  screen part's cached shape textures

## Reforged 1.0.4 (2026-09-10)

### New features

* **Video screens in animations (TVs)**: place a TV in your scene, attach a
  video file and it plays on the screen — scrub the timeline and the TV
  shows that moment; rendered image and video exports include the video on
  the screen. The "TV (video screen)" rig ships in the new rig center:
  download it, add it to the scene (drag from the library or the workbench
  Model type), select it and pick a video file in the Info panel
  (`.mp4`, `.mov`, `.avi`, `.mkv`, `.webm`), with a volume control per TV.
  Video is decoded with FFmpeg and streamed to the screen part's texture
  (`CppProject/Media/VideoPlayer.cpp`); any model rig with a part textured
  `"screen.png"` becomes a video screen. Up to 8 videos play at once, the
  file's audio follows editor playback, and any model's screen part can be
  attached/removed at any time (undoable)
* **Downloadable rigs center** (File ▸ Download rigs, and a "Download rigs"
  entry in the workbench create panel): browse an online library of
  rigs, search it by name/author/description, download with a progress bar
  and import the rig straight into the project's resources. The catalog
  lives in `Rigs/index.json` in this repository and grows over time — rigs
  land in the `Rigs` folder next to the exe. Highlights: a posable
  mannequin and stick figure with IK-ready limbs (any model part can be
  rotated to pose, and limbs support IK targets in the frame editor; the
  mannequin also accepts player skins), three video screens (TV, monitor,
  billboard), furniture (table, chair, bookshelf, barrel, chest with a
  posable lid, park bench) and props (street lamp, traffic barrier, crate,
  traffic cone, speaker). `Tools/generate_rigs.py` regenerates the catalog

### Known limitations

* The TV's audio plays in the editor; rendered video exports do not include
  it yet (only timeline audio tracks are mixed into exports)
* Video files are referenced by their file path — moving/deleting the file
  shows the TV's normal screen again
* Videos with an aspect ratio other than the screen part's are stretched to
  fit it

### Earlier Reforged releases

* 1.0.3 (2026-09-07): version identity shown as "Reforged 1.0.3",
  `log.txt` written next to the executable, dev mode disabled for
  releases, tracing + Linux/Windows CI smoke tests, startup crash fix
  (missing sprite embedding in CI builds), About screen Reforged
  credits with logo fix
* 1.0.1 / 1.0.2: restored CI pipelines, first Reforged branding

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
* Fixed two GML ternaries whose generated C++ mixes `VarType` with plain
  numeric branches (`tab_template_editor_particles_preview`,
  `tab_timeline` zoom). MSVC accepts the ambiguous conditional, but
  clang/gcc (Linux and macOS builds) reject it; both branches are now
  explicitly real-typed. Verified against a VarType-faithful test harness
* Linux link: the precompiled `libavcodec.a` was built against x264 API
  155, but Ubuntu 24.04's system libx264 only provides API 164
  (`x264_encoder_open_164`), failing the link. A static libx264 built
  from the official mirror at the last API-155 commit is now committed
  to `CppProject/External/Linux/` and linked instead of `-lx264`
  (built without assembly for now - H.264 export on Linux works but
  encodes slower than with hand-written SIMD; full Linux symbol-closure
  was verified with nm across all precompiled archives)
* Linux CI installs the system libraries this CppProject links
  (x264, gnutls, nettle, sndio, va, vdpau, bz2, lzma)

* **log.txt now lands next to the executable** (release builds, all
  platforms) instead of `Data/log.txt` (Windows) / `~/Mine-imator/`
  (Linux/macOS), so it is easy to find and attach to bug reports. The
  startup sequence now also resolves the working directory *before*
  creating/deleting any user, projects or log paths (previously they
  were derived from an unset path when the launcher's working directory
  differed from the executable's folder), and writes a first
  "Starting Mine-imator" line immediately after the log is reset.
* **Startup is now observable:** the first-run asset loading pipeline
  (unzip -> biomes -> textures -> misc -> models -> blocks) logged
  nothing on the happy path, leaving log.txt ending at "Render init"
  with no way to tell where a silent startup death happened. Every
  loading stage is now traced into log.txt, along with markers for
  camera init and render startup completion.
* **CI smoke tests:** Build check now actually runs the freshly built
  app for 90s on Windows and Linux (on a copy of the install folder),
  prints its log, and fails if the app crashes, dies before logging,
  hits a fatal/missing-file error, or never reaches the asset loading
  screen - catching "builds fine but doesn't open" regressions before
  release.
* **Startup crash in the Minecraft font (run 34363231187, all platforms):**
  `CppProject/Asset/Sprites` is git-ignored in this base (the C# CppGen
  copies frames there on Windows dev machines), but CI uses the C++
  CppGen, which writes a `Generated/Assets.cmake` manifest instead - and
  nothing consumed it. Builds therefore embedded **zero** sprite
  resources: every `:/Sprites/...` load returned a null QImage, frames
  never made it onto a texture page, and the first `SpriteFont`
  construction (`new_minecraft_font`, right after "Assets startup")
  dereferenced a null texture page location and crashed (SIGSEGV /
  0xC0000005 - reproduced by the new smoke tests and pinpointed by a gdb
  backtrace). CMake now refreshes the manifest at configure time and
  copies all 683 sprite frames from `GmProject/sprites` into
  `Asset/Sprites/` so the index.qrc glob embeds them.
* **About (credits) screen:** the Reforged logo lockup (taller than the
  original wordmark this screen was laid out for) overlapped the version
  text - it is now moved up and scaled to fit the header again. The
  credits also had no mention of Reforged: a "Reforged" section now
  credits OmniNodeCo, linking to the repository.
* **First run never reached the interface** (the "creates a Projects
  folder but no window appears" bug): the continuation base ships its
  GameMaker development defaults, with `dev_mode` enabled. In dev mode
  `app_startup_interface` skips the normal first-run flow and
  unconditionally `project_load()`s a `dev_project/dev_project.miproject`
  from the temp folder - which never exists on a user machine - and
  `dev_mode_skip_blocks` even skips loading blocks. `dev_mode` is now
  `false`, the shippable configuration the previous Reforged releases
  used (all `dev_mode_*` flags collapse to false with it; the app then
  takes the normal startup path: loading screen -> welcome popup).
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

### Versioning

* Version line continues as Reforged 1.0.3: the app identifies as
  `2.0.2 Reforged 1.0.3` instead of the base's `Continuation Build 1.0.15
  (Alpha 1)`. Release names, tags (`reforged-v1.0.3`) and download zips
  (`Mine-imator-Reforged-1.0.3-<platform>.zip`) all derive from it
