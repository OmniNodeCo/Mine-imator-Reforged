# Content server (temp dev server)

Temporary local server for the in-app **Content center** (File >
Content center...). It serves the center's four menus — **Rigs, Shader
packs, Addons, Particles** — with the exact flat URL layout of the
production content host (a GitHub release download URL), so the app
cannot tell the difference:

```
python3 Tools/content-server/server.py     # listens on :8390
```

| URL | Serves |
|---|---|
| `/index.json` | Rig catalog (live from `Rigs/index.json`) |
| `/shaders.json` | Shader pack catalog (live from `Data/Shaders/*.mishader`) |
| `/addons.json` | Addon catalog (live from `Data/Addons/*.miaddon`) |
| `/particles.json` | Particle preset catalog (live from `Particles/*.miparticles`) |
| `/<file>` | Any rig / shader pack / addon / particle file by name |

Catalogs are regenerated on every request - edit a shader or add a rig,
hit refresh in the app, and it's there.

## Pointing the app at it

The app downloads from the `link_content` macro. For a development
build, temporarily point it at this server in
`GmProject/scripts/macros/macros.gml`:

```gml
#macro link_content            "http://127.0.0.1:8390/"
```

Production builds keep the default (the GitHub release download URL);
the Release workflow stages the same catalogs and files with every
release (see the "Stage content library" step in `release.yml`), so the
content center works out of the box there - this server exists only for
development.

This server replaced the old rig center's server integration: the rig
center popup and its `link_rigs`-based index fetch were removed in
1.1.3 and the Content center now handles every menu.
