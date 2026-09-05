# Reforged tools

## `fetch_minecraft_assets.py` — Minecraft asset pipeline

Builds Mine-imator asset packages (`<version>.zip` + `<version>.midata`) for any
Minecraft Java release by downloading the vanilla client jar from Mojang's
piston-meta service. Standard library only, so it runs anywhere Python 3.8+ does.

```sh
# Latest release (auto "latest texture pack")
python3 Tools/fetch_minecraft_assets.py --latest

# Full supported range: 1.21 through 26.3 (+ latest, to stay current)
python3 Tools/fetch_minecraft_assets.py --range 1.21:26.3 --latest

# Explicit versions / custom output / offline check
python3 Tools/fetch_minecraft_assets.py --mc-version 1.21,26.3 --out /tmp/mc
python3 Tools/fetch_minecraft_assets.py --range 1.21:26.3 --dry-run
python3 Tools/fetch_minecraft_assets.py --self-test   # no network needed
```

### Version selection

Explicit ids (`--mc-version`) and range endpoints resolve against every
manifest entry — releases, pre-releases, and snapshots. If an id has no final
release yet, it automatically falls back to its newest `{id}-*` pre-release
(e.g. `--range 1.21:26.3` currently ends at `26.3-pre-2`). Range bodies cover
releases only, so output stays stable day to day; add `--include-snapshots`
to fetch every snapshot inside the range as well. `--range` is optional:
a lone id (`--range 26.2`) fetches exactly that version, an empty end
(`1.21:`) runs to the latest release, and an empty value is ignored.
`--latest` always means the
latest final release, `--latest-snapshot` the latest pre-release/snapshot, and
`--list` prints every known version (newest first). Unknown ids fail with
"did you mean" suggestions instead of a bare error.

Outputs (default: `GmProject/datafiles/Data/Minecraft`, which the app scans
automatically — every `*.midata` there becomes selectable in Settings):

| File | Purpose |
|---|---|
| `<version>.zip` | Vanilla `assets/minecraft/**` + `pack.png` from the client jar, overlaid with the Mine-imator-authored character/special-block rigs from the template package |
| `<version>.midata` | Asset spec: template clone with the new version + regenerated texture lists (see below) |
| `versions.midata` | Update-feed index in the app's `{"versions": [...]}` format |
| `assets-index.json` | SHA-256 checksums + provenance (client SHA-1, release times) |
| `minecraft_latest.txt` | Latest fetched id; release.yml stamps it as the default assets version |

**Do not copy the feed files** (`versions.midata`, `assets-index.json`,
`minecraft_latest.txt`) into `Data/Minecraft` — the Settings dropdown lists
every `*.midata` there, so `versions.midata` would show up as a bogus version.
Copy only `[0-9]*.zip` / `[0-9]*.midata`.

### What is regenerated vs inherited

Regenerated per version by scanning the new jar (template order kept, new
entries appended, so existing texture slots never shift):

* `block_textures`, `block_textures_animated` (PNGs with animation `.mcmeta`),
  `item_textures`, `model_textures` (entity textures), `particle_textures`

Inherited from the template (`26.2`, format 9 — itself cloned from `1.20.2`):

* `characters`, `special_blocks` (+ their `.mimodel`/`.miframes` rigs),
  `blocks`, `biomes`, `armor`, `sherds`, `map_colors`, `particles`, `swatches`,
  `patterns`, `block_textures_color`, `block_textures_preview`

This means new-version textures render correctly, while brand-new blocks/mobs
stay unavailable until authored data exists for them — the loaders skip unknown
entries gracefully (verified: missing textures fall back to placeholders,
unknown world blocks map to null). Coverage stats print per version.

Downloads are cached under `~/.cache/mine-imator-reforged/mc-assets` (override
with `--cache`), jars are SHA-1 verified against the Mojang manifest, and zips
are deterministic (sorted entries, timestamps from the MC release time).

## `stamp_minecraft_version.py`

Sets the default assets version (`#macro minecraft_version`) in
`GmProject/scripts/macros/macros.gml`. Used by release.yml after fetching, so
release builds default to the newest assets:

```sh
python3 Tools/stamp_minecraft_version.py 26.3
```