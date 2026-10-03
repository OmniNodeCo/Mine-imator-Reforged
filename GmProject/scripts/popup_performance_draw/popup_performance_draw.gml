/// popup_performance_draw()
/// @desc The performance checker: live FPS and frame-time stats, a frame
/// time graph of the last two seconds, and a stress test that measures the
/// PC under load and automatically applies normal or low-end mode.

function popup_performance_draw()
{
	// ---- Live stats: FPS, average frame time, worst frame ----
	tab_control(58)
	
	var colw;
	colw = dw / 3
	
	performance_stat("performancefps", string(floor(perf_fps)), c_text_main, dx, dy, colw)
	performance_stat("performanceframetime", string_format(perf_ms, 1, 1) + " ms", perf_ms <= 16.7 ? c_success : (perf_ms <= 25 ? c_warning : c_error), dx + colw, dy, colw)
	performance_stat("performanceworst", string_format(perf_ms_worst, 1, 1) + " ms", perf_ms_worst <= 25 ? c_text_main : c_warning, dx + colw * 2, dy, colw)
	tab_next()
	
	// ---- Active mode ----
	tab_control(24)
	if (performance_low_end())
		draw_label(text_get("performancemodelowactive"), dx, dy + 12, fa_left, fa_middle, c_warning, 1, font_label, 14, dw)
	else
		draw_label(text_get("performancemodenormalactive"), dx, dy + 12, fa_left, fa_middle, c_success, 1, font_label, 14, dw)
	tab_next()
	
	// ---- Frame time graph (last two seconds) ----
	tab_control(104)
	draw_label(text_get("performancegraph"), dx, dy - 3, fa_left, fa_top, c_text_secondary, 1, font_label)
	
	var gx, gy, gw, gh, budgety;
	gx = dx
	gy = dy + 4
	gw = dw
	gh = 88
	budgety = gy + gh - (16.7 / 40) * gh
	
	draw_box(gx, gy, gw, gh, false, c_level_bottom, 1)
	
	// One bar per recorded frame; height is the frame time (capped at 40 ms)
	var barw, pitch, j, msj, barh, barcol;
	barw = 2
	pitch = (gw - 4) / perf_frame_max
	
	for (j = 0; j < perf_frame_max; j++)
	{
		msj = perf_frame_times[(perf_frame_index + j) mod perf_frame_max]
		barh = min(msj, 40) / 40 * (gh - 6)
		if (msj <= 16.7)
			barcol = c_success
		else if (msj <= 25)
			barcol = c_warning
		else
			barcol = c_error
		
		if (barh >= 1)
			draw_box(gx + 2 + j * pitch, gy + gh - 3 - barh, barw, barh, false, barcol, .75)
	}
	
	// 60 FPS budget line
	draw_box(gx, budgety, gw, 1, false, c_text_tertiary, .5)
	draw_label(text_get("performancebudget"), gx + gw, budgety - 2, fa_right, fa_bottom, c_text_tertiary, a_text_tertiary, font_caption)
	tab_next()
	
	// ---- Test area: instructions, live stress test, or the result ----
	tab_control(96)
	draw_box(dx, dy + 4, dw, 88, false, c_level_bottom, 1)
	
	if (perf_test_state = 1)
	{
		// Stress load renders right here while measuring
		perf_stress_draw(dx + 1, dy + 5, dw - 2, 86)
		
		// Progress label on a small backdrop so it stays readable
		var prog, str, lw;
		prog = perf_test_measured / perf_test_duration
		str = text_get("performancetesting", string(floor(prog * 100)))
		draw_set_font(font_label)
		lw = string_width(str) + 16
		draw_box(dx + dw / 2 - lw / 2, dy + 40, lw, 22, false, c_black, .65)
		draw_label(str, dx + dw / 2, dy + 51, fa_center, fa_middle, c_text_main, 1, font_label)
	}
	else if (perf_test_verdict >= 0)
	{
		// Last test result
		var verdcol, verdkey;
		if (perf_test_verdict = 1)
		{
			verdcol = c_warning
			verdkey = "performanceresultlow"
		}
		else
		{
			verdcol = c_success
			verdkey = "performanceresultnormal"
		}
		
		draw_label(string(floor(perf_test_score)) + " FPS", dx + 16, dy + 26, fa_left, fa_middle, verdcol, 1, font_heading)
		draw_label(text_get(verdkey), dx + 16, dy + 52, fa_left, fa_middle, c_text_main, 1, font_label, 14, dw - 32)
		draw_label(text_get("performanceapplied"), dx + 16, dy + 76, fa_left, fa_middle, c_text_tertiary, a_text_tertiary, font_caption, 12, dw - 32)
	}
	else
		draw_label(text_get("performanceidle"), dx + dw / 2, dy + 48, fa_center, fa_middle, c_text_tertiary, a_text_tertiary, font_label, 14, dw - 24)
	tab_next()
	
	// ---- Run test ----
	tab_control_button_label()
	if (perf_test_state = 1)
		draw_button_label("performancerunning", dx + dw, dy, null, icons.ROCKETSHIP, e_button.PRIMARY, null, e_anchor.RIGHT, true)
	else if (draw_button_label("performancerun", dx + dw, dy, null, icons.ROCKETSHIP, e_button.PRIMARY, null, e_anchor.RIGHT))
		performance_test_start(true)
	tab_next()
}

/// performance_stat(caption, value, color, x, y, width)
/// @arg caption
/// @arg value
/// @arg color
/// @arg x
/// @arg y
/// @arg width
/// @desc One live stat: the value on top, its caption underneath.

function performance_stat(caption, value, color, xx, yy, ww)
{
	draw_label(value, xx, yy + 16, fa_left, fa_middle, color, 1, font_heading)
	draw_label(text_get(caption), xx, yy + 40, fa_left, fa_middle, c_text_tertiary, a_text_tertiary, font_caption)
}
