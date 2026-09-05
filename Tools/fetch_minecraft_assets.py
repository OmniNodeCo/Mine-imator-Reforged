#!/usr/bin/env python3
"""Fetch Minecraft client assets and package them for Mine-imator Reforged.

For each requested Minecraft Java version this tool:
  1. Resolves the version through Mojang's piston-meta manifest
     (https://piston-meta.mojang.com/mc/game/version_manifest_v2.json).
  2. Downloads the client jar (SHA1-verified) into a local cache.
  3. Extracts ``assets/minecraft/**`` (+ ``pack.png``) and overlays the
     Mine-imator-authored character/special-block rigs from the template
     package, producing ``<version>.zip``.
  4. Clones the template ``<template>.midata`` spec, stamps the new version,
     and regenerates the mechanical texture lists (block/item/model/particle
     textures, animated textures) by scanning the new jar. Authored sections
     (characters, blocks, special blocks, biomes, armor, ...) are inherited
     from the template - see Tools/README.md for details and limitations.
  5. Writes ``versions.midata`` (in-app update feed format), ``assets-index.json``
     (checksums + provenance) and ``minecraft_latest.txt`` (latest id, used by
     release.yml to stamp the default assets version).

The app lists every ``Data/Minecraft/*.midata`` in Settings automatically, so
dropping the outputs into ``GmProject/datafiles/Data/Minecraft`` (the default
``--out``) is all it takes to ship them.

Examples:
  # Latest release only (auto "latest texture pack")
  python3 Tools/fetch_minecraft_assets.py --latest

  # Full supported range, Minecraft 1.21 through 26.3
  python3 Tools/fetch_minecraft_assets.py --range 1.21:26.3

  # Explicit versions (pre-release ids work too: --mc-version 26.3-pre-2)
  python3 Tools/fetch_minecraft_assets.py --mc-version 1.21,26.3 --latest

  # List every known version, newest first
  python3 Tools/fetch_minecraft_assets.py --list

  # Offline self-test (no network needed)
  python3 Tools/fetch_minecraft_assets.py --self-test

Only the Python standard library is used so this runs on any CI runner.
"""

import argparse
import datetime
import difflib
import hashlib
import io
import json
import os
import shutil
import ssl
import sys
import tempfile
import time
import urllib.request
import zipfile
from concurrent.futures import ThreadPoolExecutor

PISTON_META = "https://piston-meta.mojang.com/mc/game/version_manifest_v2.json"
MANIFEST_CACHE_TTL = 3600  # seconds
DOWNLOAD_RETRIES = 4
RETRY_BACKOFF = 5  # seconds, multiplied by attempt

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(SCRIPT_DIR)
DEFAULT_MINECRAFT_DIR = os.path.join(
    REPO_ROOT, "GmProject", "datafiles", "Data", "Minecraft")
DEFAULT_TEMPLATE = "26.2"
DEFAULT_CACHE = os.path.join(
    os.path.expanduser("~"), ".cache", "mine-imator-reforged", "mc-assets")

# Authored (non-vanilla) roots overlaid from the template package.
AUTHORED_ROOTS = (
    "assets/minecraft/models/character/",
    "assets/minecraft/models/special_block/",
)

# The four animated textures the loader looks up by name for water/lava.
REQUIRED_ANIMATED = (
    "block/water_still",
    "block/lava_still",
    "block/water_flow",
    "block/lava_flow",
)


def log(msg):
    print("[mc-assets] " + msg, flush=True)


