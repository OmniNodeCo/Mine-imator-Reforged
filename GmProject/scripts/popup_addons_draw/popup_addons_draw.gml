/// popup_addons_draw()
/// @desc The Addons browser: lists installed addons, shows their details and
//! offers importing their rigs or removing them.

function popup_addons_draw()
{
	var pad, headerh, listw, rowh;
	pad = 12
	headerh = 40
	listw = 240
	rowh = 46

	// ---- Header: title (icon + text + BETA badge), install button, count ----
	// Custom popup: the framework draws no caption, so the header renders
	// the title itself (the caption key lives in the addon/ block)
	tab_control(headerh)
	
	draw_image(spr_icons, icons.LIBRARY, dx + pad, dy + pad + 14, 1, 1, c_accent, 1)
	draw_label(text_get("addoncaption"), dx + pad + 28, dy + pad + 14, fa_left, fa_middle, c_accent, 1, font_heading)
	draw_set_font(font_heading)
	draw_image(spr_icons, icons.BETA, dx + pad + 28 + string_width(text_get("addoncaption")) + 12, dy + pad + 14, 1, 1, c_accent, 1)
	
	if (draw_button_label("addoninstall", dx + pad + 176, dy + pad + 2, null, icons.DOWNLOAD, e_button.SECONDARY, null, e_anchor.LEFT))
		action_install_addon()

	draw_label(text_get("addoncount", ds_list_size(addon_list)), dx + dw - pad, dy + pad + 14, fa_right, fa_middle, c_text_tertiary, a_text_tertiary, font_caption)
	tab_next()

	// ---- Layout ----
	var listx, listy, listbottom, listh;
	listx = dx + pad
	listy = dy + pad + headerh
	listbottom = content_y + content_height - pad
	listh = listbottom - listy

	var detx, dety, detw, deth;
	detx = listx + listw + pad
	dety = listy
	detw = dx + dw - pad - detx
	deth = listh

	// ---- List scrolling ----
	var listcount, visiblerows, maxscroll;
	listcount = ds_list_size(addon_list)
	visiblerows = max(1, floor(listh / rowh))
	maxscroll = max(0, listcount - visiblerows)
	popup.scroll = clamp(popup.scroll, 0, maxscroll)

	if (app_mouse_box(listx, listy, listw, listh, ""))
	{
		if (mouse_wheel_up())
			popup.scroll = max(0, popup.scroll - 1)
		if (mouse_wheel_down())
			popup.scroll = min(maxscroll, popup.scroll + 1)
	}

	// ---- List pane ----
	draw_box(listx, listy, listw, listh, false, c_level_bottom, 1)

	if (listcount = 0)
	{
		draw_label(text_get("addonempty"), listx + listw / 2, listy + listh / 2, fa_center, fa_middle, c_text_tertiary, a_text_tertiary, font_body_big)
	}
	else
	{
		var shownrows;
		shownrows = min(listcount, visiblerows)

		for (var r = 0; r < shownrows; r++)
		{
			var addon, rowx, rowy, hovered, selected;
			addon = addon_list[|popup.scroll + r]
			rowx = listx
			rowy = listy + r * rowh

			hovered = app_mouse_box(rowx, rowy, listw, rowh - 4, "")
			selected = (ds_map_valid(popup.selected) && popup.selected = addon)

			var rowcolor;
			rowcolor = c_level_bottom
			if (selected)
				rowcolor = merge_color(c_level_bottom, c_accent, 0.18)
			else if (hovered)
				rowcolor = c_level_middle
			draw_box(rowx, rowy, listw, rowh - 4, false, rowcolor, 1)
			if (selected)
				draw_box(rowx, rowy, 3, rowh - 4, false, c_accent, 1)

			draw_set_font(font_caption)
			var authorwid;
			authorwid = string_width(string(addon[?"author"]))
			draw_set_font(font_label)
			draw_label(string_limit(addon[?"name"], listw - 24 - authorwid - 8), rowx + 12, rowy + 12, fa_left, fa_bottom, selected ? c_text_main : c_text_secondary, 1, font_label)
			draw_label(string(addon[?"author"]), rowx + listw - 12, rowy + 12, fa_right, fa_bottom, c_text_tertiary, a_text_tertiary, font_caption)

			if (mouse_left_pressed && hovered)
				popup.selected = addon
		}
	}

	// ---- Detail pane ----
	draw_box(detx, dety, detw, deth, false, c_level_bottom, 1)

	if (ds_map_valid(popup.selected))
	{
		var addon, tex, posy;
		addon = popup.selected
		posy = dety + 20

		draw_label(string_limit(addon[?"name"], detw - 24), detx + 16, posy, fa_left, fa_top, c_text_main, 1, font_subheading)
		posy += 30

		var byline;
		byline = text_get("addonversion", string(addon[?"version"]))
		if (string(addon[?"author"]) != "")
			byline = text_get("addonby", addon[?"author"]) + "  -  " + byline
		draw_label(byline, detx + 16, posy, fa_left, fa_top, c_text_tertiary, a_text_tertiary, font_caption)
		posy += 24

		// Description (wrapped)
		tex = string_wrap(string(addon[?"description"]), detw - 32)
		if (tex != "")
		{
			draw_label(tex, detx + 16, posy, fa_left, fa_top, c_text_secondary, 1, font_label)
			posy += 20 + string_count("\n", tex) * 20
		}

		posy += 8

		// Contents
		var contents;
		contents = ""
		if (ds_list_size(addon[?"shaders"]) > 0)
			contents = text_get("addonshaders", ds_list_size(addon[?"shaders"]))
		if (ds_list_size(addon[?"particles"]) > 0)
		{
			if (contents != "")
				contents += "\n"
			contents += text_get("addonparticles", ds_list_size(addon[?"particles"]))
		}
		if (ds_list_size(addon[?"rigs"]) > 0)
		{
			if (contents != "")
				contents += "\n"
			contents += text_get("addonrigs", ds_list_size(addon[?"rigs"]))
		}
		draw_label(contents, detx + 16, posy, fa_left, fa_top, c_text_secondary, 1, font_label)
		posy += 20 + string_count("\n", contents) * 20

		// Buttons (bottom of the detail pane)
		var buttony;
		buttony = dety + deth - 40

		if (ds_list_size(addon[?"rigs"]) > 0)
		{
			if (draw_button_label("addonimport", detx + 16, buttony, null, icons.ASSET_IMPORT, e_button.PRIMARY, null, e_anchor.LEFT))
				action_addon_import_rigs()
		}

		if (draw_button_label("addonuninstall", detx + detw - 16, buttony, null, icons.DELETE, e_button.SECONDARY, null, e_anchor.RIGHT))
			action_addon_uninstall()
	}
	else
	{
		draw_label(text_get("addonselect"), detx + detw / 2, dety + deth / 2, fa_center, fa_middle, c_text_tertiary, a_text_tertiary, font_body_big)
	}
}
