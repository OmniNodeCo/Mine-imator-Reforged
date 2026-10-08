/// popup_worldgenerator_draw()
/// @desc World generator popup: creates a random blocky landscape (hills,
/// water and trees) from a seed, writes it as a .schematic file and puts
/// it on the workbench as a new scenery. Same seed and settings always
/// produce the same world.

function popup_worldgenerator_draw()
{
	var halfw;
	halfw = (dw - 8) / 2

	// What this does
	tab_control(36)
	draw_label(text_get("worldgeneratorinfo"), dx, dy + 16, fa_left, fa_middle, c_text_secondary, 1, font_label, 14, dw)
	tab_next()

	// Seed
	tab_control_textfield(true, 24)
	draw_textfield("worldgeneratorseed", dx, dy, dw, 24, popup.tbx_seed, null, "worldgeneratorseedtip", "top")
	tab_next()

	// Size and height
	tab_control_textfield(true, 24)
	draw_textfield("worldgeneratorsize", dx, dy, halfw, 24, popup.tbx_size, null, "", "top")
	draw_textfield("worldgeneratorheight", dx + halfw + 8, dy, halfw, 24, popup.tbx_height, null, "", "top")
	tab_next()

	// Roughness
	tab_control_textfield(true, 24)
	draw_textfield("worldgeneratorroughness", dx, dy, halfw, 24, popup.tbx_roughness, null, "worldgeneratorroughnesstip", "top")
	tab_next()

	// Trees and water
	tab_control(24)
	draw_switch("worldgeneratortrees", dx, dy, popup.trees, popup_worldgenerator_set_trees)
	tab_next()
	tab_control(24)
	draw_switch("worldgeneratorwater", dx, dy, popup.water, popup_worldgenerator_set_water)
	tab_next()

	// Hint
	tab_control(18)
	draw_label(text_get("worldgeneratorhint"), dx, dy + 8, fa_left, fa_middle, c_text_tertiary, a_text_tertiary, font_caption, 12, dw)
	tab_next()

	// Generate
	tab_control_button_label()
	if (draw_button_label("worldgeneratorgenerate", dx + dw, dy, null, null, e_button.PRIMARY, null, e_anchor.RIGHT, false))
	{
		if (action_worldgenerator_generate())
			popup_close()
	}
	tab_next()
}
