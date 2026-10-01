/// shader_pack_import_zip(zippath)
/// @arg zippath
/// @desc Imports a Minecraft shaderpack zip (Iris/OptiFine format: a
/// shaders folder with GLSL programs). Mine-imator cannot run the pack's
/// GLSL, so this reads the pack and writes a .mishader preset that
/// approximates its look with the camera's own effects (bloom, tonemapping,
/// color grading...). Returns the preset's display name, "" on failure.

function shader_pack_import_zip(path)
{
	var zipname, slug, target;
	zipname = filename_new_ext(filename_name(path), "")
	
	// Extract the pack
	var dir, shadersdir, files;
	dir = unzip_directory + "shaderpack/"
	unzip(path, dir)
	
	// Find the shaders folder: at the root (the standard layout) or inside
	// a folder named like the zip (repackaged packs)
	if (directory_exists_lib(dir + "shaders"))
		shadersdir = dir + "shaders/"
	else if (directory_exists_lib(dir + zipname + "/shaders"))
		shadersdir = dir + zipname + "/shaders/"
	
	if (shadersdir = "")
		return ""
	
	// It must actually contain shader programs
	files = file_find(shadersdir, ".fsh;.vsh;.glsl;.properties")
	if (array_length(files) = 0)
		return ""
	
	// Build the preset: the pack's family decides the look
	var family, values, name;
	family = shader_pack_family(path)
	values = shader_pack_family_values(family)
	name = shader_pack_pretty(zipname)
	
	target = shaders_directory + shader_pack_slug(name) + ".mishader"
	
	json_save_start(target)
	json_save_object_start()
	json_save_var("format", 1)
	json_save_var("name", name)
	json_save_var("author", text_get("shaderpackauthor"))
	json_save_var("description", text_get("shaderpackdesc", name))
	json_save_var_bool("beta", true)
	json_save_object_start("values")
	
	var key;
	key = ds_map_find_first(values)
	repeat (ds_map_size(values))
	{
		var val;
		val = values[?key]
		
		if (is_bool(val))
			json_save_var_bool(key, val)
		else
			json_save_var(key, val)
		
		key = ds_map_find_next(values, key)
	}
	
	json_save_object_done()
	json_save_object_done()
	json_save_done()
	
	log("Shaders: imported Minecraft shaderpack", name, "as", target)
	return name
}

/// shader_pack_family(zippath)
/// @arg zippath
/// @desc Which well-known shaderpack family the zip looks like (decides the
/// generated preset's look). "iris" is the generic Minecraft shader look.

function shader_pack_family(path)
{
	var fn;
	fn = string_lower(filename_name(path))
	
	if (string_contains(fn, "complementary"))
		return "complementary"
	if (string_contains(fn, "bsl"))
		return "bsl"
	if (string_contains(fn, "seus"))
		return "seus"
	if (string_contains(fn, "sildur"))
		return "sildur"
	if (string_contains(fn, "chocapic"))
		return "chocapic"
	if (string_contains(fn, "photon"))
		return "photon"
	if (string_contains(fn, "soft"))
		return "soft"
	if (string_contains(fn, "voxel"))
		return "voxel"
	if (string_contains(fn, "nostalgia"))
		return "nostalgia"
	
	return "iris"
}

/// shader_pack_family_values(family)
/// @arg family
/// @desc Camera effect values approximating the family's signature look.

