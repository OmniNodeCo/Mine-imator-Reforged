/// app_startup_performance()
/// @desc Sets up the performance checker: a rolling frame-time monitor that
/// feeds the live stats, the FPS overlay and the stress test used to detect
/// whether the PC should run the full interface or low-end mode.

function app_startup_performance()
{
	globalvar perf_frame_times, perf_frame_index, perf_frame_max, perf_frame_count;
	globalvar perf_ms_sum, perf_ms, perf_ms_worst, perf_fps;
	globalvar perf_test_state, perf_test_visible, perf_test_frames, perf_test_measured;
	globalvar perf_test_ms, perf_test_worst, perf_test_score, perf_test_verdict;
	globalvar perf_test_warmup, perf_test_duration, perf_score_normal;
	globalvar perf_autodetect_pending, perf_test_surface;
	
	// Ring buffer with the frame times (ms) of the last two seconds
	perf_frame_max = 120
	perf_frame_times = array_create(perf_frame_max, 0)
	perf_frame_index = 0
	perf_frame_count = 0
	perf_ms_sum = 0
	perf_ms = 0
	perf_ms_worst = 0
	perf_fps = 0
	
	// Stress test: 0 = idle, 1 = running, 2 = finished
	perf_test_state = 0
	perf_test_visible = false
	perf_test_frames = 0
	perf_test_measured = 0
	perf_test_ms = 0
	perf_test_worst = 0
	perf_test_score = 0
	perf_test_verdict = -1
	
	// Test shape: skip the first frames (warm-up), then measure this many.
	// A PC that keeps ~45 FPS under the load runs the full interface.
	perf_test_warmup = 15
	perf_test_duration = 120
	perf_score_normal = 45
	perf_test_surface = -1
	
	// Set by settings_startup: true when the performance mode was never
	// configured and no test result is saved, so a detection test runs once
	perf_autodetect_pending = false
}
