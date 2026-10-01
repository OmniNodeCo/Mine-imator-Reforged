/// bench_click_rigs()
/// @desc "Download rigs" entry in the workbench create panel: opens the
/// content center's rigs menu.

function bench_click_rigs()
{
	// Close the workbench panel
	bench_show_ani_type = "hide"
	window_focus = ""
	
	// Open the content center on the rigs menu
	popup_contentcenter_show(0)
}
