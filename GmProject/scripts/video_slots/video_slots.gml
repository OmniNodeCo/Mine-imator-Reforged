/// video_slot_alloc()
/// @desc Returns a free video player slot (0-7) for a video screen, or -1 if all are in use.

function video_slot_alloc()
{
	for (var i = 0; i < 8; i++)
	{
		if (!app.video_slot_used[i])
		{
			app.video_slot_used[i] = true
			return i
		}
	}
	
	return -1
}

/// video_slot_free(slot)
/// @arg slot
/// @desc Releases a video player slot and closes its video.

function video_slot_free(slot)
{
	if (slot < 0)
		return 0
	
	video_close(slot)
	app.video_slot_used[slot] = false
}
