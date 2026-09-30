/// popup_addons_show()
/// @desc Opens the Addons browser.

function popup_addons_show()
{
	with (popup_addons)
	{
		scroll = 0
		selected = undefined
	}

	popup_show(popup_addons)
}
