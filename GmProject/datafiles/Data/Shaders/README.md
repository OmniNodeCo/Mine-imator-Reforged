# Shader packs

A shader pack is a small JSON file (`.mishader`) that presets the camera's
effect values - tonemapping, bloom, vignette, chromatic aberration, film
grain, color correction and depth of field. Applying a pack resets every
effect value to its default first, then applies the pack's values, as one
undoable step.

## Installing

In the app: **File > Install shaders...** and pick a `.mishader` (or
`.json`) file. The pack is copied into this `Shaders` folder and appears in
the camera's **Select shader...** menu (select a camera in the frame editor).
Five packs ship with the app; drop more files into this folder to add them.

## Format

```json
{
    "format": 1,
    "name": "My Shader Pack",
    "author": "Your name",
    "description": "One line about the look.",
    "values": {
        "tonemapper": 2,
        "exposure": 1.05,
        "bloom": true,
        "bloom_intensity": 0.55,
        "vignette_color": "#000000"
    }
}
```

Colors are `"#RRGGBB"` strings; everything else is a number or boolean.
Only the keys you set are applied (after the reset). Available keys:

`light_management`, `tonemapper` (0 none, 1 Reinhard, 2 ACES), `exposure`,
`gamma`, `dof`, `dof_depth`, `dof_range`, `dof_fade_size`, `dof_blur_size`,
`dof_blur_ratio`, `dof_bias`, `dof_threshold`, `dof_gain`, `dof_fringe`,
`dof_fringe_angle_red`, `dof_fringe_angle_green`, `dof_fringe_angle_blue`,
`dof_fringe_red`, `dof_fringe_green`, `dof_fringe_blue`, `bloom`,
`bloom_threshold`, `bloom_intensity`, `bloom_radius`, `bloom_ratio`,
`bloom_blend`, `lens_dirt`, `lens_dirt_bloom`, `lens_dirt_glow`,
`lens_dirt_radius`, `lens_dirt_intensity`, `lens_dirt_power`,
`color_correction`, `contrast`, `brightness`, `saturation`, `vibrance`,
`color_burn`, `grain`, `grain_strength`, `grain_saturation`, `grain_size`,
`vignette`, `vignette_radius`, `vignette_softness`, `vignette_strength`,
`vignette_color`, `ca`, `ca_blur_amount`, `ca_red_offset`,
`ca_green_offset`, `ca_blue_offset`, `distort`, `distort_repeat`,
`distort_zoom_amount`, `distort_amount`

Ship your pack as a plain `.mishader` file (a zip is not needed - it is a
single small JSON document).
