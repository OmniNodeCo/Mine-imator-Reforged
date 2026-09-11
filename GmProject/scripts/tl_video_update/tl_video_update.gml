/// tl_video_update()
/// @desc Runs in timeline scope. Keeps the model's screen part in sync with the attached video file at the current animation time. Restores the original screen texture when no video is attached.

function tl_video_update()
{
	if (temp.model = null || !instance_exists(temp.model))
		return 0
	
	if (temp.model.model_block_map = null || is_undefined(temp.model.model_block_map[?"screen.png"]))
		return 0 // Model has no screen part
	
	if (temp.model.model_texture_map = null)
		return 0
	
	// No video attached (anymore): put the model's own screen texture back
	if (video_file = "" || video_fail)
	{
		tl_video_screen_restore()
		return 0
	}
	
	// Allocate a video player on first use
	if (video_slot < 0)
	{
		video_slot = video_slot_alloc()
		if (video_slot < 0) // All players are in use
			return 0
	}
	
	// (Re)open the video when the attached file changed
	if (video_loaded_file != video_file)
	{
		video_close(video_slot)
		video_fail = false
		
		if (video_open(video_file, video_slot))
			video_loaded_file = video_file
		else
		{
			video_fail = true
			tl_video_screen_restore()
			return 0
		}
	}
	
	if (video_loaded_file = "")
		return 0
	
	// Position at the current animation time (scrubbing, playback and exports)
	video_display(app.timeline_marker / max(1, app.project_tempo), video_slot)
	video_volume(video_vol, video_slot)
	
	// Audio follows the editor playback (rendered exports are silent)
	video_audio_update(app.timeline_playing, video_slot)
	
	// Remember the model's own screen texture, then show the video on it
	if (video_orig_tex = -1)
		video_orig_tex = temp.model.model_texture_map[?"screen.png"]
	
	video_last_tex = video_texture(video_slot)
	temp.model.model_texture_map[?"screen.png"] = video_last_tex
}

/// tl_video_screen_restore()
/// @desc Runs in timeline scope. Restores the model's own screen texture if this timeline replaced it with a video frame.

function tl_video_screen_restore()
{
	if (temp.model = null || !instance_exists(temp.model) || temp.model.model_texture_map = null)
		return 0
	
	if (video_last_tex != -1 && temp.model.model_texture_map[?"screen.png"] = video_last_tex)
	{
		if (video_orig_tex != -1)
			temp.model.model_texture_map[?"screen.png"] = video_orig_tex
		video_last_tex = -1
	}
	else if (video_last_tex = -1)
		video_orig_tex = temp.model.model_texture_map[?"screen.png"]
}
