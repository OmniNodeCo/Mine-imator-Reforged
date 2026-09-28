/// popup_rigcenter_draw()

function popup_rigcenter_draw()
{
	var pad, headerh, listw, rowh;
	pad = 12
	headerh = 32
	listw = 280
	rowh = 46
	
	// ---- Header: search field + refresh button ----
	// (refresh sits left of the popup's close button)
	tab_control_textfield()
	draw_textfield("rigcentersearch", dx + pad, dy + pad, dw - 88, 24, popup.tbx_search, null, text_get("rigcentersearch"), "none")
	
	if (draw_button_icon("rigcenterrefresh", dx + dw - 68, dy + pad, 24, 24, false, icons.RECENTS, null, http_rigs_index != null, "rigcenterrefresh"))
	{
		popup.list = undefined
		popup.loading = true
		popup.fail_message = ""
		popup.filtered = []
		popup.selected = undefined
		http_rigs_index = http_get(link_rigs + "index.json")
	}
	
	tab_next()
	
	// ---- Layout ----
	var listx, listy, listh;
	listx = dx + pad
	listy = dy + pad + headerh
	listh = dh - headerh - pad * 2
	
	var detx, dety, detw, deth;
	detx = listx + listw + pad
	dety = listy
	detw = dx + dw - pad - detx
	deth = listh
	
	// ---- Filter the list by the search text ----
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
	if (app_mouse_box(listx, listy, listw, listh, ""))
	{
		if (mouse_wheel_up())
			popup.scroll = max(0, popup.scroll - 1)
		if (mouse_wheel_down())
			popup.scroll = min(maxscroll, popup.scroll + 1)
	}
	
	// ---- List pane ----
	draw_box(listx, listy, listw, listh, false, c_level_bottom, 1)
	
	if (popup.loading)
		draw_label(text_get("rigcenterloading"), listx + listw / 2, listy + listh / 2, fa_center, fa_middle, c_text_tertiary, a_text_tertiary, font_body_big)
	else if (popup.fail_message != "")
		draw_label(popup.fail_message, listx + listw / 2, listy + listh / 2, fa_center, fa_middle, c_error, 1, font_label)
	else if (filteredcount = 0)
		draw_label(text_get("rigcenterempty"), listx + listw / 2, listy + listh / 2, fa_center, fa_middle, c_text_tertiary, a_text_tertiary, font_body_big)
	else
	{
		var shownrows;
		shownrows = min(filteredcount, visiblerows)
		
		for (var r = 0; r < shownrows; r++)
		{
			var rig, rowx, rowy, hovered, selected, filename;
			rig = popup.filtered[popup.scroll + r]
			rowx = listx
			rowy = listy + r * rowh
			filename = popup_rigcenter_filename(rig)
			
			hovered = app_mouse_box(rowx, rowy, listw, rowh - 4, "")
			selected = (ds_map_valid(popup.selected) && popup.selected = rig)
			
			// Row background, hover and selection
			var rowcolor;
			rowcolor = c_level_bottom
			if (selected)
				rowcolor = merge_color(c_level_bottom, c_accent, 0.18)
			else if (hovered)
				rowcolor = c_level_middle
			draw_box(rowx, rowy, listw, rowh - 4, false, rowcolor, 1)
			if (selected)
				draw_box(rowx, rowy, 3, rowh - 4, false, c_accent, 1)
			
			// Name + author
			draw_set_font(font_label)
			draw_label(string_limit(rig[?"name"], listw - 24), rowx + 12, rowy + 12, fa_left, fa_bottom, selected ? c_text_main : c_text_secondary, 1, font_label)
			draw_label(rig[?"author"], rowx + listw - 12, rowy + 12, fa_right, fa_bottom, c_text_tertiary, a_text_tertiary, font_caption)
			
			// Status line: download progress, or the source of the rig
			if (popup.downloading = filename && filename != "")
			{
				var pct;
				pct = popup_rigcenter_progress(popup)
				if (pct >= 0)
					draw_label(text_get("rigcenterdownloadingpct", string(floor(pct * 100))), rowx + 12, rowy + 30, fa_left, fa_bottom, c_accent, 1, font_caption)
				else
					draw_label(text_get("rigcenterdownloadingbytes", string_filesize(popup.downloaded_bytes)), rowx + 12, rowy + 30, fa_left, fa_bottom, c_accent, 1, font_caption)
				
				// Progress bar under the row
				if (pct >= 0)
					draw_box(rowx + 2, rowy + rowh - 8, (listw - 4) * pct, 3, false, c_accent, 1)
			}
			else if (popup_rigcenter_ispage(rig))
				draw_label(text_get("rigcenterpagetag"), rowx + 12, rowy + 30, fa_left, fa_bottom, c_text_tertiary, a_text_tertiary, font_caption)
			else
				draw_label(text_get("rigcenterdirecttag"), rowx + 12, rowy + 30, fa_left, fa_bottom, c_text_tertiary, a_text_tertiary, font_caption)
			
			// Click selects; clicking the selected row again starts the download
			if (mouse_left_pressed && hovered)
			{
				if (selected && !popup_rigcenter_ispage(rig))
					popup_rigcenter_download(rig)
				else
					popup.selected = rig
			}
		}
		
		// More note
		if (filteredcount > shownrows)
			draw_label(text_get("rigcentermore", filteredcount - shownrows), listx + listw / 2, listy + listh - 6, fa_center, fa_bottom, c_text_tertiary, a_text_tertiary, font_caption)
	}
	
	// ---- Details pane ----
	draw_box(detx, dety, detw, deth, false, c_level_bottom, 1)
	
	if (!ds_map_valid(popup.selected))
	{
		if (filteredcount > 0 || popup.loading)
			draw_label(text_get("rigcenterselect"), detx + detw / 2, dety + deth / 2, fa_center, fa_middle, c_text_tertiary, a_text_tertiary, font_body_big)
	}
	else
		popup_rigcenter_draw_details(popup.selected, detx, dety, detw, deth)
}

