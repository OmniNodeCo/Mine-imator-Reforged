/// tl_video_update()
/// @desc Runs in timeline scope (MODEL type). Keeps the model's screen part in sync with the attached video file at the current animation time. Restores the original screen texture when no video is attached.

function tl_video_update()
{
	if (temp.model = null || !instance_exists(temp.model))
		return 0
	
	if (temp.model.model_texture_map = null || is_undefined(temp.model.model_texture_map[?"screen.png"]))
		return 0 // Model has no screen part
	
	// Find the screen part (a bodypart child whose part is textured screen.png)
	var screen_tl;
	screen_tl = null
	for (var i = 0; i < ds_list_size(part_list); i++)
	{
		var child;
		child = part_list[|i]
		if (child.model_part != null && child.model_part.texture_name = "screen.png")
		{
			screen_tl = child
			break
		}
	}
	
	if (screen_tl = null)
		return 0
	
	// No video attached (anymore): put the model's own screen texture back
	if (video_file = "" || video_fail)
	{
		tl_video_screen_restore(screen_tl)
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
			tl_video_screen_restore(screen_tl)
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
	
	// Show the video on the screen part. The part's shape textures are cached
	// on its bodypart timeline (render_update_tl_resource only re-runs when
	// the texture object changes), so the cache is refreshed here every frame.
	var vtex;
	vtex = video_texture(video_slot)
	if (vtex = -1)
		return 0
	
	video_last_tex = vtex
	with (screen_tl)
	{
		for (var s = 0; s < ds_list_size(model_part.shape_list); s++)
			model_part_shape_tex[s] = vtex
	}
}

/// tl_video_screen_restore(screen_tl)
/// @arg screen_tl
/// @desc Runs in timeline scope. Rebuilds the screen part's shape textures from the model's own textures after they were replaced with video frames.

function tl_video_screen_restore(screen_tl)
{
	if (video_last_tex = -1)
		return 0
	
	// Rebuild the part's cached shape textures from the model's texture map
	with (screen_tl)
		render_update_tl_resource()
	
	video_last_tex = -1
}
