/// action_tl_video_file_open()
/// @desc Opens a file dialog and attaches the chosen video to the selected model timelines.

function action_tl_video_file_open()
{
	var fn;
	fn = file_dialog_open("Video files (*.mp4; *.mov; *.avi; *.mkv; *.webm)|*.mp4;*.mov;*.avi;*.mkv;*.webm", "", "", text_get("filedialogopenvideo"))
	
	if (fn = "")
		return 0
	
	action_tl_video_file(fn)
	return 1
}
