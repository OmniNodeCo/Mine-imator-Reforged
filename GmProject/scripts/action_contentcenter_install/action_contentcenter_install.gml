/// action_contentcenter_install()
/// @desc Starts the download (and installation) of the item selected in the
/// content center. Rigs ask for a save location first; shader packs install
/// straight into the Shaders folder, addons into the addon system and
/// particle presets into the Particles folder.

function action_contentcenter_install()
{
	if (http_content_file != null) // One download at a time
	{
		toast_new(e_toast.WARNING, text_get("contentbusy"))
		return 0
	}
	
	var pop, item, menu, filename, name, source, target;
	pop = popup_contentcenter
	
	if (!ds_map_valid(pop.selected))
		return 0
	
	item = pop.selected
	menu = pop.menu
	filename = contentcenter_filename(item)
	name = item[?"name"]
	
	if (menu = 0)
	{
		// Rigs: ask where to save the pack (page-only rigs use the
		// "Open download page" button instead)
		if (filename = "")
			return 0
		
		var path;
		path = file_dialog_save(text_get("filedialogsaverig") + " (*.zip)|*.zip", filename, setting_rigs_dir, text_get("filedialogsaverigcaption"))
		if (path = "")
			return 0
		path = filename_new_ext(path, ".zip")
		target = path
		
		// Hosted in the Reforged library, or a direct link to the
		// author's own server
		if (is_undefined(item[?"file"]))
			source = item[?"direct"]
		else
			source = link_content + filename
		
		// Remember the folder for the next download
		setting_rigs_dir = filename_dir(path)
	}
	else
	{
		// Shaders, addons and particles install straight into the app
		source = link_content + filename
		
		if (menu = 1)
			target = shaders_directory + filename
		else if (menu = 2)
			target = temp_file
		else
			target = particles_directory + filename
	}
	
	pop.downloading = filename
	pop.downloading_menu = menu
	pop.downloading_path = target
	pop.downloading_name = name
	pop.downloaded_bytes = 0
	pop.total_bytes = 0
	pop.error_message = ""
	pop.saved_name = ""
	
	log("Content center: downloading", name, "from", source, "to", target)
	http_content_file = http_get_file(source, target)
	return 1
}
