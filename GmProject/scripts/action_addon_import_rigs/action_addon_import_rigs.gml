/// action_addon_import_rigs()
/// @desc Imports every rig of the addon selected in the Addons browser into
/// the current project.

function action_addon_import_rigs()
{
	if (!ds_map_valid(popup_addons.selected))
		return 0

	var rigs, count;
	rigs = popup_addons.selected[?"rigs"]
	count = 0

	if (ds_list_valid(rigs))
	{
		for (var i = 0; i < ds_list_size(rigs); i++)
		{
			if (!file_exists_lib(rigs[|i]))
				continue

			asset_load(rigs[|i])
			count++
		}
	}

	if (count > 0)
	{
		popup_close()
		toast_new(e_toast.POSITIVE, text_get("addonimported", count))
	}
	else
		toast_new(e_toast.NEGATIVE, text_get("addonimportnone"))

	return count
}
