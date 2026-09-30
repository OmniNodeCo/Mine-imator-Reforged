# Texture tester

Online checker that every texture of a Minecraft asset package is actually
available and decodes correctly — and a mirror downloader for the ones that
are missing.

```sh
python3 Tools/texture-tester/server.py        # listens on :8377
```

What it verifies (served at `/`, computed from the repo's bundled template
package + `vanilla-26.3.json`):

* **Bundled template package** — every texture referenced by the `.midata`
  manifest (block/item/model/particle lists, character + special-block rig
  `texture` attributes, shape-texture state overrides, animated particle
  frame expansions) resolves to a PNG inside the template zip. The browser
  decode-tests each one, which also catches corrupt images.
* **Release package simulation** — the same references checked against what
  `fetch_minecraft_assets.py` puts in a downloadable `<version>.zip`:
  vanilla 26.3 payload + authored-rig overlay (the tool as shipped at 1.1.0)
  versus the fixed tool with the template carry-over overlay.
* **Mirror availability + repair** — for textures a package lacks, the page
  can check the [minecraft-assets mirror]
  (https://github.com/InventivetalentDev/minecraft-assets) online (fetched
  straight from `raw.githubusercontent.com` by your browser — the server
  itself makes no outbound requests) and download them from that site into
  `repairs/`, ready to be dropped into a package zip.

`vanilla-26.3.json` holds the vanilla client-jar file lists (26.3 and
26.3-snapshot-9 textures, 26.3 models/blockstates) scraped from the mirror
via the GitHub API. Regenerate with
`gh api "repos/InventivetalentDev/minecraft-assets/git/trees/26.3:assets/minecraft/textures?recursive=1"`
when targeting a new version.
