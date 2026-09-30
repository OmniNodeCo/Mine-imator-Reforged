/// addons_load([reload])
/// @arg [reload]
/// @desc Loads the installed addons from the Addons directory registry into
/// addon_list. Pass true to refresh an already loaded list (after installing
/// or removing an addon).

function addons_load()
{
	globalvar addon_list;

	var reload;
	reload = (argument_count > 0 && argument[0])

	if (reload && ds_list_valid(addon_list))
	{
		while (ds_list_size(addon_list) > 0)
		{
			ds_map_destroy(addon_list[|0])
			ds_list_delete(addon_list, 0)
		}
		ds_list_destroy(addon_list)
	}

	addon_list = ds_list_create()

	if (!directory_exists_lib(addons_directory))
	{
		directory_create_lib(addons_directory)
		return 0
	}

	var spec, list;
	spec = json_load(addons_directory + "addons.json")
	if (!ds_map_valid(spec) || !ds_list_valid(spec[?"addons"]))
		return 0

	list = spec[?"addons"]
	for (var i = 0; i < ds_list_size(list); i++)
	{
		var addon;
		addon = list[|i]
		if (!ds_map_valid(addon) || is_undefined(addon[?"name"]))
			continue

		ds_list_add(addon_list, addon)
	}

	log("Addons: loaded", ds_list_size(addon_list), "addon(s)")
	return ds_list_size(addon_list)
}

/// addons_save()
/// @desc Writes the addon registry (addon_list) back to the Addons directory.

function addons_save()
{
	directory_create_lib(addons_directory)

	json_save_start(addons_directory + "addons.json")
	json_save_object_start()
	json_save_var("format", 1)

	json_save_array_start("addons")

	for (var i = 0; i < ds_list_size(addon_list); i++)
	{
		var addon;
		addon = addon_list[|i]

		json_save_object_start()
		json_save_var("name", addon[?"name"])

		if (!is_undefined(addon[?"author"]))
			json_save_var("author", addon[?"author"])
		if (!is_undefined(addon[?"description"]))
			json_save_var("description", addon[?"description"])
		if (!is_undefined(addon[?"version"]))
			json_save_var("version", addon[?"version"])

		json_save_var("slug", addon[?"slug"])

		// Installed file lists (used by the uninstaller)
		var keys;
		keys = array("shaders", "particles", "rigs")
		for (var k = 0; k < 3; k++)
		{
			var files;
			files = addon[?keys[k]]

			json_save_array_start(keys[k])
			for (var f = 0; f < ds_list_size(files); f++)
				json_save_array_value(files[|f])
			json_save_array_done()
		}

		json_save_object_done()
	}

	json_save_array_done()

	json_save_object_done()
	json_save_done()
}
