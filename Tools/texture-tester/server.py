#!/usr/bin/env python3
"""Mine-imator Reforged - online texture tester.

Serves a small web app that verifies every texture of a Minecraft asset
package actually loads:

  * Bundled template package (dev builds): every manifest reference is
    streamed from the template zip and rendered in the browser, so missing
    or corrupt PNGs surface as failures.
  * Simulated release package: what `fetch_minecraft_assets.py` would build
    for vanilla 26.3 - both with the tool as shipped (authored-rigs overlay
    only) and with the template carry-over overlay - computed against a
    vanilla file list fetched from the InventivetalentDev/minecraft-assets
    mirror.
  * For textures the package lacks, the page can check the mirror online
    (the browser fetches raw.githubusercontent.com) and download them from
    that different site into `repairs/` via this server.

Run:  python3 Tools/texture-tester/server.py   (then open the printed URL)
Standard library only.
"""

import json
import os
import re
import sys
import urllib.parse
import zipfile
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
MC_DIR = os.path.join(REPO, "GmProject", "datafiles", "Data", "Minecraft")
TEMPLATE_ID = "26.3-snapshot-9"
FIXTURE = os.path.join(HERE, "vanilla-26.3.json")
REPAIRS = os.path.join(HERE, "repairs")

# Authored rig roots - always overlaid by fetch_minecraft_assets.py.
AUTHORED_ROOTS = (
    "assets/minecraft/models/character/",
    "assets/minecraft/models/special_block/",
)

MIRROR_RAW = ("https://raw.githubusercontent.com/InventivetalentDev/"
              "minecraft-assets")
MIRROR_VERSIONS = ("26.3", "26.3-snapshot-9")


def load_refs():
    """Every texture reference in the manifest, resolved like the app does."""
    z = zipfile.ZipFile(os.path.join(MC_DIR, TEMPLATE_ID + ".zip"))
    names = {n for n in z.namelist() if not n.endswith("/")}
    spec = json.load(open(os.path.join(MC_DIR, TEMPLATE_ID + ".midata"),
                          encoding="utf-8"))

    refs = {}

    def add(v, origin):
        if not isinstance(v, str) or not v.strip():
            return
        base = v.split(" ")[0]                       # render flags
        if base.startswith("minecraft:"):
            base = base[len("minecraft:"):]
        if base and not base.endswith(".json"):
            refs.setdefault(base, set()).add(origin)

    for key in ("block_textures", "block_textures_animated",
                "block_textures_color", "block_textures_preview",
                "item_textures", "particle_textures", "model_textures"):
        for v in spec.get(key, []):
            add(v, key)

    frames = {}

    def walk(o):
        if isinstance(o, dict):
            if isinstance(o.get("texture"), str) and "frames" in o \
                    and isinstance(o.get("name"), str):
                frames[o["texture"]] = o["frames"]
            for k, v in o.items():
                if k in ("texture", "shape_texture") and isinstance(v, str):
                    add(v, k)
                elif k == "shape_texture" and isinstance(v, dict):
                    for vv in v.values():
                        if isinstance(vv, str):
                            add(vv, "shape_texture")
                elif k == "textures" and isinstance(v, list):
                    for vv in v:
                        if isinstance(vv, str):
                            add(vv, "textures")
                else:
                    walk(v)
        elif isinstance(o, list):
            for v in o:
                walk(v)

    walk(spec)
    for n in sorted(names):
        if n.endswith(".mimodel"):
            data = z.read(n).decode("utf-8", "replace")
            for m in re.finditer(r'(?:texture|source)="([^"]+)"', data):
                v = m.group(1)
                if "/" in v and not v.startswith(("http", "Data/")):
                    add(v, "rig:" + n.rsplit("/", 1)[-1])

    # Animated particle frames resolve as <name>_0 .. <name>_N-1; the bare
    # name itself is only loaded for single-frame particles.
    for name, fr in list(frames.items()):
        if isinstance(fr, int) and fr > 1:
            refs.pop(name, None)
            for i in range(fr):
                refs.setdefault("%s_%d" % (name, i), set()).add(
                    "particle frames")
    return z, names, refs, spec


