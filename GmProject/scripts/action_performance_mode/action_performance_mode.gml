/// action_performance_mode(mode)
/// @arg mode
/// @desc Settings radio callback: -1 auto-detect (follow the test result),
/// 0 normal, 1 low-end PC.

function action_performance_mode(mode)
{
	setting_performance_mode = mode
	settings_save()
	
	log("Performance: mode set to", mode = -1 ? "auto" : (mode = 1 ? "low-end" : "normal"))
}
