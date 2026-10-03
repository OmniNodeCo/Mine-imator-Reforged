#!/usr/bin/env python3
"""Mine-imator Reforged - popup checker dev server.

Development server that audits EVERY popup of the app (all popup_*
registrations in app_startup_interface_popups.gml) and serves a live
report in the browser. For each popup it checks:

  * draw script exists and its language keys exist in english.milanguage
  * popup fields read by the draw script are actually initialized
    (with-block at startup, direct assignment anywhere, or framework)
  * called scripts (action_*/popup_*/... callbacks) exist as scripts
  * icons.X references exist in the icons enum
  * the caption language key (<name>caption) exists
  * custom popups that set badge_icon/caption_icon are flagged: the
    popup framework does not draw captions/badges for custom popups,
    so their draw script must render its own header
  * fixed-height popups that position content with dh are flagged
    (the known "dh overcounts on fixed popups" layout bug class)

Plus a global section: every literal text key used anywhere in the GML
sources (menus, context menus, settings) vs english.milanguage.

Run:  python3 Tools/popup-checker/server.py   # serves on :8391
Standard library only.
"""

import json
import os
import re
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
SCRIPTS = os.path.join(REPO, "GmProject", "scripts")
POPUPS_FILE = os.path.join(SCRIPTS, "app_startup_interface_popups",
                           "app_startup_interface_popups.gml")
LANGUAGE = os.path.join(REPO, "GmProject", "datafiles", "Data",
                        "Languages", "english.milanguage")
ENUMS = os.path.join(SCRIPTS, "enums", "enums.gml")

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8391

# Fields the popup framework itself sets on every popup (new_obj/new_popup
# in new_popup.gml + popup_draw/popup_show runtime)
FRAMEWORK_FIELDS = {
    "name", "script", "width", "height", "block", "caption", "offset_x",
    "offset_y", "custom", "revert", "close_button", "closescript",
    "badge_icon", "caption_icon",
}

# Called identifiers with these prefixes must exist as scripts
SCRIPT_PREFIXES = ("action_", "popup_", "bench_", "world_", "perf_",
                   "performance_", "contentcenter_", "addon_")

# Draw-widget helpers whose first argument is a language key
KEY_ARGS = re.compile(
    r'\b(?:text_get|draw_textfield|draw_radiobutton|draw_checkbox|'
    r'draw_switch|draw_button_label|'
    r'draw_togglebutton|togglebutton_add|draw_dragger|draw_meter|'
    r'draw_tooltip_label)\s*\(\s*"([a-z0-9_]+)"')

# draw_button_collapse: first arg is a section id, the 5th arg is the caption key
COLLAPSE_CAPTION = re.compile(
    r'draw_button_collapse\s*\(\s*"[a-z0-9_]+"\s*,\s*[^,]+,\s*[^,]+,\s*[^,]+,\s*'
    r'"([a-z0-9_]+)"')

TEXT_GET = re.compile(r'\btext_get\s*\(\s*"([a-z0-9_]+)"')


def strip_comments(s):
    """Remove // comments (quote-aware) so commented-out code is not checked."""
    out = []
    for line in s.split("\n"):
        res, in_str, i = [], False, 0
        while i < len(line):
            c = line[i]
            if c == '"':
                in_str = not in_str
            elif c == "/" and not in_str and i + 1 < len(line) and line[i + 1] == "/":
                break
            res.append(c)
            i += 1
        out.append("".join(res))
    return "\n".join(out)
FIELD_READ = re.compile(r'\bpopup\.([a-z_0-9]+)')
ICONS_USE = re.compile(r'\bicons\.([A-Z_0-9]+)')
CALL = re.compile(r'\b([a-z_][a-z_0-9]*)\s*\(')


def flatten_language():
    d = json.load(open(LANGUAGE, encoding="utf-8"))
    keys = set()

    def walk(node, prefix=""):
        for k, v in node.items():
            if isinstance(v, dict):
                walk(v, prefix + k.replace("/", ""))
            else:
                keys.add(prefix + k)
    walk(d)
    return keys