/// popup_rigcenter_draw_details(rig, x, y, width, height)
/// @arg rig
/// @arg x
/// @arg y
/// @arg width
/// @arg height
/// @desc Draws the details pane for the selected rig.

function popup_rigcenter_draw_details(rig, detx, dety, detw, deth)
{
	var pad;
	pad = 16
	
	// Name, author, description
	draw_label(rig[?"name"], detx + pad, dety + 14, fa_left, fa_top, c_text_main, 1, font_heading, 2, detw - pad * 2)
	draw_label(text_get("rigcenterby", rig[?"author"]), detx + pad, dety + 44, fa_left, fa_top, c_text_tertiary, a_text_tertiary, font_caption)
	draw_label(rig[?"description"], detx + pad, dety + 62, fa_left, fa_top, c_text_secondary, a_text_secondary, font_body_big, 4, detw - pad * 2)
	
	// Source of the rig
	var source;
	source = text_get("rigcentersourcehosted")
	if (popup_rigcenter_ispage(rig))
		source = text_get("rigcentersourcepage")
	else if (!is_undefined(rig[?"direct"]))
		source = text_get("rigcentersourcedirect")
	draw_label(source, detx + pad, dety + 122, fa_left, fa_top, c_text_tertiary, a_text_tertiary, font_caption, 3, detw - pad * 2)
	
	// Bottom area: status (progress / error / saved) + buttons
	var filename, buttony;
	filename = popup_rigcenter_filename(rig)
	buttony = dety + deth - pad - 32
	
	var downloadingthis;
	downloadingthis = (popup.downloading = filename && filename != "")
	
	// Status
	if (downloadingthis)
	{
		var pct, bary, barw;
		pct = popup_rigcenter_progress(popup)
		bary = buttony - 26
		barw = detw - pad * 2
		
		if (pct >= 0)
		{
			draw_label(text_get("rigcenterdownloadingpct", string(floor(pct * 100))), detx + pad, bary - 10, fa_left, fa_bottom, c_accent, 1, font_label)
			draw_box(detx + pad, bary, barw, 6, false, c_level_middle, 1)
			draw_box(detx + pad, bary, barw * clamp(pct, 0, 1), 6, false, c_accent, 1)
			if (popup.total_bytes > 0)
				draw_label(text_get("rigcentersize", string_filesize(popup.downloaded_bytes), string_filesize(popup.total_bytes)), detx + detw - pad, bary - 10, fa_right, fa_bottom, c_text_tertiary, a_text_tertiary, font_caption)
		}
		else
		{
			// Unknown total size: show the bytes downloaded so far and pulse the bar
			draw_label(text_get("rigcenterdownloadingbytes", string_filesize(popup.downloaded_bytes)), detx + pad, bary - 10, fa_left, fa_bottom, c_accent, 1, font_label)
			draw_box(detx + pad, bary, barw, 6, false, c_level_middle, 1)
			draw_box(detx + pad, bary, barw, 6, false, c_accent, 0.3 + 0.5 * abs(sin(current_time / 400)))
		}
	}
	else if (popup.error_message != "" && popup.error_name = rig[?"name"])
		draw_label(popup.error_message, detx + pad, buttony - 46, fa_left, fa_bottom, c_error, 1, font_caption, 3, detw - pad * 2)
	else if (popup.saved_name = rig[?"name"])
		draw_label(text_get("rigcentersavedto", popup.saved_path), detx + pad, buttony - 10, fa_left, fa_bottom, c_text_tertiary, a_text_tertiary, font_caption, 3, detw - pad * 2)
	
	// Buttons
	if (popup_rigcenter_ispage(rig))
	{
		// Page-only rig: the only action is opening the author's page
		if (draw_button_label("rigcenteropenpage", detx + pad, buttony, null, icons.LINK, e_button.PRIMARY))
		{
			log("Rig center: opening download page", rig[?"url"])
			url_open(rig[?"url"])
		}
	}
	else
	{
		// Direct download
		var busy;
		busy = (http_rigs_file != null && !downloadingthis)
		
		if (downloadingthis)
			draw_button_label("rigcenterdownloadingbtn", detx + pad, buttony, 150, icons.DOWNLOAD, e_button.PRIMARY, null, e_anchor.LEFT, true)
		else if (draw_button_label("rigcenterdownload", detx + pad, buttony, 150, icons.DOWNLOAD, e_button.PRIMARY, null, e_anchor.LEFT, busy))
			popup_rigcenter_download(rig)
		
		// Secondary: open the author's page (fallback for direct downloads)
		if (!is_undefined(rig[?"url"]))
		{
			if (draw_button_label("rigcenteropenpage", detx + pad + 158, buttony, null, icons.LINK, e_button.SECONDARY))
			{
				log("Rig center: opening download page", rig[?"url"])
				url_open(rig[?"url"])
			}
		}
	}
}

