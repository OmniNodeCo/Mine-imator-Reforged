/// popup_contentcenter_draw()

function popup_contentcenter_draw()
{
	var pad, headerh, menuw, listw, rowh;
	pad = 12
	headerh = 32
	menuw = 128
	listw = 270
	rowh = 46
	
	// ---- Header: title + search field + refresh button ----
	// Custom popup: the framework draws no caption, so the header renders
	// the title (icon + text + BETA badge) itself; the refresh button sits
	// left of the popup's close button
	tab_control_textfield()
	
	var titlew;
	titlew = 200
	
	draw_image(spr_icons, icons.DOWNLOAD, dx + pad, dy + pad + 12, 1, 1, c_accent, 1)
	draw_label(text_get("contentcaption"), dx + pad + 28, dy + pad + 12, fa_left, fa_middle, c_accent, 1, font_heading)
	draw_set_font(font_heading)
	draw_image(spr_icons, icons.BETA, dx + pad + 28 + string_width(text_get("contentcaption")) + 12, dy + pad + 12, 1, 1, c_accent, 1)
	
	draw_textfield("contentsearch", dx + pad + titlew, dy + pad, dw - 88 - titlew, 24, popup.tbx_search, null, text_get("contentsearch"), "none")
	
	if (draw_button_icon("contentrefresh", dx + dw - 68, dy + pad, 24, 24, false, icons.RECENTS, null, http_content_index != null, "contentrefresh"))
		contentcenter_fetch(popup.menu, true)
	
	tab_next()
	
	// ---- Layout ----
	// The panes are anchored to the popup's bottom edge (content_y +
	// content_height), NOT to dh: on fixed-height popups dh overcounts by
	// the caption height and elements would end up below the popup
	var menux, listy, listbottom, listh;
	menux = dx + pad
	listy = dy + pad + headerh
	listbottom = content_y + content_height - pad
	listh = listbottom - listy
	
	var listx, detx, dety, detw, deth;
	listx = menux + menuw + 8
	detx = listx + listw + pad
	dety = listy
	detw = dx + dw - pad - detx
	deth = listh
	
	// ---- Menu column (the center's menus) ----
	var menunames, menuicons;
	menunames = array("contentmenurigs", "contentmenushaders", "contentmenuaddons", "contentmenuparticles")
	menuicons = array(icons.CHARACTER, icons.STAR, icons.LIBRARY, icons.CLOUD)
	
	for (var m = 0; m < 4; m++)
	{
		var mrowy, mhover, msel, mcolor;
		mrowy = listy + m * 34
		mhover = app_mouse_box(menux, mrowy, menuw, 30, "")
		msel = (popup.menu = m)
		
		mcolor = c_level_bottom
		if (msel)
			mcolor = merge_color(c_level_bottom, c_accent, 0.18)
		else if (mhover)
			mcolor = c_level_middle
		draw_box(menux, mrowy, menuw, 30, false, mcolor, 1)
		if (msel)
			draw_box(menux, mrowy, 3, 30, false, c_accent, 1)
		
		draw_image(spr_icons, menuicons[m], menux + 18, mrowy + 15, 1, 1, msel ? c_text_main : c_text_secondary, 1)
		draw_label(text_get(menunames[m]), menux + 34, mrowy + 15, fa_left, fa_middle, msel ? c_text_main : c_text_secondary, 1, font_label)
		
		if (mouse_left_pressed && mhover && !msel)
			action_contentcenter_select(m)
	}
	
	// ---- Filter the current menu's list by the search text ----
	var query, listcount;
	query = string_lower(popup.tbx_search.text)
	popup.filtered = []
	
	var curlist;
	curlist = popup.lists[popup.menu]
	
	if (!is_undefined(curlist) && ds_list_valid(curlist))
	{
		listcount = ds_list_size(curlist)
		for (var i = 0; i < listcount; i++)
		{
			var item, searchtext;
			item = curlist[|i]
			
			if (!ds_map_valid(item))
				continue
			
			searchtext = string_lower(item[?"name"])
			if (!is_undefined(item[?"author"]))
				searchtext += " " + string_lower(item[?"author"])
			if (!is_undefined(item[?"description"]))
				searchtext += " " + string_lower(item[?"description"])
			
			if (query != "" && string_pos(query, searchtext) = 0)
				continue
			
			popup.filtered[array_length(popup.filtered)] = item
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
	
	if (popup.loading[popup.menu])
		draw_label(text_get("contentloading", text_get(menunames[popup.menu])), listx + listw / 2, listy + listh / 2, fa_center, fa_middle, c_text_tertiary, a_text_tertiary, font_body_big)
	else if (popup.fail[popup.menu] != "")
		draw_label(popup.fail[popup.menu], listx + listw / 2, listy + listh / 2, fa_center, fa_middle, c_error, 1, font_label)
	else if (filteredcount = 0)
		draw_label(text_get("contentempty"), listx + listw / 2, listy + listh / 2, fa_center, fa_middle, c_text_tertiary, a_text_tertiary, font_body_big)
	else
	{
		var shownrows;
		shownrows = min(filteredcount, visiblerows)
		
		for (var r = 0; r < shownrows; r++)
		{
			var item, rowx, rowy, hovered, selected, filename;
			item = popup.filtered[popup.scroll + r]
			rowx = listx
			rowy = listy + r * rowh
			filename = contentcenter_filename(item)
			
			hovered = app_mouse_box(rowx, rowy, listw, rowh - 4, "")
			selected = (ds_map_valid(popup.selected) && popup.selected = item)
			
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
			
			// Name + author (the name is limited to leave room for the
			// right-aligned author label)
			draw_set_font(font_caption)
			var authorwid;
			authorwid = string_width(string(item[?"author"]))
			draw_set_font(font_label)
			draw_label(string_limit(item[?"name"], listw - 24 - authorwid - 8), rowx + 12, rowy + 12, fa_left, fa_bottom, selected ? c_text_main : c_text_secondary, 1, font_label)
			draw_label(string(item[?"author"]), rowx + listw - 12, rowy + 12, fa_right, fa_bottom, c_text_tertiary, a_text_tertiary, font_caption)
			
			// Status line: download progress, or the source of the item
			if (popup.downloading = filename && filename != "")
			{
				var pct;
				pct = contentcenter_progress(popup)
				if (pct >= 0)
					draw_label(text_get("contentdownloadingpct", string(floor(pct * 100))), rowx + 12, rowy + 30, fa_left, fa_bottom, c_accent, 1, font_caption)
				else
					draw_label(text_get("contentdownloadingbytes", string_filesize(popup.downloaded_bytes)), rowx + 12, rowy + 30, fa_left, fa_bottom, c_accent, 1, font_caption)
				
				// Progress bar under the row
				if (pct >= 0)
					draw_box(rowx + 2, rowy + rowh - 8, (listw - 4) * pct, 3, false, c_accent, 1)
			}
			else if (contentcenter_ispage(item))
				draw_label(text_get("contentpagetag"), rowx + 12, rowy + 30, fa_left, fa_bottom, c_text_tertiary, a_text_tertiary, font_caption)
			else if (!is_undefined(item[?"direct"]) && popup.menu = 0)
				draw_label(text_get("contentdirecttag"), rowx + 12, rowy + 30, fa_left, fa_bottom, c_text_tertiary, a_text_tertiary, font_caption)
			else
				draw_label(text_get("contenthostedtag"), rowx + 12, rowy + 30, fa_left, fa_bottom, c_text_tertiary, a_text_tertiary, font_caption)
			
			// Click selects; clicking the selected row again installs
			if (mouse_left_pressed && hovered)
			{
				if (selected && !contentcenter_ispage(item))
					action_contentcenter_install()
				else
					popup.selected = item
			}
		}
		
		// More note
		if (filteredcount > shownrows)
			draw_label(text_get("contentmore", filteredcount - shownrows), listx + listw / 2, listy + listh - 6, fa_center, fa_bottom, c_text_tertiary, a_text_tertiary, font_caption)
	}
	
	// ---- Details pane ----
	draw_box(detx, dety, detw, deth, false, c_level_bottom, 1)
	
	if (!ds_map_valid(popup.selected))
	{
		if (filteredcount > 0 || popup.loading[popup.menu])
			draw_label(text_get("contentselect"), detx + detw / 2, dety + deth / 2, fa_center, fa_middle, c_text_tertiary, a_text_tertiary, font_body_big)
	}
	else
		popup_contentcenter_draw_details(popup.selected, detx, dety, detw, deth)
}

/// popup_contentcenter_draw_details(item, x, y, width, height)
/// @arg item
/// @arg x
/// @arg y
/// @arg width
/// @arg height
/// @desc Draws the details pane for the selected content item.

function popup_contentcenter_draw_details(item, detx, dety, detw, deth)
{
	var pad;
	pad = 16
	
	// Name, author, description (separation = line advance: roughly the
	// font's line height, or wrapped lines overlap)
	draw_label(item[?"name"], detx + pad, dety + 14, fa_left, fa_top, c_text_main, 1, font_heading, 14, detw - pad * 2)
	
	if (!is_undefined(item[?"author"]))
		draw_label(text_get("contentby", item[?"author"]), detx + pad, dety + 48, fa_left, fa_top, c_text_tertiary, a_text_tertiary, font_caption)
	
	if (!is_undefined(item[?"description"]))
		draw_label(item[?"description"], detx + pad, dety + 64, fa_left, fa_top, c_text_secondary, a_text_secondary, font_body_big, 16, detw - pad * 2)
	
	// Source of the item
	var source;
	if (popup.menu = 0)
	{
		source = text_get("contentsourcehosted")
		if (contentcenter_ispage(item))
			source = text_get("contentsourcepage")
		else if (!is_undefined(item[?"direct"]))
			source = text_get("contentsourcedirect")
	}
	else
		source = text_get("contentsourcehosted")
	draw_label(source, detx + pad, dety + 126, fa_left, fa_top, c_text_tertiary, a_text_tertiary, font_caption, 12, detw - pad * 2)
	
	// Bottom area: status (progress / error / saved) + buttons
	var filename, buttony;
	filename = contentcenter_filename(item)
	buttony = dety + deth - pad - 32
	
	var downloadingthis;
	downloadingthis = (popup.downloading = filename && filename != "")
	
	// Status
	if (downloadingthis)
	{
		var pct, bary, barw;
		pct = contentcenter_progress(popup)
		bary = buttony - 26
		barw = detw - pad * 2
		
		if (pct >= 0)
		{
			draw_label(text_get("contentdownloadingpct", string(floor(pct * 100))), detx + pad, bary - 10, fa_left, fa_bottom, c_accent, 1, font_label)
			draw_box(detx + pad, bary, barw, 6, false, c_level_middle, 1)
			draw_box(detx + pad, bary, barw * clamp(pct, 0, 1), 6, false, c_accent, 1)
			if (popup.total_bytes > 0)
				draw_label(text_get("contentsize", string_filesize(popup.downloaded_bytes), string_filesize(popup.total_bytes)), detx + detw - pad, bary - 10, fa_right, fa_bottom, c_text_tertiary, a_text_tertiary, font_caption)
		}
		else
		{
			// Unknown total size: show the bytes downloaded so far and
			// pulse the bar
			draw_label(text_get("contentdownloadingbytes", string_filesize(popup.downloaded_bytes)), detx + pad, bary - 10, fa_left, fa_bottom, c_accent, 1, font_label)
			draw_box(detx + pad, bary, barw, 6, false, c_level_middle, 1)
			draw_box(detx + pad, bary, barw, 6, false, c_accent, 0.3 + 0.5 * abs(sin(current_time / 400)))
		}
	}
	else if (popup.error_message != "" && popup.error_name = item[?"name"])
		draw_label(popup.error_message, detx + pad, buttony - 46, fa_left, fa_bottom, c_error, 1, font_caption, 12, detw - pad * 2)
	else if (popup.saved_name = item[?"name"])
		draw_label(text_get("contentsavedto", popup.saved_path), detx + pad, buttony - 10, fa_left, fa_bottom, c_text_tertiary, a_text_tertiary, font_caption, 12, detw - pad * 2)
	
	// Buttons
	if (contentcenter_ispage(item))
	{
		// Page-only item: the only action is opening the author's page
		if (draw_button_label("contentopenpage", detx + pad, buttony, null, icons.LINK, e_button.PRIMARY))
		{
			log("Content center: opening download page", item[?"url"])
			url_open(item[?"url"])
		}
	}
	else
	{
		// Direct download / install
		var busy;
		busy = (http_content_file != null && !downloadingthis)
		
		var installlabel;
		if (popup.menu = 0)
			installlabel = text_get("contentdownload")
		else
			installlabel = text_get("contentinstall")
		
		if (downloadingthis)
			draw_button_label("contentdownloadingbtn", detx + pad, buttony, 150, icons.DOWNLOAD, e_button.PRIMARY, null, e_anchor.LEFT, true)
		else if (draw_button_label("contentinstall", detx + pad, buttony, 150, icons.DOWNLOAD, e_button.PRIMARY, null, e_anchor.LEFT, busy))
			action_contentcenter_install()
		
		// Secondary: open the author's page (fallback for direct downloads)
		if (!is_undefined(item[?"url"]))
		{
			if (draw_button_label("contentopenpage", detx + pad + 158, buttony, null, icons.LINK, e_button.SECONDARY))
			{
				log("Content center: opening download page", item[?"url"])
				url_open(item[?"url"])
			}
		}
	}
}

/// contentcenter_filename(item)
/// @arg item
/// @desc File name the given content item downloads as ("" when it has
/// none - those items open the author's page instead).

function contentcenter_filename(item)
{
	if (!is_undefined(item[?"file"]))
		return item[?"file"]
	if (!is_undefined(item[?"filename"]))
		return item[?"filename"]
	return ""
}

/// contentcenter_ispage(item)
/// @arg item
/// @desc Whether the item can only be downloaded from the author's own page.

function contentcenter_ispage(item)
{
	return (contentcenter_filename(item) = "" && !is_undefined(item[?"url"]))
}

/// contentcenter_progress(popup)
/// @arg popup
/// @desc Current download progress as a 0-1 value (-1 when the size is
/// unknown).

function contentcenter_progress(pop)
{
	if (pop.total_bytes > 0)
		return clamp(pop.downloaded_bytes / pop.total_bytes, 0, 1)
	return -1
}