def sha1_of_file(path):
    h = hashlib.sha1()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def sha256_of_file(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def http_get(url, timeout=120):
    """GET a URL with retries, returns response bytes."""
    last_err = None
    for attempt in range(1, DOWNLOAD_RETRIES + 1):
        try:
            req = urllib.request.Request(
                url, headers={"User-Agent": "Mine-imator-Reforged-asset-fetcher/1.0"})
            with urllib.request.urlopen(req, timeout=timeout) as resp:
                return resp.read()
        except Exception as exc:  # noqa: BLE001 - retry whatever fails
            last_err = exc
            log("GET %s failed (attempt %d/%d): %s"
                % (url, attempt, DOWNLOAD_RETRIES, exc))
            if attempt < DOWNLOAD_RETRIES:
                time.sleep(RETRY_BACKOFF * attempt)
    raise RuntimeError("GET %s failed after %d attempts: %s"
                       % (url, DOWNLOAD_RETRIES, last_err))


def http_download(url, dest, expected_sha1=None, timeout=600):
    """Download a URL to dest (atomic), optionally SHA1-verified."""
    if os.path.exists(dest) and expected_sha1:
        try:
            if sha1_of_file(dest) == expected_sha1:
                log("Reusing cached %s" % os.path.basename(dest))
                return dest
        except OSError:
            pass
    last_err = None
    for attempt in range(1, DOWNLOAD_RETRIES + 1):
        try:
            req = urllib.request.Request(
                url, headers={"User-Agent": "Mine-imator-Reforged-asset-fetcher/1.0"})
            tmp = dest + ".part"
            with urllib.request.urlopen(req, timeout=timeout) as resp, \
                    open(tmp, "wb") as f:
                total = resp.getheader("Content-Length")
                total = int(total) if total else 0
                done = 0
                while True:
                    chunk = resp.read(1 << 20)
                    if not chunk:
                        break
                    f.write(chunk)
                    done += len(chunk)
                    if total:
                        pct = done * 100 // total
                        print("\r[mc-assets]   %s %d%% (%d/%d MB)"
                              % (os.path.basename(dest), pct,
                                 done // (1 << 20), total // (1 << 20)),
                              end="", flush=True)
            print()
            if expected_sha1:
                got = sha1_of_file(tmp)
                if got != expected_sha1:
                    raise RuntimeError(
                        "SHA1 mismatch for %s: expected %s, got %s"
                        % (url, expected_sha1, got))
            os.replace(tmp, dest)
            return dest
        except Exception as exc:  # noqa: BLE001 - retry whatever fails
            last_err = exc
            log("Download %s failed (attempt %d/%d): %s"
                % (url, attempt, DOWNLOAD_RETRIES, exc))
            try:
                os.remove(dest + ".part")
            except OSError:
                pass
            if attempt < DOWNLOAD_RETRIES:
                time.sleep(RETRY_BACKOFF * attempt)
    raise RuntimeError("Download %s failed after %d attempts: %s"
                       % (url, DOWNLOAD_RETRIES, last_err))


def parse_time(value):
    return datetime.datetime.strptime(value, "%Y-%m-%dT%H:%M:%S%z")


def load_version_manifest(args):
    """Load piston-meta manifest (fixture, fresh cache, or download)."""
    if args.manifest:
        with open(args.manifest, "r", encoding="utf-8") as f:
            return json.load(f)
    os.makedirs(args.cache, exist_ok=True)
    cache_path = os.path.join(args.cache, "version_manifest_v2.json")
    if os.path.exists(cache_path):
        age = time.time() - os.path.getmtime(cache_path)
        if age < MANIFEST_CACHE_TTL:
            log("Using cached version manifest (age %ds)" % age)
            with open(cache_path, "r", encoding="utf-8") as f:
                return json.load(f)
    log("Fetching version manifest from piston-meta ...")
    data = http_get(PISTON_META, timeout=60)
    manifest = json.loads(data.decode("utf-8"))
    with open(cache_path, "w", encoding="utf-8") as f:
        f.write(data.decode("utf-8"))
    return manifest


def entries_by_time(manifest, types=("release", "snapshot")):
    entries = [v for v in manifest["versions"] if v.get("type") in types]
    entries.sort(key=lambda v: parse_time(v["releaseTime"]))
    return entries


def resolve_id(vid, by_id, chrono, what):
    """Resolve a version id to a manifest entry.

    Exact matches win. Otherwise the id falls back to its newest '{id}-*'
    pre-release (e.g. 26.3 -> 26.3-pre-2), which is then treated exactly like
    a release. The dash keeps partial versions safe: '1.2' never matches
    '1.20.2'.
    """
    if vid in by_id:
        return by_id[vid]
    prefix = vid + "-"
    cands = [e for e in chrono if e["id"].startswith(prefix)]
    if cands:
        best = max(cands, key=lambda e: parse_time(e["releaseTime"]))
        log("note: '%s' is not a known release; using pre-release '%s' "
            "instead" % (vid, best["id"]))
        return best
    suggestions = difflib.get_close_matches(vid, list(by_id), n=3)
    newest_rel = [e["id"] for e in chrono if e.get("type") == "release"][-5:]
    newest_pre = [e["id"] for e in chrono if e.get("type") != "release"][-3:]
    msg = "error: %s '%s' is not a known version." % (what, vid)
    if suggestions:
        msg += " Did you mean: %s?" % ", ".join(suggestions)
    msg += " Newest releases: %s." % ", ".join(newest_rel)
    if newest_pre:
        msg += " Newest pre-releases: %s." % ", ".join(newest_pre)
    msg += " Run with --list to see everything."
    raise SystemExit(msg)


def select_versions(manifest, args):
    """Return manifest entries in chronological order.

    Explicit ids and range endpoints resolve against every manifest entry
    (releases, pre-releases, snapshots, ...). Range bodies cover releases
    only unless --include-snapshots is given; pre-release endpoints are
    always included themselves.
    """
    chrono = entries_by_time(manifest)
    by_id = {v["id"]: v for v in chrono}
    selected = {}

    def add(entry):
        selected[entry["id"]] = entry

    if args.mc_version:
        for vid in args.mc_version.split(","):
            vid = vid.strip()
            if vid:
                add(resolve_id(vid, by_id, chrono, "version"))

    if args.range and args.range.strip():
        rng = args.range.strip()
        if ":" not in rng:
            # A single version id ("--range 26.2") means exactly that version.
            rng = rng + ":" + rng
        start_id, _, end_id = rng.partition(":")
        start_id = start_id.strip()
        end_id = end_id.strip() or manifest["latest"]["release"]
        if not start_id:
            raise SystemExit("error: --range needs a start version "
                             "(e.g. 1.21:26.3, 1.21: or a single id like 26.2)")
        start = resolve_id(start_id, by_id, chrono, "range start")
        end = resolve_id(end_id, by_id, chrono, "range end")
        start_t = parse_time(start["releaseTime"])
        end_t = parse_time(end["releaseTime"])
        if end_t < start_t:
            raise SystemExit("error: range end %s predates start %s"
                             % (end["id"], start["id"]))
        if getattr(args, "include_snapshots", False):
            pool = chrono
            kind = "version(s)"
        else:
            pool = [e for e in chrono if e.get("type") == "release"]
            kind = "release(s)"
        count = 0
        for entry in pool:
            t = parse_time(entry["releaseTime"])
            if start_t <= t <= end_t:
                add(entry)
                count += 1
        pre_endpoints = [e["id"] for e in (start, end)
                         if e.get("type") != "release"]
        add(start)
        add(end)
        log("Range %s:%s covers %d %s%s"
            % (start["id"], end["id"], count, kind,
               " + pre-release endpoint(s): %s" % ", ".join(pre_endpoints)
               if pre_endpoints else ""))

    if args.latest:
        latest_id = manifest["latest"]["release"]
        if latest_id not in by_id:
            raise SystemExit("error: latest release '%s' missing from manifest"
                             % latest_id)
        add(by_id[latest_id])
        log("Latest release: %s" % latest_id)

    if getattr(args, "latest_snapshot", False):
        snap_id = manifest["latest"]["snapshot"]
        if snap_id not in by_id:
            raise SystemExit("error: latest snapshot '%s' missing from manifest"
                             % snap_id)
        add(by_id[snap_id])
        log("Latest snapshot: %s" % snap_id)

    if not selected:
        raise SystemExit("error: specify --latest, --latest-snapshot, "
                         "--range A:B and/or --mc-version X[,Y...] "
                         "(or --self-test)")
    ordered = sorted(selected.values(),
                     key=lambda v: parse_time(v["releaseTime"]))
    return ordered


def list_versions(manifest):
    chrono = entries_by_time(manifest)
    for e in reversed(chrono):
        print("%-24s %-8s %s"
              % (e["id"], e.get("type"), e["releaseTime"][:10]))


def resolve_client_jar(entry, args):
    """Return (jar_path, client_sha1_or_None) for a manifest entry."""
    vid = entry["id"]
    jars_dir = os.path.join(args.cache, "jars")
    os.makedirs(jars_dir, exist_ok=True)
    jar_path = os.path.join(jars_dir, vid + ".jar")

    # Offline override: pre-seeded client jars.
    if args.client_jar:
        seeded = os.path.join(args.client_jar, vid + ".jar")
        if os.path.exists(seeded):
            log("%s: using seeded client jar" % vid)
            return seeded, None
        raise SystemExit("error: --client-jar %s lacks %s.jar"
                         % (args.client_jar, vid))

    log("%s: fetching version manifest ..." % vid)
    version_manifest = json.loads(
        http_get(entry["url"], timeout=60).decode("utf-8"))
    client = version_manifest.get("downloads", {}).get("client", {})
    if not client.get("url") or not client.get("sha1"):
        raise SystemExit("error: version %s has no client download" % vid)
    log("%s: downloading client jar (%0.1f MB) ..."
        % (vid, client.get("size", 0) / 1e6))
    http_download(client["url"], jar_path, expected_sha1=client["sha1"])
    return jar_path, client["sha1"]


def texture_name(path):
    """assets/minecraft/textures/block/stone.png -> block/stone."""
    assert path.startswith("assets/minecraft/textures/")
    assert path.endswith(".png")
    return path[len("assets/minecraft/textures/"):-len(".png")]


def scan_jar(jar_path):
    """Extract vanilla asset payload + texture inventory from a client jar."""
    with zipfile.ZipFile(jar_path) as jar:
        names = jar.namelist()
        payload = {}
        for name in names:
            if name.startswith("assets/minecraft/") and not name.endswith("/"):
                payload[name] = jar.read(name)
        pack_png = jar.read("pack.png") if "pack.png" in names else None

        block, item, entity, particle = set(), set(), set(), set()
        animated = set()
        mcmetas = {}
        for name in payload:
            if not name.startswith("assets/minecraft/textures/"):
                continue
            if name.endswith(".png.mcmeta"):
                mcmetas[name] = payload[name]
                continue
            if not name.endswith(".png"):
                continue
            tex = texture_name(name)
            head = tex.split("/", 1)[0]
            if head == "block":
                block.add(tex)
            elif head == "item":
                item.add(tex)
            elif head == "entity":
                base = tex.rsplit("/", 1)[-1]
                # _n/_s/_e are normal/material/emissive maps loaded separately.
                if "_" in base and base.rsplit("_", 1)[-1] in ("n", "s", "e"):
                    continue
                entity.add(tex)
            elif head == "particle":
                particle.add(tex)
        for name, raw in mcmetas.items():
            try:
                meta = json.loads(raw.decode("utf-8"))
            except (ValueError, UnicodeDecodeError):
                continue
            if isinstance(meta, dict) and "animation" in meta:
                tex = texture_name(name[:-len(".mcmeta")])
                if tex.startswith("block/"):
                    animated.add(tex)
    return {
        "payload": payload,
        "pack_png": pack_png,
        "block": block,
        "item": item,
        "entity": entity,
        "particle": particle,
        "animated": animated,
    }


def merge_list(template_list, scanned):
    """Template order first, then newly discovered entries (sorted)."""
    merged = list(template_list)
    seen = set(template_list)
    for tex in sorted(scanned):
        if tex not in seen:
            merged.append(tex)
            seen.add(tex)
    return merged


def build_package(vid, release_time, jar_path, template, out_dir, force):
    """Build <vid>.zip + <vid>.midata. Returns stats dict."""
    zip_path = os.path.join(out_dir, vid + ".zip")
    midata_path = os.path.join(out_dir, vid + ".midata")
    if not force and os.path.exists(zip_path) and os.path.exists(midata_path):
        log("%s: outputs exist, skipping (use --force to rebuild)" % vid)
        return {"version": vid, "skipped": True}

    scan = scan_jar(jar_path)

    # Deterministic timestamps from the MC release time.
    dt = parse_time(release_time).astimezone(datetime.timezone.utc)
    stamp = (dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second)

    # .zip: vanilla payload + authored rigs overlay + pack.png.
    files = {n: scan["payload"][n] for n in scan["payload"]
             if not n.startswith(AUTHORED_ROOTS)}  # Overlay always wins.
    files.update(template["authored"])
    pack = scan["pack_png"] if scan["pack_png"] is not None \
        else template["pack_png"]
    if pack is not None:
        files["pack.png"] = pack
    # Explicit directory entries, like the upstream packages.
    dirs = set()
    for name in files:
        parts = name.split("/")[:-1]
        for i in range(1, len(parts) + 1):
            dirs.add("/".join(parts[:i]) + "/")

    tmp_zip = zip_path + ".part"
    with zipfile.ZipFile(tmp_zip, "w", zipfile.ZIP_DEFLATED,
                         compresslevel=6) as out:
        for name in sorted(dirs):
            info = zipfile.ZipInfo(name, stamp)
            info.external_attr = 0o40775 << 16
            out.writestr(info, b"")
        for name in sorted(files):
            info = zipfile.ZipInfo(name, stamp)
            info.compress_type = zipfile.ZIP_DEFLATED
            out.writestr(info, files[name])
    os.replace(tmp_zip, zip_path)
    overlaid = len(template["authored"])

    # .midata: template clone + regenerated mechanical texture lists.
    spec = json.loads(json.dumps(template["spec"]))
    spec["version"] = vid
    stats = {"version": vid, "zip_files": 0, "appended": {}, "missing": {}}

    def regen(key, scanned):
        before = list(spec.get(key, []))
        spec[key] = merge_list(before, scanned)
        added = len(spec[key]) - len(before)
        # Report template entries whose PNG vanished (loader falls back).
        missing = [t for t in before
                   if " " not in t and t not in scanned
                   and "textures/%s.png" % t not in template_texture_files(scan)]
        stats["appended"][key] = added
        stats["missing"][key] = len(missing)
        if missing:
            log("%s: %d %s entries lack PNGs in this jar (e.g. %s) - "
                "in-app fallback textures will be used"
                % (vid, len(missing), key, ", ".join(missing[:3])))
        return added

    regen("block_textures", scan["block"])
    regen("block_textures_animated", scan["animated"])
    regen("item_textures", scan["item"])
    regen("model_textures", scan["entity"])
    regen("particle_textures", scan["particle"])

    for req in REQUIRED_ANIMATED:
        if req not in spec["block_textures_animated"]:
            raise SystemExit(
                "error: %s lacks required animated texture %s" % (vid, req))

    tmp_midata = midata_path + ".part"
    with open(tmp_midata, "w", encoding="utf-8") as f:
        json.dump(spec, f, indent="\t", ensure_ascii=True)
    os.replace(tmp_midata, midata_path)

    with zipfile.ZipFile(zip_path) as z:
        stats["zip_files"] = len(z.namelist())
    stats["zip_bytes"] = os.path.getsize(zip_path)
    stats["midata_bytes"] = os.path.getsize(midata_path)
    stats["overlaid"] = overlaid
    stats["skipped"] = False
    log("%s: wrote %s (%d files, +%d block +%d animated +%d item "
        "+%d model +%d particle textures)"
        % (vid, os.path.basename(zip_path), stats["zip_files"],
           stats["appended"]["block_textures"],
           stats["appended"]["block_textures_animated"],
           stats["appended"]["item_textures"],
           stats["appended"]["model_textures"],
           stats["appended"]["particle_textures"]))
    return stats


def template_texture_files(scan):
    # All texture PNG paths present in this jar payload.
    return {"textures/%s.png" % t for t in
            scan["block"] | scan["item"] | scan["entity"] | scan["particle"]}


def load_template(template_id, template_dir):
    midata_path = os.path.join(template_dir, template_id + ".midata")
    zip_path = os.path.join(template_dir, template_id + ".zip")
    for path in (midata_path, zip_path):
        if not os.path.exists(path):
            raise SystemExit("error: template file missing: %s" % path)
    with open(midata_path, "r", encoding="utf-8") as f:
        spec = json.load(f)
    authored = {}
    pack_png = None
    with zipfile.ZipFile(zip_path) as z:
        for name in z.namelist():
            if name.endswith("/"):
                continue
            if name.startswith(AUTHORED_ROOTS):
                authored[name] = z.read(name)
        if "pack.png" in z.namelist():
            pack_png = z.read("pack.png")
    log("Template %s: midata format %s, %d authored rig files"
        % (template_id, spec.get("format"), len(authored)))
    if not authored:
        raise SystemExit("error: no authored rigs found in %s" % zip_path)
    return {"spec": spec, "authored": authored, "pack_png": pack_png,
            "format": spec.get("format"), "id": template_id}


def write_feed(entries, template_format, out_dir, index):
    versions = [{"version": e["id"], "format": template_format,
                 "changes": "Minecraft %s assets (auto-fetched Reforged "
                            "package)" % e["id"]}
                for e in entries]
    feed = {"versions": versions}
    with open(os.path.join(out_dir, "versions.midata"), "w",
              encoding="utf-8") as f:
        json.dump(feed, f, indent="\t", ensure_ascii=True)
    with open(os.path.join(out_dir, "assets-index.json"), "w",
              encoding="utf-8") as f:
        json.dump(index, f, indent=2, sort_keys=True)
        f.write("\n")
    latest_id = entries[-1]["id"]
    with open(os.path.join(out_dir, "minecraft_latest.txt"), "w",
              encoding="utf-8") as f:
        f.write(latest_id + "\n")
    log("Feed: %d version(s), latest %s" % (len(entries), latest_id))
    return latest_id


def fetch_all(entries, args, template, out_dir):
    index = {"generated_utc": datetime.datetime.now(
        datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "tool": "Tools/fetch_minecraft_assets.py",
        "template": template["id"],
        "template_format": template["format"],
        "versions": {}}

    def one(entry):
        vid = entry["id"]
        jar_path, client_sha1 = resolve_client_jar(entry, args)
        stats = build_package(vid, entry["releaseTime"], jar_path,
                              template, out_dir, args.force)
        if not stats.get("skipped"):
            index["versions"][vid] = {
                "release_time": entry["releaseTime"],
                "client_sha1": client_sha1 or sha1_of_file(jar_path),
                "zip_sha256": sha256_of_file(
                    os.path.join(out_dir, vid + ".zip")),
                "midata_sha256": sha256_of_file(
                    os.path.join(out_dir, vid + ".midata")),
                "zip_files": stats["zip_files"],
                "appended_textures": stats["appended"],
            }
        return stats

    if args.workers > 1 and not args.client_jar:
        with ThreadPoolExecutor(max_workers=args.workers) as pool:
            results = list(pool.map(one, entries))
    else:
        results = [one(e) for e in entries]
    # Backfill index for skipped (already-built) versions.
    for entry, stats in zip(entries, results):
        vid = entry["id"]
        if stats.get("skipped") and vid not in index["versions"]:
            index["versions"][vid] = {
                "release_time": entry["releaseTime"],
                "client_sha1": "cached",
                "zip_sha256": sha256_of_file(
                    os.path.join(out_dir, vid + ".zip")),
                "midata_sha256": sha256_of_file(
                    os.path.join(out_dir, vid + ".midata")),
            }
    return index


# ---------------------------------------------------------------- self-test

def run_self_test(args):
    """Offline validation: range logic + template round-trip packaging."""
    failures = []

    def check(name, cond, detail=""):
        print(("PASS " if cond else "FAIL ") + name
              + (" - " + detail if detail and not cond else ""))
        if not cond:
            failures.append(name)

    # 1. Version selection over a fixture manifest mirroring live reality:
    # no final 26.3 yet; 26.3-pre-2 is the latest snapshot (type snapshot).
    fixture = {
        "latest": {"release": "26.2", "snapshot": "26.3-pre-2"},
        "versions": [
            {"id": "26.3-pre-2", "type": "snapshot",
             "url": "https://example.invalid/26.3-pre-2.json",
             "releaseTime": "2026-08-28T10:00:00+00:00"},
            {"id": "26.3-pre-1", "type": "snapshot",
             "url": "https://example.invalid/26.3-pre-1.json",
             "releaseTime": "2026-08-21T10:00:00+00:00"},
            {"id": "26.2", "type": "release",
             "url": "https://example.invalid/26.2.json",
             "releaseTime": "2026-07-15T10:00:00+00:00"},
            {"id": "25.1", "type": "release",
             "url": "https://example.invalid/25.1.json",
             "releaseTime": "2025-06-01T10:00:00+00:00"},
            {"id": "1.21", "type": "release",
             "url": "https://example.invalid/1.21.json",
             "releaseTime": "2024-06-13T10:00:00+00:00"},
            {"id": "1.20.2", "type": "release",
             "url": "https://example.invalid/1.20.2.json",
             "releaseTime": "2023-09-21T10:00:00+00:00"},
        ],
    }

    class Opts:
        mc_version = None
        range = "1.21:26.3"
        latest = False
        latest_snapshot = False
        include_snapshots = False
    got = [e["id"] for e in select_versions(fixture, Opts)]
    check("range 1.21:26.3 falls back to 26.3-pre-2 endpoint",
          got == ["1.21", "25.1", "26.2", "26.3-pre-2"], str(got))

    class OptsSnap(Opts):
        include_snapshots = True
    got = [e["id"] for e in select_versions(fixture, OptsSnap)]
    check("range + --include-snapshots covers pre-releases",
          got == ["1.21", "25.1", "26.2", "26.3-pre-1", "26.3-pre-2"],
          str(got))

    class Opts2(Opts):
        range = None
        latest = True
        mc_version = "1.20.2"
    got = [e["id"] for e in select_versions(fixture, Opts2)]
    check("explicit+latest merge", got == ["1.20.2", "26.2"], str(got))

    class OptsExp(Opts):
        range = None
        mc_version = "26.3-pre-1,26.2"
    got = [e["id"] for e in select_versions(fixture, OptsExp)]
    check("explicit snapshot id resolves",
          got == ["26.2", "26.3-pre-1"], str(got))

    class OptsSnapLatest(Opts):
        range = None
        latest_snapshot = True
    got = [e["id"] for e in select_versions(fixture, OptsSnapLatest)]
    check("--latest-snapshot resolves", got == ["26.3-pre-2"], str(got))

    class OptsSingle(Opts):
        range = "26.2"
    got = [e["id"] for e in select_versions(fixture, OptsSingle)]
    check("single-version range covers just that version",
          got == ["26.2"], str(got))

    class OptsOpenEnd(Opts):
        range = "26.2:"
    got = [e["id"] for e in select_versions(fixture, OptsOpenEnd)]
    check("open-ended range runs to latest release",
          got == ["26.2"], str(got))

    class OptsBlank(Opts):
        range = "   "
        latest = True
    got = [e["id"] for e in select_versions(fixture, OptsBlank)]
    check("blank --range value is ignored",
          got == ["26.2"], str(got))

    try:
        class OptsNoStart(Opts):
            range = ":26.2"
        select_versions(fixture, OptsNoStart)
        check("range without start errors", False, "no SystemExit")
    except SystemExit:
        check("range without start errors", True)

    try:
        class Opts3(Opts):
            range = "9.9:26.3"
        select_versions(fixture, Opts3)
        check("bad range start errors", False, "no SystemExit")
    except SystemExit as exc:
        check("bad range start errors with suggestion lists",
              "Newest releases" in str(exc), str(exc)[:120])

    try:
        class Opts4(Opts):
            range = None
            mc_version = "1.2"  # must NOT prefix-match 1.20.2
        select_versions(fixture, Opts4)
        check("partial id 1.2 rejected", False, "no SystemExit")
    except SystemExit:
        check("partial id 1.2 rejected", True)

    # 2. Round-trip: template zip as a pseudo client jar.
    tmp = tempfile.mkdtemp(prefix="mc-assets-test-")
    try:
        template = load_template(args.template, args.template_dir)
        fake_jar_dir = os.path.join(tmp, "jars")
        os.makedirs(fake_jar_dir)
        shutil.copy(
            os.path.join(args.template_dir, args.template + ".zip"),
            os.path.join(fake_jar_dir, "9.9.9.jar"))
        out_dir = os.path.join(tmp, "out")
        os.makedirs(out_dir)
        entry = {"id": "9.9.9",
                 "releaseTime": "2026-09-04T12:00:00+00:00", "url": ""}
        args.client_jar = fake_jar_dir
        jar_path, _ = resolve_client_jar(entry, args)
        stats = build_package("9.9.9", entry["releaseTime"], jar_path,
                              template, out_dir, True)
        check("round-trip builds", not stats.get("skipped"))

        with open(os.path.join(out_dir, "9.9.9.midata"),
                  encoding="utf-8") as f:
            regen = json.load(f)
        orig = template["spec"]
        check("version stamped", regen["version"] == "9.9.9")
        check("format kept",
              regen["format"] == orig["format"] == 9, str(regen["format"]))
        for key in ("block_textures", "block_textures_animated",
                    "item_textures", "model_textures", "particle_textures"):
            same_prefix = regen[key][:len(orig[key])] == orig[key]
            superset = set(orig[key]) <= set(regen[key])
            check("regen %s keeps template order+entries" % key,
                  same_prefix and superset)
        check("required animated kept",
              all(r in regen["block_textures_animated"]
                  for r in REQUIRED_ANIMATED))
        for key in ("characters", "blocks", "special_blocks", "biomes",
                    "armor", "map_colors"):
            check("authored section kept: %s" % key,
                  regen[key] == orig[key])

        with zipfile.ZipFile(
                os.path.join(args.template_dir,
                             args.template + ".zip")) as zo, \
                zipfile.ZipFile(os.path.join(out_dir, "9.9.9.zip")) as zn:
            fo = {n for n in zo.namelist() if not n.endswith("/")}
            fn = {n for n in zn.namelist() if not n.endswith("/")}
            check("zip file set identical", fo == fn)
            check("zip file contents identical",
                  fo == fn and all(zo.read(n) == zn.read(n) for n in fo))
    finally:
        shutil.rmtree(tmp, ignore_errors=True)

    print("self-test: %s" % ("ALL PASS" if not failures
                             else "%d FAILURES" % len(failures)))
    return 1 if failures else 0


# ------------------------------------------------------------------- main

def build_parser():
    p = argparse.ArgumentParser(
        description="Fetch Minecraft Java assets and package them for "
                    "Mine-imator Reforged.")
    p.add_argument("--mc-version", default=None,
                   help="Explicit version(s), comma separated (e.g. 1.21,26.3)")
    p.add_argument("--range", default=None,
                   help="Optional version range (start:end; empty end = latest "
                        "release; a single id like 26.2 = exactly that version. "
                        "An empty value is ignored)")
    p.add_argument("--latest", action="store_true",
                   help="Include the latest release")
    p.add_argument("--latest-snapshot", action="store_true",
                   help="Include the latest snapshot/pre-release")
    p.add_argument("--include-snapshots", action="store_true",
                   help="Include every snapshot/pre-release inside --range "
                        "(pre-release endpoints are always included)")
    p.add_argument("--list", action="store_true",
                   help="List known versions (newest first) and exit")
    p.add_argument("--out", default=DEFAULT_MINECRAFT_DIR,
                   help="Output directory for .zip/.midata files")
    p.add_argument("--template", default=DEFAULT_TEMPLATE,
                   help="Template assets version to clone rigs/spec from")
    p.add_argument("--template-dir", default=DEFAULT_MINECRAFT_DIR,
                   help="Directory holding the template files")
    p.add_argument("--cache", default=DEFAULT_CACHE,
                   help="Download/manifest cache directory")
    p.add_argument("--workers", type=int, default=4,
                   help="Parallel downloads (default 4)")
    p.add_argument("--manifest", default=None,
                   help="Use a local version_manifest JSON (offline)")
    p.add_argument("--client-jar", default=None,
                   help="Use seeded <version>.jar files from DIR (offline)")
    p.add_argument("--force", action="store_true",
                   help="Rebuild outputs even if they exist")
    p.add_argument("--dry-run", action="store_true",
                   help="Resolve + list versions only, download nothing")
    p.add_argument("--self-test", action="store_true",
                   help="Run offline self-test and exit")
    return p


def main(argv=None):
    args = build_parser().parse_args(argv)
    if args.self_test:
        return run_self_test(args)
    manifest = load_version_manifest(args)
    if args.list:
        list_versions(manifest)
        return 0
    entries = select_versions(manifest, args)
    log("Selected %d version(s): %s"
        % (len(entries), ", ".join(e["id"] for e in entries)))
    if args.dry_run:
        return 0
    os.makedirs(args.out, exist_ok=True)
    template = load_template(args.template, args.template_dir)
    index = fetch_all(entries, args, template, args.out)
    write_feed(entries, template["format"], args.out, index)
    log("Done. Outputs in %s" % args.out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
