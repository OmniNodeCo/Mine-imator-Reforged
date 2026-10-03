/// performance_test_start(visible)
/// @arg visible
/// @desc Starts the performance stress test. Visible tests render their load
/// inside the performance popup; invisible tests (the automatic first-run
/// detection) render the same load onto an offscreen surface.

function performance_test_start(visible)
{
	perf_test_state = 1
	perf_test_visible = visible
	perf_test_frames = 0
	perf_test_measured = 0
	perf_test_ms = 0
	perf_test_worst = 0
	perf_test_score = 0
	perf_test_verdict = -1
	
	log("Performance: stress test started", visible ? "(visible)" : "(auto-detect)")
}

/// performance_test_finish()
/// @desc Ends the stress test, computes the score (average FPS under the
/// load) and the verdict, applies the detected performance mode and
/// remembers it - so the automatic detection runs only once, and the user
/// can always override it in Settings > Program > Performance.

function performance_test_finish()
{
	perf_test_state = 0
	
	if (perf_test_measured = 0)
		return 0
	
	var avgms;
	avgms = perf_test_ms / perf_test_measured
	perf_test_score = 1000 / max(0.01, avgms)
	perf_test_verdict = (perf_test_score >= perf_score_normal ? 0 : 1) // 0 normal, 1 low-end
	
	// Apply + persist the result (auto mode keeps following the detection;
	// an explicit Normal/Low-end choice always wins)
	perf_autodetect_pending = false
	setting_performance_detected = perf_test_verdict
	setting_performance_score = floor(perf_test_score)
	settings_save()
	
	// The visible test shows its result in the popup; the invisible
	// first-run detection reports with a toast
	if (!perf_test_visible)
		toast_new(e_toast.INFO, text_get(perf_test_verdict = 1 ? "performancedetectlow" : "performancedetectnormal"))
	
	log("Performance: test finished,", string(perf_test_score), "FPS ->", perf_test_verdict = 1 ? "low-end mode" : "normal mode")
	return 1
}
