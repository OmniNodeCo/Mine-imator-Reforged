/// action_performance_test()
/// @desc Opens the performance checker and immediately runs the stress test.

function action_performance_test()
{
	popup_show(popup_performance)
	performance_test_start(true)
}
