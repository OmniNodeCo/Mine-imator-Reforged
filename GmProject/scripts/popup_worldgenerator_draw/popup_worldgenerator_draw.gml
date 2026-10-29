/// popup_worldgenerator_draw()
/// @desc World generator popup: creates a random blocky world (hills,
/// islands, mountains or flat land, with caves, water, trees, villages
/// and cities) from a seed, writes it as a .schematic file and puts
/// it on the workbench as a new scenery. Same seed and settings always
/// produce the same world.

function popup_worldgenerator_draw()
{
	var halfw, thirdw, quarterw;
	halfw = (dw - 8) / 2
	thirdw = (dw - 16) / 3
	quarterw = (dw - 24) / 4

	// What this does
	tab_control(36)
	draw_label(text_get("worldgeneratorinfo"), dx, dy + 16, fa_left, fa_middle, c_text_secondary, 1, font_label, 14, dw)
	tab_next()

	// Seed: an empty field rolls a fresh random seed on every generate,
	// the dice button rolls one into the field to keep or share
	tab_control_textfield(true, 24)
	draw_textfield("worldgeneratorseed", dx, dy, dw - 36, 24, popup.tbx_seed, null, text_get("worldgeneratorseedplaceholder"), "top")
	if (draw_button_icon("worldgeneratornewseed", dx + dw - 28, dy - 2, 28, 28, false, icons.RANDOMIZE, null, false, "worldgeneratornewseed"))
		popup.tbx_seed.text = worldgenerator_mc_seed_string(worldgenerator_mc_random_seed())
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

	// Terrain type: standard hills, a lone island, mountain ranges
	// or flat land
	tab_control(46)
	draw_label(text_get("worldgeneratorterrain"), dx, dy - 3, fa_left, fa_top, c_text_secondary, 1, font_label)
	draw_radiobutton("worldgeneratortstandard", dx, dy + 22, 0, popup.terrain = 0, popup_worldgenerator_set_terrain)
	draw_radiobutton("worldgeneratortisland", dx + quarterw, dy + 22, 1, popup.terrain = 1, popup_worldgenerator_set_terrain)
	draw_radiobutton("worldgeneratortmountains", dx + quarterw * 2, dy + 22, 2, popup.terrain = 2, popup_worldgenerator_set_terrain)
	draw_radiobutton("worldgeneratortflat", dx + quarterw * 3, dy + 22, 3, popup.terrain = 3, popup_worldgenerator_set_terrain)
	tab_next()

	// Buildings: none, a village of houses around a well, or a city
	// of towers on streets
	tab_control(46)
	draw_label(text_get("worldgeneratorbuildings"), dx, dy - 3, fa_left, fa_top, c_text_secondary, 1, font_label)
	draw_radiobutton("worldgeneratorbnone", dx, dy + 22, 0, popup.buildings = 0, popup_worldgenerator_set_buildings)
	draw_radiobutton("worldgeneratorbvillage", dx + thirdw + 8, dy + 22, 1, popup.buildings = 1, popup_worldgenerator_set_buildings)
	draw_radiobutton("worldgeneratorbcity", dx + (thirdw + 8) * 2, dy + 22, 2, popup.buildings = 2, popup_worldgenerator_set_buildings)
	tab_next()

	// Trees, water and caves
	tab_control(24)
	draw_switch("worldgeneratortrees", dx, dy, popup.trees, popup_worldgenerator_set_trees)
	tab_next()
	tab_control(24)
	draw_switch("worldgeneratorwater", dx, dy, popup.water, popup_worldgenerator_set_water)
	tab_next()
	tab_control(24)
	draw_switch("worldgeneratorcaves", dx, dy, popup.caves, popup_worldgenerator_set_caves)
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
