/// app_startup_fonts()

function app_startup_fonts()
{
	// Chinese swaps the interface fonts for bundled Noto Sans SC subsets
	// that include the translated characters. The check reads the
	// language saved in the settings, because the fonts load before the
	// settings themselves do
	language_fonts_chinese = languages_chinese_selected()
	
	var noto_regular_fn, noto_bold_fn, rubik_medium_fn;
	noto_regular_fn = fonts_directory + "noto_regular.ttf"
	noto_bold_fn = fonts_directory + "noto_bold.ttf"
	rubik_medium_fn = fonts_directory + "rubik_medium.ttf"
	if (language_fonts_chinese)
	{
		noto_regular_fn = fonts_directory + "notosc_regular.otf"
		noto_bold_fn = fonts_directory + "notosc_bold.otf"
		rubik_medium_fn = fonts_directory + "notosc_medium.otf"
	}
	
	font_subheading = font_add(rubik_medium_fn, 8.5, false, false, 32, 1024)
	font_label = font_add(noto_bold_fn, 9, false, false, 32, 1024)
	font_value = font_add(noto_regular_fn, 9, false, false, 32, 1024)
	font_digits = font_add(fonts_directory + "notomono_regular.ttf", 9, false, false, 32, 1024)
	font_caption = font_add(noto_regular_fn, 8, false, false, 32, 1024)
	font_button = font_add(rubik_medium_fn, 9.5, false, false, 32, 1024)
	
	// Special-case fonts
	font_upgrade = font_add(noto_regular_fn, 18, false, false, 32, 1024)
	font_heading = font_add(rubik_medium_fn, 10, false, false, 32, 1024)
	font_body_big = font_add(noto_regular_fn, 12, false, false, 32, 1024)
	font_heading_big = font_add(rubik_medium_fn, 13, false, false, 32, 1024)
}
