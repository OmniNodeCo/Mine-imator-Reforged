/// popup_contentcenter_show([menu])
/// @arg [menu]
/// @desc Opens the content center (rigs, shader packs, addons, particles)
/// on the given menu (0 rigs, 1 shaders, 2 addons, 3 particles; the last
/// used menu is kept when no argument is given).

function popup_contentcenter_show(newmenu = -1)
{
	if (!directory_exists_lib(rigs_directory))
		directory_create_lib(rigs_directory)
	
	with (popup_contentcenter)
	{
		if (newmenu >= 0 && newmenu < 4)
			menu = newmenu
		
		tbx_search.text = ""
		filtered = []
		scroll = 0
		selected = undefined
	}
	
	// Fetch the current menu's catalog on first open (http_content_* live
	// on the app object, the HTTP handler runs in app scope - keep the
	// request out of the with-block so it is not stored on the popup)
	contentcenter_fetch(popup_contentcenter.menu)
	
	popup_show(popup_contentcenter)
}

/// contentcenter_fetch(menu, [force])
/// @arg menu
/// @arg [force]
/// @desc Starts loading the catalog of the given content menu. Skipped when
/// the catalog is already loaded, unless force is true (refresh).

function contentcenter_fetch(menu, force = false)
{
	if (http_content_index != null) // One catalog request at a time
		return 0
	
	if (!force && !is_undefined(popup_contentcenter.lists[menu]))
		return 0
	
	popup_contentcenter.loading[menu] = true
	popup_contentcenter.fail[menu] = ""
	popup_contentcenter.fetch_menu = menu
	http_content_index = http_get(link_content + contentcenter_catalog_file(menu))
	return 1
}

/// contentcenter_catalog_file(menu)
/// @arg menu
/// @desc Catalog file name of each content menu. All catalogs live flat on
/// the content server (a GitHub release in production, Tools/content-server
/// during development).

function contentcenter_catalog_file(menu)
{
	switch (menu)
	{
		case 0:
			return "index.json"
		case 1:
			return "shaders.json"
		case 2:
			return "addons.json"
		case 3:
			return "particles.json"
	}
	
	return "index.json"
}
