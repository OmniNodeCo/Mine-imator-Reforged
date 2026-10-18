/// language_load(filename, map, reload)
/// @arg filename
/// @arg map
/// @arg [reload]

function language_load(fn, map, reload = false)
{
	log("Loading language file", fn)
	
	ds_map_clear(map)
	
	if (filename_ext(fn) = ".milanguage")
	{
		// Convert unicode (external)
		var convfn = file_directory + "conv.tmp";
		json_file_convert_unicode(fn, convfn)
		
		if (!file_exists_lib(convfn))
		{
			var msg = "An error occurred while reading the language file:\nCould not convert.";
			log(msg)
			window_set_caption("Error")
			show_message(msg)
			window_set_caption("")
			return 0
		}
		
		// Load JSON
		var jsonmap = json_load(convfn);
		if (ds_map_valid(jsonmap))
		{
			language_load_map("", jsonmap, map)
			ds_map_destroy(jsonmap)
		}
		else
		{
			var msg = "An error occured while reading the language file:\n" + json_error + " on line " + string(json_line) + ", column " + string(json_column);
			log(msg)
			window_set_caption("Error")
			show_message(msg)
			window_set_caption("")
			return 0
		}
	}
	else
		language_load_legacy(fn, map)
	
	// Check keys (missing texts display as English - the list is logged
	// so translators can complete their file without a wall of popups)
	if (!reload && map != language_english_map)
	{
		var missingkeyslist, key;
		missingkeyslist = ds_list_create()
		key = ds_map_find_first(language_english_map);
		while (!is_undefined(key))
		{
			if (is_undefined(map[?key]))
				ds_list_add(missingkeyslist, key)
			key = ds_map_find_next(language_english_map, key)	
		}
		
		if (ds_list_size(missingkeyslist) > 0)
		{
			ds_list_sort(missingkeyslist, true)
			log(string(ds_list_size(missingkeyslist)) + " texts are missing in the translation and will display as English:")
			for (var i = 0; i < ds_list_size(missingkeyslist); i++)
				log(missingkeyslist[|i] + ": " + string_replace_all(language_english_map[?missingkeyslist[|i]], "\n", "\\n"))
		}
	}
}