def parse_icons():
    s = open(ENUMS, encoding="utf-8").read()
    m = re.search(r"enum icons\s*\{(.*?)\n\t\}", s, re.S)
    return set(re.findall(r"^\s*([A-Z_0-9]+),?$", m.group(1), re.M))


def block_of(s, start):
    """Content of the brace block starting at the first { after start."""
    i = s.index("{", start)
    depth, j = 0, i
    for j in range(i, len(s)):
        if s[j] == "{":
            depth += 1
        elif s[j] == "}":
            depth -= 1
            if depth == 0:
                return s[i + 1:j]
    return s[i:]


def all_gml_sources():
    for root, _, files in os.walk(SCRIPTS):
        for f in files:
            if f.endswith(".gml"):
                yield os.path.join(root, f)


def parse_popups():
    s = open(POPUPS_FILE, encoding="utf-8").read()
    popups = []
    for m in re.finditer(
            r'popup_([a-z_0-9]+) = new_popup\("([^"]+)",\s*([a-z_0-9]+),\s*'
            r'([0-9]+|null),\s*([0-9]+|null),\s*(true|false)'
            r'(?:,\s*(true|false))?(?:,\s*(true|false))?(?:,\s*(true|false))?\)', s):
        var, name, script, w, h, block, custom, revert, close = m.groups()
        # Optional per-popup attributes set right after the registration
        after = s[m.end():m.end() + 400]
        badge = re.search(r'popup_%s\.badge_icon = icons\.([A-Z_0-9]+)' % var, after)
        capicon = re.search(r'popup_%s\.caption_icon = icons\.([A-Z_0-9]+)' % var, after)
        # with-block field initialization
        wm = re.search(r'with \(popup_%s\)' % var, s)
        fields = set()
        if wm:
            body = block_of(s, wm.end())
            fields |= set(re.findall(r'^\t+([a-z_0-9]+) =', body, re.M))
        popups.append({
            "var": var, "name": name, "script": script,
            "width": int(w) if w != "null" else None,
            "height": int(h) if h != "null" else None,
            "custom": custom == "true",
            "badge_icon": badge.group(1) if badge else None,
            "caption_icon": capicon.group(1) if capicon else None,
            "init_fields": fields,
        })
    return popups


def assignments_anywhere(var):
    """Fields assigned on popup_<var> anywhere in the codebase (the generic
    popup. alias counts too - draw scripts and helpers assign through it)."""
    direct = re.compile(r'\bpopup_%s\.([a-z_0-9]+)\s*=[^=]' % var)
    alias = re.compile(r'\bpopup\.([a-z_0-9]+)\s*=[^=]')
    fields = set()
    for path in all_gml_sources():
        s = open(path, encoding="utf-8").read()
        fields |= set(direct.findall(s))
        fields |= set(alias.findall(s))
        for wm in re.finditer(r'with \(popup_%s\)' % var, s):
            body = block_of(s, wm.end())
            fields |= set(re.findall(r'^\t+([a-z_0-9]+) =', body, re.M))
    return fields


def defined_functions():
    funcs = set()
    for path in all_gml_sources():
        s = open(path, encoding="utf-8").read()
        funcs |= set(re.findall(r'\bfunction\s+([a-z_0-9]+)\s*\(', s))
    return funcs