/// popup_rigcenter_filename(rig)
/// @arg rig
/// @desc File name the given rig entry downloads as ("" when it has none).

function popup_rigcenter_filename(rig)
{
	if (!is_undefined(rig[?"file"]))
		return rig[?"file"]
	if (!is_undefined(rig[?"filename"]))
		return rig[?"filename"]
	return ""
}

/// popup_rigcenter_ispage(rig)
/// @arg rig
/// @desc Whether the rig can only be downloaded from the author's own page.

function popup_rigcenter_ispage(rig)
{
	return (popup_rigcenter_filename(rig) = "" && !is_undefined(rig[?"url"]))
}

/// popup_rigcenter_progress(popup)
/// @arg popup
/// @desc Current download progress as a 0-1 value (-1 when the size is unknown).

function popup_rigcenter_progress(popup)
{
	if (popup.total_bytes > 0)
		return clamp(popup.downloaded_bytes / popup.total_bytes, 0, 1)
	return -1
}

/// popup_rigcenter_download(rig)
/// @arg rig
/// @desc Asks where to save the given rig entry and starts downloading it there.

function popup_rigcenter_download(rig)
{
	if (http_rigs_file != null) // One download at a time
	{
		toast_new(e_toast.WARNING, text_get("rigcenterbusy"))
		return 0
	}
	
	var filename, name, source;
	filename = popup_rigcenter_filename(rig)
	name = rig[?"name"]
	
	// Where the pack downloads from: our release (hosted entries) or the
	// author's own server (direct entries, e.g. Google Drive)
	if (is_undefined(rig[?"file"]))
		source = rig[?"direct"]
	else
		source = link_rigs + filename
	
	// Ask the user where to save the rig pack
	var path;
	path = file_dialog_save(text_get("filedialogsaverig") + " (*.zip)|*.zip", filename, setting_rigs_dir, text_get("filedialogsaverigcaption"))
	if (path = "")
		return 0
	path = filename_new_ext(path, ".zip")
	
	popup.downloading = filename
	popup.downloading_path = path
	popup.downloading_name = name
	popup.downloaded_bytes = 0
	popup.total_bytes = 0
	popup.error_message = ""
	popup.saved_name = ""
	
	// Remember the folder for the next download
	setting_rigs_dir = filename_dir(path)
	
	log("Rig center: downloading", name, "from", source, "to", path)
	http_rigs_file = http_get_file(source, path)
	return 1
}
