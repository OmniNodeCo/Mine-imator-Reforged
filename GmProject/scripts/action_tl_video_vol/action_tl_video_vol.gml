/// action_tl_video_vol(value, add)
/// @arg value
/// @arg add
/// @desc Sets the video screen volume of the selected timelines (value is 0-100).

function action_tl_video_vol(val, add)
{
	if (history_undo)
	{
		with (history_data)
			for (var t = 0; t < save_var_amount; t++)
				with (save_id_find(save_var_save_id[t]))
					video_vol = other.save_var_old_value[t]
	}
	else if (history_redo)
	{
		with (history_data)
			for (var t = 0; t < save_var_amount; t++)
				with (save_id_find(save_var_save_id[t]))
					video_vol = other.save_var_new_value[t]
	}
	else
	{
		var hobj = history_save_var_start(action_tl_video_vol, true);
		
		with (obj_timeline)
		{
			if (!selected)
				continue
			
			with (hobj)
				history_save_var(other.id, other.video_vol, clamp(other.video_vol * add + val / 100, 0, 1))
			
			video_vol = clamp(video_vol * add + val / 100, 0, 1)
		}
	}
}
