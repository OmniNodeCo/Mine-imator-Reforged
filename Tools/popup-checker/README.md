# Popup checker (dev server)

Development server that audits **every popup** of the app and serves a live
report in the browser:

```
python3 Tools/popup-checker/server.py     # serves on :8391
```

Open `http://127.0.0.1:8391` — the report regenerates from the sources on
every refresh, so it always reflects the current code.

## What it checks (per popup)

All `popup_*` registrations in `app_startup_interface_popups.gml` are
discovered automatically — currently 19 popups:

| Check | Catches |
|---|---|
| Draw script exists | registrations pointing at missing scripts |
| Language keys used by the draw script exist in `english.milanguage` | `<No text found>` labels in the UI |
| Popup fields read by the draw script are initialized (startup with-block, direct assignment, or framework fields) | reads of fields nobody sets |
| Called scripts exist (script folder or `function` defined anywhere) | callbacks referencing removed/renamed scripts |
| `icons.X` references exist in the icons enum | dead icon references |
| Caption key `<name>caption` exists (non-custom popups) | missing popup titles |
| **Custom popups with badge/caption icons draw their own header** | the framework draws no caption for custom popups — badges that never show |
| Fixed-height popups positioning with `dh` | the "dh overcounts on fixed popups" layout bug class (popup 1.0.9) |

Plus a **global pass**: every literal language key used anywhere in the GML
sources (menus, context menus, settings, popups) vs `english.milanguage` —
dynamic keys (`"prefix" + value`) are recognized via the prefix rule.

## Track record

The 1.1.5 audit run found and fixed:

* Content center + Addons popups: custom popups that set a BETA badge but
  never drew one (the framework skips captions on custom popups) — both now
  render their own header with icon, title and badge
* Frame editor transition dropdown: looked up `"menu" + name` keys that
  don't exist — every transition showed the fallback text; now uses the
  `transition*` key family with the ease direction templates
* Template editor: `Block`/`Model` list captions had no keys
* Watermark align + text align buttons, color picker mode: toggle button
  names without keys
* Mac/Linux keyboard names in the keybind list (Command/Super/media keys)
  had no keys

Keep it green: run the server while touching popups or menus.
