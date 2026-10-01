/// shader_packs_load([reload])
/// @arg [reload]
/// @desc Loads the installed shader packs from the Shaders directory into
/// shader_pack_list, and builds the shader value name -> e_value lookup
/// used by packs and the apply function. Pass true to refresh an already
/// loaded list (after installing a new pack).

function shader_packs_load()
{
	globalvar shader_pack_list, shader_value_map, shader_value_list;
	
	var reload;
	reload = (argument_count > 0 && argument[0])
	
	// Name -> camera value lookup (the values a shader pack may set)
	shader_value_map = ds_map_create()
	ds_map_add(shader_value_map, "light_management", e_value.CAM_LIGHT_MANAGEMENT)
	ds_map_add(shader_value_map, "tonemapper", e_value.CAM_TONEMAPPER)
	ds_map_add(shader_value_map, "exposure", e_value.CAM_EXPOSURE)
	ds_map_add(shader_value_map, "gamma", e_value.CAM_GAMMA)
	ds_map_add(shader_value_map, "dof", e_value.CAM_DOF)
	ds_map_add(shader_value_map, "dof_depth", e_value.CAM_DOF_DEPTH)
	ds_map_add(shader_value_map, "dof_range", e_value.CAM_DOF_RANGE)
	ds_map_add(shader_value_map, "dof_fade_size", e_value.CAM_DOF_FADE_SIZE)
	ds_map_add(shader_value_map, "dof_blur_size", e_value.CAM_DOF_BLUR_SIZE)
	ds_map_add(shader_value_map, "dof_blur_ratio", e_value.CAM_DOF_BLUR_RATIO)
	ds_map_add(shader_value_map, "dof_bias", e_value.CAM_DOF_BIAS)
	ds_map_add(shader_value_map, "dof_threshold", e_value.CAM_DOF_THRESHOLD)
	ds_map_add(shader_value_map, "dof_gain", e_value.CAM_DOF_GAIN)
	ds_map_add(shader_value_map, "dof_fringe", e_value.CAM_DOF_FRINGE)
	ds_map_add(shader_value_map, "dof_fringe_angle_red", e_value.CAM_DOF_FRINGE_ANGLE_RED)
	ds_map_add(shader_value_map, "dof_fringe_angle_green", e_value.CAM_DOF_FRINGE_ANGLE_GREEN)
	ds_map_add(shader_value_map, "dof_fringe_angle_blue", e_value.CAM_DOF_FRINGE_ANGLE_BLUE)
	ds_map_add(shader_value_map, "dof_fringe_red", e_value.CAM_DOF_FRINGE_RED)
	ds_map_add(shader_value_map, "dof_fringe_green", e_value.CAM_DOF_FRINGE_GREEN)
	ds_map_add(shader_value_map, "dof_fringe_blue", e_value.CAM_DOF_FRINGE_BLUE)
	ds_map_add(shader_value_map, "bloom", e_value.CAM_BLOOM)
	ds_map_add(shader_value_map, "bloom_threshold", e_value.CAM_BLOOM_THRESHOLD)
	ds_map_add(shader_value_map, "bloom_intensity", e_value.CAM_BLOOM_INTENSITY)
	ds_map_add(shader_value_map, "bloom_radius", e_value.CAM_BLOOM_RADIUS)
	ds_map_add(shader_value_map, "bloom_ratio", e_value.CAM_BLOOM_RATIO)
	ds_map_add(shader_value_map, "bloom_blend", e_value.CAM_BLOOM_BLEND)
	ds_map_add(shader_value_map, "lens_dirt", e_value.CAM_LENS_DIRT)
	ds_map_add(shader_value_map, "lens_dirt_bloom", e_value.CAM_LENS_DIRT_BLOOM)
	ds_map_add(shader_value_map, "lens_dirt_glow", e_value.CAM_LENS_DIRT_GLOW)
	ds_map_add(shader_value_map, "lens_dirt_radius", e_value.CAM_LENS_DIRT_RADIUS)
	ds_map_add(shader_value_map, "lens_dirt_intensity", e_value.CAM_LENS_DIRT_INTENSITY)
	ds_map_add(shader_value_map, "lens_dirt_power", e_value.CAM_LENS_DIRT_POWER)
	ds_map_add(shader_value_map, "color_correction", e_value.CAM_COLOR_CORRECTION)
	ds_map_add(shader_value_map, "contrast", e_value.CAM_CONTRAST)
	ds_map_add(shader_value_map, "brightness", e_value.CAM_BRIGHTNESS)
	ds_map_add(shader_value_map, "saturation", e_value.CAM_SATURATION)
	ds_map_add(shader_value_map, "vibrance", e_value.CAM_VIBRANCE)
	ds_map_add(shader_value_map, "color_burn", e_value.CAM_COLOR_BURN)
	ds_map_add(shader_value_map, "grain", e_value.CAM_GRAIN)
	ds_map_add(shader_value_map, "grain_strength", e_value.CAM_GRAIN_STRENGTH)
	ds_map_add(shader_value_map, "grain_saturation", e_value.CAM_GRAIN_SATURATION)
	ds_map_add(shader_value_map, "grain_size", e_value.CAM_GRAIN_SIZE)
	ds_map_add(shader_value_map, "vignette", e_value.CAM_VIGNETTE)
	ds_map_add(shader_value_map, "vignette_radius", e_value.CAM_VIGNETTE_RADIUS)
	ds_map_add(shader_value_map, "vignette_softness", e_value.CAM_VIGNETTE_SOFTNESS)
	ds_map_add(shader_value_map, "vignette_strength", e_value.CAM_VIGNETTE_STRENGTH)
	ds_map_add(shader_value_map, "vignette_color", e_value.CAM_VIGNETTE_COLOR)
	ds_map_add(shader_value_map, "ca", e_value.CAM_CA)
	ds_map_add(shader_value_map, "ca_blur_amount", e_value.CAM_CA_BLUR_AMOUNT)
	ds_map_add(shader_value_map, "ca_red_offset", e_value.CAM_CA_RED_OFFSET)
	ds_map_add(shader_value_map, "ca_green_offset", e_value.CAM_CA_GREEN_OFFSET)
	ds_map_add(shader_value_map, "ca_blue_offset", e_value.CAM_CA_BLUE_OFFSET)
	ds_map_add(shader_value_map, "distort", e_value.CAM_DISTORT)
	ds_map_add(shader_value_map, "distort_repeat", e_value.CAM_DISTORT_REPEAT)
	ds_map_add(shader_value_map, "distort_zoom_amount", e_value.CAM_DISTORT_ZOOM_AMOUNT)
	ds_map_add(shader_value_map, "distort_amount", e_value.CAM_DISTORT_AMOUNT)
	
	// All shader-scope values, for resetting before a pack is applied
	shader_value_list = ds_list_create()
	var key;
	key = ds_map_find_first(shader_value_map)
	repeat (ds_map_size(shader_value_map))
	{
		ds_list_add(shader_value_list, shader_value_map[?key])
		key = ds_map_find_next(shader_value_map, key)
	}
	
	// Free the previous pack list on refresh
	if (reload && ds_list_valid(shader_pack_list))
	{
		while (ds_list_size(shader_pack_list) > 0)
		{
			ds_map_destroy(shader_pack_list[|0])
			ds_list_delete(shader_pack_list, 0)
		}
		ds_list_destroy(shader_pack_list)
	}
	
	shader_pack_list = ds_list_create()
	
	if (!directory_exists_lib(shaders_directory))
	{
		directory_create_lib(shaders_directory)
		return 0
	}
	
	var files;
	files = file_find(shaders_directory, ".mishader,.json")
	for (var i = 0; i < array_length(files); i++)
	{
		var pack, spec, name;
		spec = json_load(files[i])
		if (!ds_map_valid(spec) || !ds_map_valid(spec[?"values"]))
		{
			log("Shaders: invalid shader pack (no values map)", files[i])
			continue
		}
		
		name = filename_new_ext(filename_name(files[i]), "")
		if (!is_undefined(spec[?"name"]))
			name = spec[?"name"]
		
		var author, description;
		author = spec[?"author"]
		if (is_undefined(author))
			author = ""
		description = spec[?"description"]
		if (is_undefined(description))
			description = ""
		
		pack = ds_map_create()
		pack[?"name"] = name
		pack[?"author"] = author
		pack[?"description"] = description
		pack[?"file"] = files[i]
		pack[?"values"] = spec[?"values"]
		
		// Packs still being tested (e.g. imported Minecraft shaderpack
		// approximations) carry a beta badge in the camera shader menu
		if (!is_undefined(spec[?"beta"]) && spec[?"beta"])
			pack[?"beta"] = true
		
		ds_list_add(shader_pack_list, pack)
	}
	
	log("Shaders: loaded", ds_list_size(shader_pack_list), "shader packs")
	return ds_list_size(shader_pack_list)
}
