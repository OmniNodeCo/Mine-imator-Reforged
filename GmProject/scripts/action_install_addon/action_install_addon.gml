/// action_install_addon()
/// @desc "Install addon..." (File menu and the Addons browser): pick an
/// addon file (.miaddon / .zip), install it and refresh the lists.

function action_install_addon()
{
	var path, name;
	path = file_dialog_open(text_get("addoninstallfilter"), "", working_directory, text_get("addoninstallcaption"))
	if (path = "")
		return 0

	name = addon_install(path)

	if (name = "")
	{
		log("Addons: not an addon", path)
		toast_new(e_toast.NEGATIVE, text_get("addoninvalid"))
		return 0
	}

	toast_new(e_toast.POSITIVE, text_get("addoninstalled", name))
	return 1
}