function shader_pack_family_values(family)
{
	var values;
	values = ds_map_create()
	
	switch (family)
	{
		// Soft, warm and cinematic
		case "bsl":
			ds_map_add(values, "tonemapper", 2)
			ds_map_add(values, "exposure", 1.05)
			ds_map_add(values, "bloom", true)
			ds_map_add(values, "bloom_threshold", 0.8)
			ds_map_add(values, "bloom_intensity", 0.5)
			ds_map_add(values, "bloom_radius", 1.3)
			ds_map_add(values, "color_correction", true)
			ds_map_add(values, "saturation", 1.08)
			ds_map_add(values, "ca", true)
			break
		
		// Clean, vibrant and bright
		case "complementary":
			ds_map_add(values, "tonemapper", 2)
			ds_map_add(values, "exposure", 1.1)
			ds_map_add(values, "bloom", true)
			ds_map_add(values, "bloom_threshold", 0.82)
			ds_map_add(values, "bloom_intensity", 0.45)
			ds_map_add(values, "bloom_radius", 1.0)
			ds_map_add(values, "color_correction", true)
			ds_map_add(values, "saturation", 1.05)
			ds_map_add(values, "vibrance", 0.25)
			break
		
		// Stylized contrast with vignette
		case "seus":
			ds_map_add(values, "tonemapper", 1)
			ds_map_add(values, "color_correction", true)
			ds_map_add(values, "contrast", 0.08)
			ds_map_add(values, "saturation", 1.05)
			ds_map_add(values, "bloom", true)
			ds_map_add(values, "bloom_threshold", 0.75)
			ds_map_add(values, "bloom_intensity", 0.6)
			ds_map_add(values, "bloom_radius", 1.1)
			ds_map_add(values, "vignette", true)
			ds_map_add(values, "vignette_strength", 1.0)
			break
		
		// Loud colors and heavy glow
		case "sildur":
			ds_map_add(values, "tonemapper", 2)
			ds_map_add(values, "color_correction", true)
			ds_map_add(values, "saturation", 1.25)
			ds_map_add(values, "vibrance", 0.3)
			ds_map_add(values, "bloom", true)
			ds_map_add(values, "bloom_threshold", 0.7)
			ds_map_add(values, "bloom_intensity", 0.8)
			ds_map_add(values, "bloom_radius", 1.6)
			ds_map_add(values, "ca", true)
			break
		
		// Moody, depth-heavy
		case "chocapic":
			ds_map_add(values, "tonemapper", 1)
			ds_map_add(values, "exposure", 0.95)
			ds_map_add(values, "dof", true)
			ds_map_add(values, "dof_blur_size", 0.012)
			ds_map_add(values, "bloom", true)
			ds_map_add(values, "bloom_threshold", 0.8)
			ds_map_add(values, "bloom_intensity", 0.4)
			ds_map_add(values, "color_correction", true)
			ds_map_add(values, "saturation", 0.95)
			ds_map_add(values, "vignette", true)
			ds_map_add(values, "vignette_strength", 1.1)
			break
		
		// Crisp and modern
		case "photon":
			ds_map_add(values, "tonemapper", 2)
			ds_map_add(values, "exposure", 1.1)
			ds_map_add(values, "bloom", true)
			ds_map_add(values, "bloom_threshold", 0.85)
			ds_map_add(values, "bloom_intensity", 0.35)
			ds_map_add(values, "bloom_radius", 0.9)
			ds_map_add(values, "color_correction", true)
			ds_map_add(values, "vibrance", 0.2)
			break
		
		// Ray-traced look: rich color and strong glow
		case "voxel":
			ds_map_add(values, "tonemapper", 2)
			ds_map_add(values, "exposure", 1.05)
			ds_map_add(values, "bloom", true)
			ds_map_add(values, "bloom_threshold", 0.78)
			ds_map_add(values, "bloom_intensity", 0.55)
			ds_map_add(values, "bloom_radius", 1.2)
			ds_map_add(values, "color_correction", true)
			ds_map_add(values, "saturation", 1.12)
			ds_map_add(values, "vibrance", 0.25)
			break
		
		// Old-school Minecraft shaders: washed warm film
		case "nostalgia":
			ds_map_add(values, "tonemapper", 1)
			ds_map_add(values, "color_correction", true)
			ds_map_add(values, "color_burn", "#FFE7C4")
			ds_map_add(values, "saturation", 0.85)
			ds_map_add(values, "contrast", -0.03)
			ds_map_add(values, "bloom", true)
			ds_map_add(values, "bloom_threshold", 0.72)
			ds_map_add(values, "bloom_intensity", 0.45)
			ds_map_add(values, "vignette", true)
			break
		
		// Soft pastel glow
		case "soft":
			ds_map_add(values, "tonemapper", 2)
			ds_map_add(values, "bloom", true)
			ds_map_add(values, "bloom_threshold", 0.7)
			ds_map_add(values, "bloom_intensity", 0.45)
			ds_map_add(values, "bloom_radius", 1.4)
			ds_map_add(values, "color_correction", true)
			ds_map_add(values, "vibrance", 0.15)
			ds_map_add(values, "vignette", true)
			ds_map_add(values, "vignette_strength", 0.8)
			break
		
		// Generic Minecraft shader look
		default:
			ds_map_add(values, "tonemapper", 2)
			ds_map_add(values, "exposure", 1.05)
			ds_map_add(values, "bloom", true)
			ds_map_add(values, "bloom_threshold", 0.8)
			ds_map_add(values, "bloom_intensity", 0.5)
			ds_map_add(values, "bloom_radius", 1.3)
			ds_map_add(values, "color_correction", true)
			ds_map_add(values, "saturation", 1.05)
			ds_map_add(values, "ca", true)
			break
	}
	
	return values
}

/// shader_pack_pretty(zipname)
/// @arg zipname
/// @desc Turns a shaderpack zip name into a display name (BSL_v8.2 -> BSL v8.2).

function shader_pack_pretty(zipname)
{
	var name;
	name = string_replace_all(zipname, "_", " ")
	name = string_replace_all(name, ".zip", "")
	return name
}

/// shader_pack_slug(name)
/// @arg name
/// @desc Turns a display name into a file name (BSL v8.2 -> bsl-v8.2).

function shader_pack_slug(name)
{
	var slug, chars;
	slug = ""
	chars = "abcdefghijklmnopqrstuvwxyz0123456789."
	name = string_lower(name)
	
	for (var i = 1; i <= string_length(name); i++)
	{
		var c;
		c = string_char_at(name, i)
		
		if (string_pos(c, chars) > 0)
			slug += c
		else if (string_length(slug) = 0 || string_char_at(slug, string_length(slug)) != "-")
			slug += "-"
	}
	
	// Trim trailing dashes and dots
	while (string_length(slug) > 0 && string_pos(string_char_at(slug, string_length(slug)), "-.") > 0)
		slug = string_copy(slug, 1, string_length(slug) - 1)
	
	return slug
}
