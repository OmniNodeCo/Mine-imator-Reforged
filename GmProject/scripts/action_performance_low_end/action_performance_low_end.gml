/// action_performance_low_end(enabled)
/// @arg enabled
/// @desc Settings switch callback (the quick toggle on the Performance
/// section header): turns low-end mode on or off as an explicit choice.

function action_performance_low_end(enabled)
{
	setting_performance_mode = (enabled ? 1 : 0)
	settings_save()
	
	log("Performance: low-end mode", enabled ? "enabled" : "disabled")
}
