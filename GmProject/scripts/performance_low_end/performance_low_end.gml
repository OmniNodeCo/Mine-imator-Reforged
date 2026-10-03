/// performance_low_end()
/// @desc Whether the app currently runs in low-end mode: explicitly chosen
/// in Settings > Program > Performance, or the automatic first-run detection
/// result when the mode is still set to auto.

function performance_low_end()
{
	if (app.setting_performance_mode = 1)
		return true
	if (app.setting_performance_mode = -1 && app.setting_performance_detected = 1)
		return true
	return false
}
