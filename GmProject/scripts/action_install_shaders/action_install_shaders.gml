/// action_install_shaders()
/// @desc "Install shaders" (File menu and the camera's shader menu): pick a
/// shader pack file (.mishader / .json), validate it, copy it into the
/// Shaders directory and refresh the shader pack list.

function action_install_shaders()
{
	var path;
	path = file_dialog_open(text_get("shaderinstallfilter"), "", working_directory, text_get("shaderinstallcaption"))
	if (path = "")
		return 0
	
	// Validate before installing
	var spec;
	spec = json_load(path)
	if (!ds_map_valid(spec) || !ds_map_valid(spec[?"values"]))
	{
		log("Shaders: not a shader pack", path)
		toast_new(e_toast.NEGATIVE, text_get("shaderinstallinvalid"))
		return 0
	}
	
	// Copy into the Shaders directory (keep the pack's own file name)
	var filename, target;
	filename = filename_name(path)
	if (filename_ext(filename) != ".mishader")
		filename = filename_new_ext(filename, ".mishader")
	target = shaders_directory + filename
	
	file_delete_lib(target)
	if (!file_copy_lib(path, target))
	{
		log("Shaders: could not copy pack to", target)
		toast_new(e_toast.NEGATIVE, text_get("shaderinstallfailed"))
		return 0
	}
	
	shader_packs_load(true)
	
	var name;
	name = (is_undefined(spec[?"name"]) ? filename_new_ext(filename, "") : spec[?"name"])
	toast_new(e_toast.POSITIVE, text_get("shaderinstalled", name))
	log("Shaders: installed", name, "to", target)
	return 1
}
