/// action_setting_language_load(fn)
/// @arg fn

function action_setting_language_load(fn)
{
	if (!file_exists_lib(fn))
		return 0
	
	setting_language_filename = fn
	
	// Switching between the Latin and Chinese font sets needs a
	// restart: save the choice and tell the user, instead of swapping
	// the text into fonts that cannot display it
	if (languages_locale_chinese(fn) != language_fonts_chinese)
	{
		settings_save()
		show_message(text_get("alertlanguagerestart"))
		return 0
	}
	
	language_load(fn, language_map)
	
	with (obj_template)
		temp_update_display_name()
	
	with (obj_timeline)
		tl_update_type_name()
	
	with (obj_popup)
		caption = text_get(name + "caption")
	
	settings_save()
}
