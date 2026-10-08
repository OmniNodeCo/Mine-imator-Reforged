/// popup_worldgenerator_show()
/// @desc Opens the world generator popup, rolling a fresh seed when the
/// seed field is still empty.

function popup_worldgenerator_show()
{
	if (popup_worldgenerator.tbx_seed.text = "" || popup_worldgenerator.tbx_seed.text = "0")
		popup_worldgenerator.tbx_seed.text = string(irandom_range(1, 999999))
	popup_show(popup_worldgenerator)
}
