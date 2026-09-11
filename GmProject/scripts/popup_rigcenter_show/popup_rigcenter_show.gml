/// popup_rigcenter_show()
/// @desc Opens the downloadable rigs center and fetches the rig library index.

function popup_rigcenter_show()
{
	if (!directory_exists_lib(rigs_directory))
		directory_create_lib(rigs_directory)
	
	with (popup_rigcenter)
	{
		tbx_search.text = ""
		filtered = []
		scroll = 0
		downloading = ""
		downloading_path = ""
		downloading_name = ""
		progress = 0
		fail_message = ""
	}
	
	// Fetch the catalog on first open (http_rigs_* live on the app object,
	// the HTTP handler runs in app scope - keep the request out of the
	// with-block above so it is not stored on the popup)
	if (is_undefined(popup_rigcenter.list) && http_rigs_index = null)
	{
		popup_rigcenter.loading = true
		http_rigs_index = http_get(link_rigs + "index.json")
	}
	
	popup_show(popup_rigcenter)
}
