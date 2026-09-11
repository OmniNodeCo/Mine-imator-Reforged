/// bench_click_rigs()
/// @desc "Download rigs" entry in the workbench create panel: opens the rig center.

function bench_click_rigs()
{
	// Close the workbench panel
	bench_show_ani_type = "hide"
	window_focus = ""
	
	// Open the rig center
	popup_rigcenter_show()
}
