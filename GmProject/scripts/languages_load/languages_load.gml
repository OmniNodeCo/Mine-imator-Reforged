/// languages_load()

function languages_load()
{
	var fn = languages_file;
	
	if (!file_exists_lib(fn))
		return 0
	
	log("Loading languages", fn)
	
	// Decode
	var map = json_load(fn);
	if (!ds_map_valid(map))
		return 0
	
	load_format = map[?"format"]
	log("load_format", load_format)
	
	var list, obj;
	list = map[?"languages"]
	
	// File names the catalog knows (also used to skip them below)
	var catalog_fns;
	catalog_fns = array()
	
	for (var i = 0; i < ds_list_size(list); i++)
	{
		map = list[|i]
		
		var name, locale, fn;
		name = value_get_string(map[?"name"], "")
		locale = value_get_string(map[?"locale"], "")
		fn = value_get_string(map[?"filename"], "")
		
		language_remove(fn)
		
		var obj = new_obj(obj_language);
		obj.name = name
		obj.locale = locale
		obj.filename = fn
		
		catalog_fns[array_length(catalog_fns)] = fn
	}
	
	ds_list_destroy(list)
	
	// Auto-discovery: register any .milanguage file dropped into the
	// Languages folder that the catalog does not list yet, using the
	// name and locale from the file's own header. The catalog on disk is
	// left alone - the entries live for this session and the picker
	// shows them next to the bundled languages
	var files, known, header;
	files = file_find(languages_directory, ".milanguage")
	for (var i = 0; i < array_length(files); i++)
	{
		fn = filename_name(files[i])
		
		known = false
		for (var j = 0; j < array_length(catalog_fns); j++)
		{
			if (catalog_fns[j] = fn)
				known = true
		}
		if (known)
			continue
		
		header = languages_read_header(files[i])
		if (header = null)
			continue
		
		var obj = new_obj(obj_language);
		obj.name = header[0]
		obj.locale = header[1]
		obj.filename = fn
		log("Discovered language file", fn, header[0], header[1])
	}
}

/// languages_read_header(filename)
/// @arg filename
/// @desc Reads the file/language and file/locale entries from a
/// .milanguage header. Returns an array [name, locale], or null when
/// the file cannot be read as a language file.

function languages_read_header(fn)
{
	if (!file_exists_lib(fn))
		return null
	
	var map, header;
	map = json_load(fn)
	if (!ds_map_valid(map))
		return null
	
	header = null
	var filemap, name, locale;
	filemap = map[?"file/"]
	if (ds_map_valid(filemap))
	{
		name = value_get_string(filemap[?"language"], "")
		locale = value_get_string(filemap[?"locale"], "")
		if (name != "")
			header = array(name, locale)
	}
	
	ds_map_destroy(map)
	return header
}

/// languages_locale_chinese(filename)
/// @arg filename
/// @desc Returns whether a language file's locale is Chinese - the one
/// language whose fonts are bundled (Noto Sans SC subsets). Extend the
/// subsets and this check when adding other CJK languages.

function languages_locale_chinese(fn)
{
	var header, locale;
	header = languages_read_header(fn)
	if (header = null)
		return false
	
	locale = string_lower(header[1])
	return (string_copy(locale, 1, 2) = "zh")
}

/// languages_chinese_selected()
/// @desc Returns whether the language saved in the settings (read
/// before the settings themselves load) is Chinese and needs the
/// Chinese font set. Used at startup to pick the interface fonts before
/// any text is drawn.

function languages_chinese_selected()
{
	var fn;
	fn = language_file
	
	if (file_exists_lib(settings_file))
	{
		var map, interfacemap, savedfn;
		map = json_load(settings_file)
		if (ds_map_valid(map))
		{
			interfacemap = map[?"interface"]
			if (ds_map_valid(interfacemap))
			{
				savedfn = value_get_string(interfacemap[?"language_filename"], "")
				if (savedfn != "" && file_exists_lib(savedfn))
					fn = savedfn
			}
			ds_map_destroy(map)
		}
	}
	
	log("Language fonts check", fn, languages_locale_chinese(fn) ? "Chinese fonts" : "Latin fonts")
	return languages_locale_chinese(fn)
}
