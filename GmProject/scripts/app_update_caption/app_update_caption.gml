/// app_update_caption()

function app_update_caption()
{
	if (project_name != "")
		window_set_caption(project_name + string_repeat(" * ", project_changed) + " - " + mineimator_title_short)
	else
		window_set_caption(mineimator_title_short)
}
