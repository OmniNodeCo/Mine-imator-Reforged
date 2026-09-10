/// popup_videoplayer_draw()

function popup_videoplayer_draw()
{
	var pos, dur;
	pos = video_position()
	dur = video_duration()
	
	// Controls area height at the bottom
	var controls_h = 44;
	var video_w = content_width;
	var video_h = content_height - controls_h;
	
	// Video area
	draw_box(content_x, content_y, video_w, video_h, false, c_black, 1)
	
	if (video_width() = 0)
	{
		// Nothing loaded yet
		draw_label(text_get("videoplayeropenhint"), content_x + content_width / 2, content_y + video_h / 2 - 24, fa_center, fa_bottom, c_text_secondary, a_text_secondary, font_body_big)
		
		if (draw_button_label("videoplayeropen", content_x + content_width / 2 - 80, content_y + video_h / 2 + 4, 160, icons.CAMERA, e_button.PRIMARY))
			popup_videoplayer_open()
	}
	else
	{
		// Update playback (delta_time is in microseconds)
		video_update(delta_time / 1000000)
		
		// Letterbox the video into the video area
		var vidw, vidh, sca, draww, drawh, drawx, drawy;
		vidw = video_width()
		vidh = video_height()
		sca = min(video_w / vidw, video_h / vidh)
		draww = vidw * sca
		drawh = vidh * sca
		drawx = content_x + (video_w - draww) / 2
		drawy = content_y + (video_h - drawh) / 2
		
		gpu_set_tex_filter(true)
		draw_texture(video_texture(), drawx, drawy, sca, sca)
		gpu_set_tex_filter(false)
		
		// Space toggles playback
		if (keyboard_check_pressed(vk_space))
			video_play(!video_playing())
	}
	
	// Controls
	var cx, cy;
	cx = content_x
	cy = content_y + video_h + 8
	
	// Play / pause
	if (draw_button_icon("videoplayerplay", cx, cy, 24, 24, false, video_playing() ? icons.PAUSE : icons.PLAY, null, video_width() = 0, "videoplayerplay"))
	{
		if (video_width() > 0)
			video_play(!video_playing())
	}
	
	// Time label
	var posmin, possec, durmin, dursec, timetext;
	posmin = floor(pos / 60)
	possec = floor(pos) mod 60
	durmin = floor(dur / 60)
	dursec = floor(dur) mod 60
	timetext = string(posmin) + ":" + (possec < 10 ? "0" : "") + string(possec) + " / " + string(durmin) + ":" + (dursec < 10 ? "0" : "") + string(dursec)
	draw_label(timetext, cx + 34, cy + 12, fa_left, fa_center, c_text_secondary, a_text_secondary, font_label)
	
	// Volume
	if (draw_button_icon("videoplayervoldn", cx + 150, cy, 24, 24, false, null, null, video_has_audio() = 0, "videoplayervolume"))
		video_volume(max(0, video_volume_get() - 0.1))
	
	if (draw_button_icon("videoplayervolup", cx + 176, cy, 24, 24, false, null, null, video_has_audio() = 0, "videoplayervolume"))
		video_volume(min(1, video_volume_get() + 0.1))
	
	// Open / switch file
	if (draw_button_icon("videoplayeropen", content_x + content_width - 24, cy, 24, 24, false, icons.CAMERA, null, false, "videoplayeropen"))
		popup_videoplayer_open()
	
	// Seek bar
	var barx, bary, barw, barh;
	barx = cx + 210
	bary = cy + 8
	barw = content_width - 210 - 36
	barh = 8
	
	if (barw > 20 && video_width() > 0)
	{
		draw_box(barx, bary + 2, barw, 4, false, c_level_bottom, 1)
		draw_box(barx, bary, max(2, barw * (dur > 0 ? pos / dur : 0)), barh, false, c_accent, 1)
		
		// Click / drag to seek
		if (app_mouse_box(barx, bary - 10, barw, barh + 20))
		{
			mouse_cursor = cr_handpoint
			if (mouse_left)
				window_busy = "videoplayerseek"
		}
		
		if (window_busy = "videoplayerseek")
		{
			if (!mouse_left)
			{
				window_busy = ""
				window_focus = ""
				app_mouse_clear()
			}
			else
				video_seek(clamp((mouse_x - barx) / barw, 0, 1) * dur)
		}
	}
	
	// Failure message
	if (popup.fail_message != "")
		draw_label(popup.fail_message, content_x + content_width / 2, content_y + video_h / 2 + 40, fa_center, fa_bottom, c_error, 1, font_label)
}

/// popup_videoplayer_open()
/// @desc Opens a file dialog and loads the selected video.

function popup_videoplayer_open()
{
	var fn;
	fn = file_dialog_open("Video files (*.mp4; *.mov; *.avi; *.mkv; *.webm)|*.mp4;*.mov;*.avi;*.mkv;*.webm", "", "", text_get("videoplayeropen"))
	
	if (fn = "")
		return 0
	
	popup.fail_message = ""
	
	if (!video_open(fn))
	{
		popup.fail_message = text_get("videoplayeropenfail")
		return 0
	}
	
	video_volume(video_volume_get())
	video_play(true)
	return 1
}