def build_audit():
    z, names, refs, spec = load_refs()
    fixture = json.load(open(FIXTURE, encoding="utf-8"))
    fin = fixture["vanilla_26_3"]
    snap = fixture["vanilla_26_3_snapshot_9"]
    vanilla_tex = set("assets/minecraft/textures/" + p
                      for p in fin["textures"])
    vanilla_snap_tex = set("assets/minecraft/textures/" + p
                           for p in snap["textures"])
    vanilla_models = set("assets/minecraft/models/" + p
                         for p in fin["models"])
    vanilla_bs = set("assets/minecraft/blockstates/" + p
                     for p in fin["blockstates"])

    template_tex = {n for n in names
                    if n.startswith("assets/minecraft/textures/")
                    and n.endswith(".png")}
    overlay_models = {n for n in names if n.startswith(AUTHORED_ROOTS)}

    def kind(ref):
        want = "assets/minecraft/textures/%s.png" % ref
        if want in vanilla_tex:
            return "vanilla"
        if want in vanilla_snap_tex:
            return "dropped-upstream"   # renamed/removed after the template
        return "mineimator-authored"

    entries = []
    for ref in sorted(refs):
        want = "assets/minecraft/textures/%s.png" % ref
        in_tpl = want in template_tex
        in_van = want in vanilla_tex
        entries.append({
            "ref": ref,
            "kind": kind(ref),
            "origin": sorted(refs[ref]),
            "template": in_tpl,
            # Tool as it shipped at 1.1.0: jar payload + rig overlay only.
            "release_current": in_van,
            # Tool with the template carry-over overlay (fill-missing).
            "release_fixed": in_van or in_tpl,
        })

    # Rig + blockstate references (paths the loaders open).
    rig_missing = []
    sections = (spec.get("blocks", []) + spec.get("special_blocks", [])
                + spec.get("characters", []))
    for blk in sections:
        stacks = list(blk.get("states", {}).values()) if isinstance(
            blk.get("states"), dict) else []
        for st_list in stacks:
            if not isinstance(st_list, list):
                continue
            for var in st_list:
                f = var.get("file", "") if isinstance(var, dict) else ""
                if f.endswith(".json") and ("assets/minecraft/blockstates/"
                                            + f) not in vanilla_bs:
                    rig_missing.append("blockstates/" + f)
                elif f.endswith((".mimodel", ".miframes")) and not any(
                        p + f in overlay_models for p in (
                            "assets/minecraft/models/character/",
                            "assets/minecraft/models/character/loops/",
                            "assets/minecraft/models/special_block/")):
                    rig_missing.append("models/" + f)

    counts = {}
    for src in ("template", "release_current", "release_fixed"):
        counts[src] = sum(1 for e in entries if e[src])

    all_pngs = sorted(n[len("assets/minecraft/textures/"):-len(".png")]
                      for n in template_tex)
    return {
        "template_id": TEMPLATE_ID,
        "mirror": MIRROR_RAW,
        "mirror_versions": MIRROR_VERSIONS,
        "total_refs": len(entries),
        "counts": counts,
        "package_pngs": len(all_pngs),
        "vanilla_pngs": len(vanilla_tex),
        "missing_rigs": sorted(set(rig_missing)),
        "refs": entries,
        "all_pngs": all_pngs,
    }


class Handler(BaseHTTPRequestHandler):
    audit = None
    zfile = None

    def log_message(self, fmt, *args):  # quiet
        pass

    def _send(self, code, body, ctype="application/json", cache=True):
        if isinstance(body, str):
            body = body.encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        if cache:
            self.send_header("Cache-Control", "max-age=300")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        route = parsed.path
        if route in ("/", "/index.html"):
            self._send(200, open(os.path.join(HERE, "index.html"),
                                 "rb").read(), "text/html; charset=utf-8")
        elif route == "/api/audit":
            self._send(200, json.dumps(Handler.audit))
        elif route.startswith("/tex/"):
            ref = urllib.parse.unquote(route[len("/tex/"):])
            name = "assets/minecraft/textures/%s.png" % ref
            try:
                data = Handler.zfile.read(name)
            except KeyError:
                self._send(404, b"{}", "application/json")
                return
            self._send(200, data, "image/png")
        else:
            self._send(404, b"{}", "application/json")

    def do_POST(self):
        if self.path != "/api/repair":
            self._send(404, b"{}", "application/json")
            return
        length = int(self.headers.get("Content-Length", "0"))
        payload = json.loads(self.rfile.read(length) or b"{}")
        ref = payload.get("ref", "")
        b64 = payload.get("data", "")
        if not re.fullmatch(r"[A-Za-z0-9_/.-]+", ref) or not b64:
            self._send(400, json.dumps({"error": "bad request"}))
            return
        import base64
        try:
            data = base64.b64decode(b64)
        except Exception:
            self._send(400, json.dumps({"error": "bad base64"}))
            return
        os.makedirs(os.path.join(REPAIRS, "textures"), exist_ok=True)
        path = os.path.join(REPAIRS, "textures", ref + ".png")
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "wb") as f:
            f.write(data)
        self._send(200, json.dumps({
            "saved": os.path.relpath(path, REPO),
            "bytes": len(data),
            "note": "Saved to the texture-tester repairs folder. Drop it "
                    "into a package zip under assets/minecraft/textures/ "
                    "to repair that package."}))


def main():
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8377
    Handler.zfile = zipfile.ZipFile(os.path.join(MC_DIR, TEMPLATE_ID + ".zip"))
    print("indexing manifest references ...", flush=True)
    Handler.audit = build_audit()
    c = Handler.audit["counts"]
    print("refs: %d | template ok: %d | release(current tool): %d | "
          "release(fixed tool): %d"
          % (Handler.audit["total_refs"], c["template"],
             c["release_current"], c["release_fixed"]))
    server = ThreadingHTTPServer(("0.0.0.0", port), Handler)
    print("texture tester listening on http://0.0.0.0:%d" % port, flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
