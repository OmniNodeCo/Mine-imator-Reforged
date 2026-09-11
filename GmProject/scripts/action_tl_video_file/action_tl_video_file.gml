/// action_tl_video_file(filename)
/// @arg filename
/// @desc Attaches a video file to the selected model timelines ("" removes the video).

function action_tl_video_file(fn)
{
	if (history_undo)
	{
		with (history_data)
		{
			for (var t = 0; t < save_var_amount; t++)
			{
				with (save_id_find(save_var_save_id[t]))
				{
					video_file = other.save_var_old_value[t]
					video_loaded_file = ""
				}
			}
		}
	}
	else if (history_redo)
	{
		with (history_data)
		{
			for (var t = 0; t < save_var_amount; t++)
			{
				with (save_id_find(save_var_save_id[t]))
				{
					video_file = other.save_var_new_value[t]
					video_loaded_file = ""
				}
			}
		}
	}
	else
	{
		var hobj = history_save_var_start(action_tl_video_file, true);
		
		with (obj_timeline)
		{
			if (!selected)
				continue
			
			with (hobj)
				history_save_var(other.id, other.video_file, fn)
			
			video_file = fn
			video_loaded_file = "" // Force reopen on the next draw
			
			if (video_file = "" && video_slot >= 0)
			{
				video_slot_free(video_slot)
				video_slot = -1
			}
		}
	}
}
