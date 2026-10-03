/// perf_update()
/// @desc Per-frame performance sampling (called at the end of the main
/// window's draw): records frame times into a rolling window for the live
/// stats and the frame-time graph, advances the stress test, runs the
/// one-time low-end detection and draws the optional FPS overlay.

function perf_update()
{
	if (window_get_current() != e_window.MAIN)
		return 0
	
	var ms;
	ms = delta_time / 1000
	
	// Rolling window of the last 120 frame times
	perf_ms_sum = perf_ms_sum - perf_frame_times[perf_frame_index] + ms
	perf_frame_times[perf_frame_index] = ms
	perf_frame_index = (perf_frame_index + 1) mod perf_frame_max
	perf_frame_count++
	
	// Live stats (average + worst), refreshed a few times per second
	if (perf_frame_count mod 10 = 0)
	{
		var worst;
		worst = 0
		for (var i = 0; i < perf_frame_max; i++)
		{
			if (perf_frame_times[i] > worst)
				worst = perf_frame_times[i]
		}
		perf_ms_worst = worst
		perf_ms = perf_ms_sum / perf_frame_max
		perf_fps = 1000 / max(0.01, perf_ms)
	}
	
	// First run (no saved performance mode): detect automatically once the
	// interface is up and idle - the test itself is invisible (offscreen)
	if (perf_autodetect_pending && perf_test_state = 0 && perf_frame_count > 30)
	{
		if (window_state != "load_assets" && window_state != "new_assets" && window_state != "export_movie" && window_state != "export_image" && window_state != "world_import")
		{
			perf_autodetect_pending = false
			performance_test_start(false)
		}
	}
	
	// Stress test in progress
	if (perf_test_state = 1)
	{
		// An export took over the app - abandon the test
		if (window_state = "export_movie" || window_state = "export_image")
		{
			perf_test_state = 0
			log("Performance: test cancelled (export started)")
		}
		else
		{
			// The visible test renders its load inside the popup; when the
			// popup is closed mid-test it continues invisibly
			if (perf_test_visible && popup != popup_performance)
				perf_test_visible = false
			
			if (!perf_test_visible)
				perf_stress_draw_offscreen()
			
			perf_test_frames++
			if (perf_test_frames > perf_test_warmup)
			{
				perf_test_ms = perf_test_ms + ms
				if (ms > perf_test_worst)
					perf_test_worst = ms
				perf_test_measured++
			}
			
			if (perf_test_measured >= perf_test_duration)
				performance_test_finish()
		}
	}
	
	// FPS overlay (Settings > Program > Performance)
	if (setting_show_fps && window_state != "export_movie" && window_state != "export_image")
	{
		var str, w;
		str = string(floor(perf_fps)) + " FPS"
		draw_set_font(font_caption)
		w = string_width(str) + 12
		draw_box(window_width - w - 8, 8, w, 20, false, c_black, .5)
		draw_label(str, window_width - 14, 18, fa_right, fa_middle, perf_fps < 45 ? c_error : c_text_main, 1, font_caption)
	}
	
	return 1
}

/// perf_stress_draw(x, y, width, height)
/// @arg x
/// @arg y
/// @arg width
/// @arg height
/// @desc The stress test load: many alpha-blended quads (GPU fill rate,
/// what heavy effects like bloom and depth of field cost) plus rotating
/// sprites (per-quad transform and submission cost). Drawn into the test
/// area of the performance popup, or onto an offscreen surface when the
/// test runs invisibly during auto-detection.

function perf_stress_draw(xx, yy, ww, hh)
{
	var layers, cols, rows;
	layers = 48
	cols = 24
	rows = 12
	
	// Fill rate: blended full-area quads, drifting so nothing can be cached
	for (var l = 0; l < layers; l++)
	{
		var ox, oy;
		ox = ((l * 37 + perf_test_frames * 3) mod (cols * 2)) / (cols * 2) * ww * .25
		oy = ((l * 53 + perf_test_frames * 5) mod (rows * 2)) / (rows * 2) * hh * .25
		draw_box(xx + ox, yy + oy, ww - ox, hh - oy, false, c_white, .25)
	}
	
	// Per-quad cost: small rotating sprites
	var cw, ch;
	cw = ww / cols
	ch = hh / rows
	
	for (var cy = 0; cy < rows; cy++)
	{
		for (var cx = 0; cx < cols; cx++)
		{
			var i, px, py;
			i = cy * cols + cx
			px = xx + (cx + .5) * cw + ((i * 31 + perf_test_frames * 7) mod 17) - 8
			py = yy + (cy + .5) * ch + ((i * 17 + perf_test_frames * 11) mod 13) - 6
			draw_sprite_ext(spr_checkbox, 0, px, py, 2.5, 2.5, (i + perf_test_frames) mod 360, c_white, .8)
		}
	}
}

/// perf_stress_draw_offscreen()
/// @desc Draws the stress test load onto an offscreen surface, so the
/// auto-detection test measures the same load without showing anything.

function perf_stress_draw_offscreen()
{
	perf_test_surface = surface_require(perf_test_surface, 384, 216)
	
	surface_set_target(perf_test_surface)
	{
		draw_clear_alpha(c_black, 0)
		perf_stress_draw(0, 0, 384, 216)
	}
	surface_reset_target()
}
