# Addons

Addons are content packs for Mine-imator Reforged: one zip file that can
bundle shader packs, particle presets and rigs, installed with
**File > Install addon...** and managed in the **File > Addons...** browser.

A ready-made example ships next to this file: `frosty-night.miaddon`.

## Format

An addon is a `.zip` (rename the extension to `.miaddon` if you like - both
work) containing an `addon.json` manifest plus content folders:

```
my-addon.zip
 |- addon.json
 |- shaders/
 |   |- my-grade.mishader        (camera shader packs)
 |- particles/
 |   |- my-fx.miparticles        (workbench particle presets)
 |- rigs/
     |- my-rig.miobject          (rigs, imported from the Addons browser)
     |- my-rig.zip
```

`addon.json`:

```json
{
  "format": 1,
  "name": "MyAddon",
  "author": "Your name",
  "description": "What the addon contains.",
  "version": "1.0"
}
```

The manifest must sit at the zip's root (a single wrapper folder named like
the zip also works). `name` is required; everything else is optional. At
least one content folder with at least one file is required.

## What goes where when installed

| Folder | Installed to | Where it shows up |
|---|---|---|
| `shaders/*.mishader` | `Data/Shaders/` | The camera's **Select shader...** menu |
| `particles/*.miparticles` | `Particles/` | The workbench particle preset list |
| `rigs/*` | `Data/Addons/<addon>/rigs/` | **Import rigs into project** button in the Addons browser |

Uninstalling an addon (Addons browser > Uninstall) removes the files it
installed. Re-installing an addon with the same name replaces it.
