# Extras

Standalone helper tools that ship alongside Mine-imator Reforged. They are
plain HTML files — download them (or clone the repo), open them in any
browser and they work fully offline.

## Walk-cycle generator (`mine-imator_walk-cycle_gen.html`)

Bakes a realistic **walking** cycle for the default character rigs into a
`.miframes` file you import as keyframes: leg swing with knee bend,
counter-swinging arms with elbow bend, vertical bob with proper foot
contact (the stance foot never slides), torso lean, rotation and hip tilt.
Every parameter is a slider, with a live side-view preview and the ideal
forward speed to move your character at.

## Run-cycle generator (`mine-imator_run-cycle_gen.html`)

The running counterpart: shorter cycle, high knee drive, a flight phase
where both feet leave the ground, pumped arms with bent elbows, more
forward lean and a stronger bounce — same preview, sliders and
`.miframes` export.

## Importing

1. Open the generator, tweak the sliders and download the `.miframes` file.
2. In Mine-imator, select your **character** in the timeline (not a single
   body part) and import the file as keyframes.
3. Parts are matched by name — `head, body, left_arm, right_arm,
   left_leg, right_leg` (Steve, Alex and rigs built like them).
4. Move the character itself forward at the recommended speed; the
   animation runs in place.

The default Steve/Alex rigs attach the head and arms to the *body* part,
so the tools only bob the body and legs — head and arms ride along. If
your custom rig keeps all parts directly under the character root, tick
**Flat rig** in the tool before exporting.

## Credits

- The walk-cycle generator was originally created by **eysnaafo**
  (Discord). Thank you!
- Completed, corrected and maintained by the Mine-imator Reforged project:
  restored the truncated file, fixed the double head/arm bob on the
  default rigs, compensated arm/head angles for torso lean, updated the
  file format version, and added the run-cycle generator on top of the
  same core.