def check_popup(pop, lang_keys, icons, script_dirs, functions):
    issues, warns = [], []
    script_file = os.path.join(SCRIPTS, pop["script"], pop["script"] + ".gml")

    if not os.path.isfile(script_file):
        issues.append("draw script missing: scripts/%s/%s.gml"
                      % (pop["script"], pop["script"]))
        return issues, warns
    src = strip_comments(open(script_file, encoding="utf-8").read())

    # Caption key must exist (the framework draws it on non-custom popups;
    # custom popups render their own header with their own key of choice)
    capkey = pop["name"] + "caption"
    if not pop["custom"] and capkey not in lang_keys:
        issues.append("missing caption key: %s" % capkey)

    # Language keys used by the draw script (and helpers in the same file)
    used = (set(TEXT_GET.findall(src)) | set(KEY_ARGS.findall(src))
            | set(COLLAPSE_CAPTION.findall(src)))
    missing = [k for k in used if k not in lang_keys
               and not any(e.startswith(k) for e in lang_keys)]
    if missing:
        issues.append("missing language keys: " + ", ".join(sorted(missing)))

    # Popup fields read but never initialized
    known = (FRAMEWORK_FIELDS | pop["init_fields"]
             | assignments_anywhere(pop["var"]))
    reads = set(FIELD_READ.findall(src))
    uninit = sorted(f for f in reads if f not in known)
    if uninit:
        issues.append("fields read but never initialized: "
                      + ", ".join(uninit))

    # Called scripts must exist (as a script folder or a function defined
    # somewhere - many files define several helper functions)
    for call in set(CALL.findall(src)):
        if (call.startswith(SCRIPT_PREFIXES)
                and call not in script_dirs and call not in functions):
            issues.append("called script does not exist: %s" % call)

    # Icons must exist
    for icon in sorted(set(ICONS_USE.findall(src))):
        if icon not in icons:
            issues.append("unknown icon: icons.%s" % icon)

    # Custom popups: framework draws no caption/badge/icon - the draw
    # script must render its own header (title and the badge icon itself)
    if pop["custom"] and (pop["badge_icon"] or pop["caption_icon"]):
        has_badge = pop["badge_icon"] is None or (
            "icons.%s" % pop["badge_icon"]) in src
        has_title = (pop["caption_icon"] is None
                     or ("icons.%s" % pop["caption_icon"]) in src)
        if not (has_badge and has_title):
            issues.append(
                "custom popup sets badge_icon/caption_icon but the popup "
                "framework draws no caption for custom popups - the draw "
                "script must render its own title/badge header")

    # Fixed height + dh positioning (known layout bug class)
    if pop["height"] is not None and not pop["custom"] and "dh" in src:
        warns.append("fixed-height popup positions content with dh "
                     "(dh overcounts by the caption height - anchor to "
                     "content_y + content_height instead)")

    return issues, warns


def global_key_check(lang_keys):
    """Literal text keys used anywhere vs english.milanguage."""
    per_file = {}
    for path in all_gml_sources():
        s = strip_comments(open(path, encoding="utf-8").read())
        used = (set(TEXT_GET.findall(s)) | set(KEY_ARGS.findall(s))
                | set(COLLAPSE_CAPTION.findall(s)))
        missing = sorted(k for k in used if k not in lang_keys
                         and not any(e.startswith(k) for e in lang_keys))
        if missing:
            rel = os.path.relpath(path, SCRIPTS)
            per_file[rel] = missing
    return per_file


def build_report():
    lang_keys = flatten_language()
    icons = parse_icons()
    script_dirs = set(os.listdir(SCRIPTS))
    functions = defined_functions()
    popups = parse_popups()

    results = []
    for pop in popups:
        issues, warns = check_popup(pop, lang_keys, icons, script_dirs,
                                    functions)
        results.append({**pop, "issues": issues, "warnings": warns})

    global_missing = global_key_check(lang_keys)
    return results, global_missing


PAGE = """<!DOCTYPE html>
<html><head><meta charset="utf-8">
<title>Reforged popup checker</title>
<style>
 body { font: 14px system-ui; background: #17181c; color: #e8e9ec;
        max-width: 1100px; margin: 24px auto; padding: 0 16px; }
 h1 { font-size: 20px; } h1 b { color: #e9b345; }
 .ok { color: #7bd88f; } .bad { color: #ff7b72; } .warn { color: #e3b341; }
 table { border-collapse: collapse; width: 100%%; margin: 12px 0; }
 td, th { text-align: left; padding: 6px 10px; border-bottom: 1px solid #33363f;
          vertical-align: top; }
 tr:hover td { background: #1f2127; }
 code { background: #262932; padding: 1px 5px; border-radius: 4px; }
 .box { background: #1f2127; border: 1px solid #33363f; border-radius: 10px;
        padding: 14px 18px; margin: 14px 0; }
 details ul { margin: 4px 0; padding-left: 20px; }
 .num { text-align: right; }
</style></head><body>
<h1>Mine-imator <b>Reforged</b> popup checker</h1>
<div class="box">%SUMMARY%</div>
%BODY%
<div class="box"><b>Global language-key check</b> (every literal key used in
the GML sources - menus, context menus, settings, popups - vs
english.milanguage):%GLOBAL%</div>
</body></html>"""


