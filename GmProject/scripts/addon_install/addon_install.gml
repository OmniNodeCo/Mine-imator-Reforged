/// addon_install(path)
/// @arg path
/// @desc Installs an addon from a .miaddon / .zip file: a zip with an
/// addon.json manifest and optional shaders, particles and rigs folders.
/// Shader packs are copied into the Shaders directory (they appear in the
/// camera's shader menu), particle presets into Particles, and rigs are
/// kept in the addon's own folder (import them from the Addons browser).
/// Returns the addon's display name, "" on failure.

function addon_install(path)
{
	if (!file_exists_lib(path))
		return ""

	var zipname, dir, root, num, target, existing;
	zipname = filename_new_ext(filename_name(path), "")

	// Extract the addon
	dir = unzip_directory + "addon/"
	num = unzip(path, dir)
	if (num <= 0)
		return ""

	// The manifest sits at the root (the standard layout) or inside a
	// folder named like the zip (repackaged addons)
	root = ""
	if (file_exists_lib(dir + "addon.json"))
		root = dir
	else if (file_exists_lib(dir + zipname + "/addon.json"))
		root = dir + zipname + "/"

	if (root = "")
		return ""

	// Read and validate the manifest
	var spec, name, author, description, version;
	spec = json_load(root + "addon.json")
	if (!ds_map_valid(spec) || !is_string(spec[?"name"]))
	{
		if (ds_map_valid(spec))
			ds_map_destroy(spec)
		return ""
	}

	name = spec[?"name"]
	author = spec[?"author"]
	if (is_undefined(author))
		author = ""
	description = spec[?"description"]
	if (is_undefined(description))
		description = ""
	version = spec[?"version"]
	if (is_undefined(version))
		version = "1.0"

	var slug;
	slug = shader_pack_slug(name)
	if (slug = "")
		slug = "addon"

	// Collect the content files
	var shader_files, particle_files, rig_files;
	shader_files = file_find(root + "shaders/", ".mishader,.json")
	particle_files = file_find(root + "particles/", ".miparticles")
	rig_files = file_find(root + "rigs/", ".miobject,.mimodel,.miframes,.zip,.json")

	if (array_length(shader_files) = 0 && array_length(particle_files) = 0 && array_length(rig_files) = 0)
	{
		ds_map_destroy(spec)
		return ""
	}

	// Remove a previous install of the same addon
	for (var i = 0; i < ds_list_size(addon_list); i++)
	{
		existing = addon_list[|i]
		if (existing[?"slug"] = slug)
		{
			addon_remove(existing)
			break
		}
	}

	directory_create_lib(addons_directory)

	// Registry entry
	var addon;
	addon = ds_map_create()
	addon[?"name"] = name
	addon[?"author"] = author
	addon[?"description"] = description
	addon[?"version"] = version
	addon[?"slug"] = slug
	addon[?"shaders"] = ds_list_create()
	addon[?"particles"] = ds_list_create()
	addon[?"rigs"] = ds_list_create()

	// Shader packs -> Shaders directory (appear in the camera shader menu)
	for (var i = 0; i < array_length(shader_files); i++)
	{
		target = shaders_directory + filename_name(shader_files[i])
		file_delete_lib(target)
		if (file_copy_lib(shader_files[i], target))
			ds_list_add(addon[?"shaders"], filename_name(shader_files[i]))
	}

	// Particle presets -> Particles directory (appear in the workbench)
	for (var i = 0; i < array_length(particle_files); i++)
	{
		target = particles_directory + filename_name(particle_files[i])
		file_delete_lib(target)
		if (file_copy_lib(particle_files[i], target))
			ds_list_add(addon[?"particles"], filename_name(particle_files[i]))
	}

	// Rigs -> the addon's own folder (import from the Addons browser)
	directory_create_lib(addons_directory + slug + "/rigs/")
	for (var i = 0; i < array_length(rig_files); i++)
	{
		target = addons_directory + slug + "/rigs/" + filename_name(rig_files[i])
		file_delete_lib(target)
		if (file_copy_lib(rig_files[i], target))
			ds_list_add(addon[?"rigs"], target)
	}

	ds_list_add(addon_list, addon)
	addons_save()

	// Refresh the shader pack menu
	shader_packs_load(true)

	ds_map_destroy(spec)

	log("Addons: installed", name, "(", ds_list_size(addon[?"shaders"]), "shaders,",
		ds_list_size(addon[?"particles"]), "particles,", ds_list_size(addon[?"rigs"]), "rigs )")
	return name
}

/// addon_remove(addon)
/// @arg addon
/// @desc Removes an installed addon: deletes the files it installed and its
/// own folder, drops it from the registry and saves.

function addon_remove(addon)
{
	var slug, i, files, target;
	slug = addon[?"slug"]

	// Shader packs
	files = addon[?"shaders"]
	if (ds_list_valid(files))
	{
		for (i = 0; i < ds_list_size(files); i++)
			file_delete_lib(shaders_directory + files[|i])
	}

	// Particle presets
	files = addon[?"particles"]
	if (ds_list_valid(files))
	{
		for (i = 0; i < ds_list_size(files); i++)
			file_delete_lib(particles_directory + files[|i])
	}

	// The addon's own folder (rigs)
	directory_delete_lib(addons_directory + slug)

	// Registry
	var index;
	index = ds_list_find_index(addon_list, addon)
	if (index >= 0)
	{
		ds_list_delete(addon_list, index)
		addons_save()
	}

	ds_map_destroy(addon)
	log("Addons: removed", slug)
}
