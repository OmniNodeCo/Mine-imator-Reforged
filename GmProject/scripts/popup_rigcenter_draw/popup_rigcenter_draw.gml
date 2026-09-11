/// popup_rigcenter_draw()

function popup_rigcenter_draw()
{
	// ---- Search field ----
	tab_control_textfield()
	draw_textfield("rigcentersearch", dx, dy, dw - 28, 24, popup.tbx_search, null)
	
	// Refresh button
	if (draw_button_icon("rigcenterrefresh", dx + dw - 24, dy, 24, 24, false, icons.RECENTS, null, http_rigs_index != null, "rigcenterrefresh"))
	{
		popup.list = undefined
		popup.loading = true
		popup.fail_message = ""
		popup.filtered = []
		http_rigs_index = http_get(link_rigs + "index.json")
	}
	
	tab_next()
	
	// ---- List ----
	var listy, listh, rowh;
	listy = dy + 10
	listh = content_height - 34 - 24 - 16
	rowh = 44
	
	// Filter the list by the search text
	var query, listcount;
	query = string_lower(popup.tbx_search.text)
	popup.filtered = []
	
	if (!is_undefined(popup.list) && ds_list_valid(popup.list))
	{
		listcount = ds_list_size(popup.list)
		for (var i = 0; i < listcount; i++)
		{
			var rig;
			rig = popup.list[|i]
			
			if (query != "" && string_pos(query, string_lower(rig[?"name"] + " " + rig[?"author"] + " " + rig[?"description"])) = 0)
				continue
			
			popup.filtered[array_length(popup.filtered)] = rig
		}
	}
	
	var filteredcount;
	filteredcount = array_length(popup.filtered)
	
	// Rows that fit in the list area, and the highest safe scroll offset.
	// Never let scroll + row count exceed the array length: out-of-bounds
	// array reads return undefined, and using that as a ds map id is a
	// fatal "Invalid id 0" crash.
	var visiblerows, maxscroll;
	visiblerows = max(1, floor(listh / rowh))
	maxscroll = max(0, filteredcount - visiblerows)
	
	// Clamp the current scroll (the search may have shrunk the list)
	popup.scroll = clamp(popup.scroll, 0, maxscroll)
	
	// Scroll with the mouse wheel
	if (app_mouse_box(content_x, listy, content_width, listh, ""))
	{
		if (mouse_wheel_up())
			popup.scroll = max(0, popup.scroll - 1)
		if (mouse_wheel_down())
			popup.scroll = min(maxscroll, popup.scroll + 1)
	}
	
	// Status line
	if (popup.loading)
		draw_label(text_get("rigcenterloading"), content_x + content_width / 2, listy + listh / 2, fa_center, fa_center, c_text_tertiary, a_text_tertiary, font_body_big)
	else if (popup.fail_message != "")
		draw_label(popup.fail_message, content_x + content_width / 2, listy + listh / 2, fa_center, fa_center, c_error, 1, font_label)
	else if (filteredcount = 0)
		draw_label(text_get("rigcenterempty"), content_x + content_width / 2, listy + listh / 2, fa_center, fa_center, c_text_tertiary, a_text_tertiary, font_body_big)
	else
	{
		// Rows
		var shownrows;
		shownrows = min(filteredcount, visiblerows)
		
		for (var r = 0; r < shownrows; r++)
		{
			var rig, rowx, rowy;
			rig = popup.filtered[popup.scroll + r]
			rowx = content_x
			rowy = listy + r * rowh
			
			// Row background + hover
			var hovered;
			hovered = app_mouse_box(rowx, rowy, content_width, rowh - 4, "")
			draw_box(rowx, rowy, content_width, rowh - 4, false, hovered ? c_level_middle : c_level_bottom, 1)
			
			// Name + author
			draw_label(rig[?"name"], rowx + 12, rowy + 10, fa_left, fa_bottom, c_text_main, a_text_main, font_label)
			draw_label(rig[?"author"], rowx + content_width - 12, rowy + 10, fa_right, fa_bottom, c_text_tertiary, a_text_tertiary, font_caption)
			
			// Description
			draw_label(rig[?"description"], rowx + 12, rowy + 28, fa_left, fa_bottom, c_text_secondary, a_text_secondary, font_caption)
			
			// Download status / action on click
			var filename;
			filename = rig[?"file"]
			
			if (popup.downloading = filename)
			{
				// Progress bar under the row
				draw_box(rowx + 2, rowy + rowh - 8, (content_width - 4) * popup.progress, 3, false, c_accent, 1)
			}
			else if (mouse_left_pressed && hovered)
				popup_rigcenter_download(rig)
		}
		
		// More note
		if (filteredcount > shownrows)
			draw_label(text_get("rigcentermore", filteredcount - shownrows), content_x + content_width / 2, listy + listh - 8, fa_center, fa_bottom, c_text_tertiary, a_text_tertiary, font_caption)
	}
}

/// popup_rigcenter_download(rig)
/// @arg rig
/// @desc Starts downloading the given rig entry.

function popup_rigcenter_download(rig)
{
	if (http_rigs_file != null) // One download at a time
		return 0
	
	var filename, name;
	filename = rig[?"file"]
	name = rig[?"name"]
	
	popup.downloading = filename
	popup.downloading_path = rigs_directory + filename_name(filename)
	popup.downloading_name = name
	popup.progress = 0
	popup.fail_message = ""
	
	log("Rig center: downloading", filename)
	http_rigs_file = http_get_file(link_rigs + filename, popup.downloading_path)
	return 1
}
