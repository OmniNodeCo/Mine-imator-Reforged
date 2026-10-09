/// popup_worldgenerator_draw()
/// @desc World generator popup: creates a random blocky landscape (hills,
/// water and trees) from a seed, writes it as a .schematic file and puts
/// it on the workbench as a new scenery. Same seed and settings always
/// produce the same world.

function popup_worldgenerator_draw()
{
	var halfw, thirdw;
	halfw = (dw - 8) / 2
	thirdw = (dw - 16) / 3

	// What this does
	tab_control(36)
	draw_label(text_get("worldgeneratorinfo"), dx, dy + 16, fa_left, fa_middle, c_text_secondary, 1, font_label, 14, dw)
	tab_next()

	// Seed
	tab_control_textfield(true, 24)
	draw_textfield("worldgeneratorseed", dx, dy, dw, 24, popup.tbx_seed, null, "worldgeneratorseedtip", "top")
	tab_next()

	// Size presets (like the world import's selection sizes)
	tab_control(46)
	draw_label(text_get("worldgeneratorsize"), dx, dy - 3, fa_left, fa_top, c_text_secondary, 1, font_label)
	draw_radiobutton("worldgeneratorsmall", dx, dy + 22, 32, popup.tbx_size.text = "32", popup_worldgenerator_set_size)
	draw_radiobutton("worldgeneratormedium", dx + thirdw + 8, dy + 22, 64, popup.tbx_size.text = "64", popup_worldgenerator_set_size)
	draw_radiobutton("worldgeneratorlarge", dx + (thirdw + 8) * 2, dy + 22, 96, popup.tbx_size.text = "96", popup_worldgenerator_set_size)
	tab_next()

	// Custom size and height
	tab_control_textfield(true, 24)
	draw_textfield("worldgeneratorcustomsize", dx, dy, halfw, 24, popup.tbx_size, null, "", "top")
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

	// Generate. On success the scenery load takes over the popup slot
	// with the loading screen and closes itself when done - closing this
	// popup after generating would cancel the load before it starts
	tab_control_button_label()
	if (draw_button_label("worldgeneratorgenerate", dx + dw, dy, null, null, e_button.PRIMARY, null, e_anchor.RIGHT, false))
		action_worldgenerator_generate()
	tab_next()
}
