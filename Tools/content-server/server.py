#!/usr/bin/env python3
"""Mine-imator Reforged - content center dev server.

Temporary development server for the in-app Content center (File >
Content center...). It mirrors the flat layout of a GitHub release
download URL exactly, so pointing the app at it while developing gives
the same responses as production:

  http://127.0.0.1:8390/index.json        rig catalog (Rigs/index.json)
  http://127.0.0.1:8390/shaders.json      shader pack catalog
  http://127.0.0.1:8390/addons.json       addon catalog
  http://127.0.0.1:8390/particles.json    particle preset catalog
  http://127.0.0.1:8390/<file>            any rig/pack/addon/particle file

Catalogs are generated live from the repository, so editing a shader or
adding a rig immediately shows up after a refresh in the app.

To develop against it, temporarily point the ``link_content`` macro at
the server (GmProject/scripts/macros/macros.gml):

  #macro link_content "http://127.0.0.1:8390/"

and run ``python3 Tools/content-server/server.py``. Production builds
keep the macro pointed at the GitHub release download URL - the Release
workflow stages the same catalogs and files (see release.yml, "Stage
content library").

Standard library only.
"""

import json
import os
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))

RIGS_DIR = os.path.join(REPO, "Rigs")
SHADERS_DIR = os.path.join(REPO, "GmProject", "datafiles", "Data", "Shaders")
ADDONS_DIR = os.path.join(REPO, "GmProject", "datafiles", "Data", "Addons")
PARTICLES_DIR = os.path.join(REPO, "GmProject", "datafiles", "Particles")

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8390


def catalog_rigs():
    index = json.load(open(os.path.join(RIGS_DIR, "index.json"),
                           encoding="utf-8"))
    items = index.get("rigs", [])
    # Hosted entries carry "file" already. Entries with only "filename"
    # (e.g. the Winny rigs) are direct downloads from the author's own
    # server - the filename is just their suggested save name, so do NOT
    # mark them hosted here or the app would 404 on this server.
    for item in items:
        if "file" in item:
            path = os.path.join(RIGS_DIR, item["file"])
            if not os.path.isfile(path):    # not actually hosted here
                del item["file"]
    return items


def catalog_shaders():
    items = []
    for fn in sorted(os.listdir(SHADERS_DIR)):
        if not fn.endswith((".mishader", ".json")) or fn == "README.md":
            continue
        try:
            spec = json.load(open(os.path.join(SHADERS_DIR, fn),
                                  encoding="utf-8"))
        except (OSError, ValueError):
            continue
        if not isinstance(spec, dict) or "values" not in spec:
            continue
        items.append({
            "name": spec.get("name", fn),
            "author": spec.get("author", "Mine-imator Reforged"),
            "description": spec.get("description", ""),
            "file": fn,
        })
    return items


def catalog_addons():
    import zipfile
    items = []
    for fn in sorted(os.listdir(ADDONS_DIR)):
        if not fn.endswith((".miaddon", ".zip")):
            continue
        path = os.path.join(ADDONS_DIR, fn)
        try:
            with zipfile.ZipFile(path) as z:
                names = z.namelist()
                root = ""
                if "addon.json" in names:
                    root = "addon.json"
                else:
                    base = fn.rsplit(".", 1)[0]
                    if base + "/addon.json" in names:
                        root = base + "/addon.json"
                if not root:
                    continue
                spec = json.loads(z.read(root).decode("utf-8"))
        except (OSError, ValueError, zipfile.BadZipFile):
            continue
        if not isinstance(spec, dict) or "name" not in spec:
            continue
        items.append({
            "name": spec["name"],
            "author": spec.get("author", ""),
            "description": spec.get("description", ""),
            "version": spec.get("version", "1.0"),
            "file": fn,
        })
    return items


def catalog_particles():
    items = []
    for fn in sorted(os.listdir(PARTICLES_DIR)):
        if not fn.endswith(".miparticles"):
            continue
        items.append({
            "name": fn[:-len(".miparticles")].replace("_", " "),
            "description": "",
            "file": fn,
        })
    return items


CATALOGS = {
    "index.json": catalog_rigs,
    "shaders.json": catalog_shaders,
    "addons.json": catalog_addons,
    "particles.json": catalog_particles,
}

FILE_DIRS = {
    "rigs": RIGS_DIR,
    "shaders": SHADERS_DIR,
    "addons": ADDONS_DIR,
    "particles": PARTICLES_DIR,
}


def find_file(name):
    """Locate a flat-served file across the content directories."""
    for d in FILE_DIRS.values():
        path = os.path.join(d, name)
        if os.path.isfile(path):
            return path
    return None


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        print("[content-server] " + (fmt % args))

    def _send(self, code, body, ctype):
        if isinstance(body, str):
            body = body.encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        name = self.path.lstrip("/").split("?")[0]
        if name in ("", "index.html"):
            self._send(200, PAGE, "text/html; charset=utf-8")
        elif name in CATALOGS:
            body = json.dumps({"items": CATALOGS[name]()},
                              indent=2, ensure_ascii=True)
            self._send(200, body, "application/json")
        else:
            path = find_file(name)
            if path is None or ".." in name or "/" in name:
                self._send(404, b"{}", "application/json")
                return
            with open(path, "rb") as f:
                self._send(200, f.read(),
                           "application/octet-stream")


PAGE = """<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>Reforged content server</title>
<style>
 body { font: 14px system-ui; background: #17181c; color: #e8e9ec;
        max-width: 720px; margin: 40px auto; padding: 0 16px; }
 a { color: #e9b345; } code { background: #262932; padding: 1px 5px;
        border-radius: 4px; }
 h1 { font-size: 20px; } h1 b { color: #e9b345; }
 .box { background: #1f2127; border: 1px solid #33363f; border-radius: 10px;
        padding: 14px 18px; margin: 14px 0; }
</style></head><body>
<h1>Mine-imator <b>Reforged</b> content server</h1>
<div class="box">Serving the in-app Content center catalogs and files for
local development. Point the app's <code>link_content</code> macro at
<code>http://127.0.0.1:%PORT%/</code> to use it.</div>
<div class="box">Catalogs (live, generated from this repository):<br>
 <a href="/index.json">/index.json</a> - rigs<br>
 <a href="/shaders.json">/shaders.json</a> - shader packs<br>
 <a href="/addons.json">/addons.json</a> - addons<br>
 <a href="/particles.json">/particles.json</a> - particles</div>
<div class="box">Every catalog entry's <code>file</code> is served flat,
exactly like a GitHub release download URL.</div>
</body></html>""".replace("%PORT%", "8390")


def main():
    server = ThreadingHTTPServer(("0.0.0.0", PORT), Handler)
    print("content server listening on http://0.0.0.0:%d" % PORT)
    print("catalogs: %d rigs, %d shaders, %d addons, %d particles"
          % (len(catalog_rigs()), len(catalog_shaders()),
             len(catalog_addons()), len(catalog_particles())))
    server.serve_forever()


if __name__ == "__main__":
    main()
