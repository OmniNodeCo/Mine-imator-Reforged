/// question(text)
/// @arg text

function question(text)
{
	var answer;
	
	window_set_caption(mineimator_title_short)
	answer = show_question(text)
	window_set_caption("")
	
	return answer;
}
