/// action_addon_uninstall()
/// @desc Removes the addon selected in the Addons browser: deletes the
/// files it installed and its own folder.

function action_addon_uninstall()
{
	if (!ds_map_valid(popup_addons.selected))
		return 0

	var name;
	name = popup_addons.selected[?"name"]

	addon_remove(popup_addons.selected)
	popup_addons.selected = undefined

	shader_packs_load(true)

	toast_new(e_toast.INFO, text_get("addonuninstalled", name))
	return 1
}
