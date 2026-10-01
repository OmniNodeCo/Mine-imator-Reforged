/// action_contentcenter_select(menu)
/// @arg menu
/// @desc Content center menu callback: switches to the given content menu
/// (0 rigs, 1 shaders, 2 addons, 3 particles) and loads its catalog.

function action_contentcenter_select(newmenu)
{
	if (newmenu < 0 || newmenu > 3)
		return 0
	
	with (popup_contentcenter)
	{
		if (menu = newmenu)
			return 0
		
		menu = newmenu
		tbx_search.text = ""
		filtered = []
		scroll = 0
		selected = undefined
	}
	
	contentcenter_fetch(newmenu)
	return 1
}