def render():
    results, global_missing = build_report()
    bad = [r for r in results if r["issues"]]
    warn = [r for r in results if r["warnings"] and not r["issues"]]
    ok = [r for r in results if not r["issues"] and not r["warnings"]]

    summary = ("<b>%d</b> popups checked: <span class='ok'>%d clean</span>, "
               "<span class='warn'>%d warnings</span>, "
               "<span class='bad'>%d with issues</span> - refresh reloads "
               "the report live from the sources"
               % (len(results), len(ok), len(warn), len(bad)))

    rows = ["<table><tr><th>Popup</th><th>Size</th><th>Custom</th>"
            "<th>Checks</th></tr>"]
    for r in sorted(results, key=lambda r: (bool(r["issues"]),
                                            bool(r["warnings"]),
                                            r["var"])):
        size = "%d&times;%s" % (r["width"], r["height"] if r["height"] else "auto")
        if r["issues"]:
            status = "<span class='bad'>FAIL</span>"
        elif r["warnings"]:
            status = "<span class='warn'>WARN</span>"
        else:
            status = "<span class='ok'>PASS</span>"
        detail = ""
        if r["issues"] or r["warnings"]:
            items = "".join("<li><span class='bad'>%s</span></li>" % i
                            for i in r["issues"])
            items += "".join("<li><span class='warn'>%s</span></li>" % w
                             for w in r["warnings"])
            detail = "<details><summary>details</summary><ul>%s</ul></details>" % items
        else:
            detail = "<span class='ok'>all checks passed</span>"
        badge = " %sBETA badge%s" % ("<b>", "</b>") if r["badge_icon"] else ""
        capicon = " %scaption icon%s" % ("<b>", "</b>") if r["caption_icon"] else ""
        rows.append("<tr><td><code>popup_%s</code><br><small>%s%s</small></td>"
                    "<td>%s</td><td>%s</td><td>%s %s</td></tr>"
                    % (r["var"], r["name"], badge + capicon if (badge or capicon) else "",
                       size, "yes" if r["custom"] else "no", status, detail))
    rows.append("</table>")
    body = "".join(rows)

    if global_missing:
        gitems = "".join(
            "<li><code>%s</code>: %s</li>" % (f, ", ".join(k for k in ks))
            for f, ks in sorted(global_missing.items()))
        gout = "<ul>%s</ul>" % gitems
    else:
        gout = " <span class='ok'>no missing keys anywhere</span>"

    return (PAGE.replace("%SUMMARY%", summary)
                .replace("%BODY%", body)
                .replace("%GLOBAL%", gout))


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        print("[popup-checker] " + (fmt % args))

    def do_GET(self):
        if self.path.startswith("/report"):
            body = render().encode("utf-8")
            code, ctype = 200, "text/html; charset=utf-8"
        elif self.path in ("", "/", "/index.html"):
            body = render().encode("utf-8")
            code, ctype = 200, "text/html; charset=utf-8"
        else:
            body, code, ctype = b"{}", 404, "application/json"
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body)


def main():
    results, global_missing = build_report()
    bad = sum(1 for r in results if r["issues"])
    print("popup checker: %d popups, %d with issues, %d files with missing keys"
          % (len(results), bad, len(global_missing)))
    server = ThreadingHTTPServer(("0.0.0.0", PORT), Handler)
    print("popup checker listening on http://0.0.0.0:%d" % PORT)
    server.serve_forever()


if __name__ == "__main__":
    main()
