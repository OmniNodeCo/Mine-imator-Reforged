/// action_performance_showfps(enabled)
/// @arg enabled
/// @desc Settings switch callback: shows or hides the FPS overlay in the
/// corner of the main window.

function action_performance_showfps(enabled)
{
	setting_show_fps = enabled
	settings_save()
}
