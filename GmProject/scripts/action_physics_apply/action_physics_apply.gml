/// action_physics_apply()
/// @desc Bakes the physics motion configured in the physics popup into every
/// selected timeline object as keyframes, starting at the current frame:
/// fall and bounce, throw, pendulum swing or settle. Fully undoable.

function action_physics_apply()
{
	var mode, gravity, bounce, floorv, velx, vely, velz, amplitude, period, damping, frames, step;

	if (history_undo)
	{
		with (history_data)
		{
			// Remove the keyframes this action created (rows are grouped:
			// one keyframe can hold several baked values)
			var tl_last, pos_last, tl_cur;
			tl_last = null
			pos_last = -1

			for (var r = 0; r < row_amount; r++)
			{
				if (row_tl[r] = tl_last)
				{
					if (row_pos[r] = pos_last)
						continue
				}
				tl_last = row_tl[r]
				pos_last = row_pos[r]

				tl_cur = save_id_find(row_tl[r])
				if (tl_cur = null)
					continue

				with (tl_cur)
				{
					for (var k = 0; k < ds_list_size(keyframe_list); k++)
					{
						if (keyframe_list[|k].position = pos_last)
						{
							with (keyframe_list[|k])
								instance_destroy()
							break
						}
					}
					tl_update_values()
				}
			}
		}
	}
	else if (history_redo)
	{
		with (history_data)
		{
			// Re-create the baked keyframes from the recorded rows
			var tl_redo, tl_prev;
			tl_prev = null

			for (var r = 0; r < row_amount; r++)
			{
				tl_redo = save_id_find(row_tl[r])
				if (tl_redo = null)
					continue

				if (tl_redo != tl_prev)
				{
					tl_prev = tl_redo
					with (tl_redo)
						tl_update_values()
				}

				tl_redo.value[row_vi[r]] = row_val[r]

				// Last row of a keyframe group: create the keyframe
				var lastgroup;
				lastgroup = false
				if (r = row_amount - 1)
					lastgroup = true
				else if (row_tl[r + 1] != row_tl[r])
					lastgroup = true
				else if (row_pos[r + 1] != row_pos[r])
					lastgroup = true

				if (lastgroup)
				{
					with (tl_redo)
						tl_keyframe_add(other.row_pos[r])
				}
			}
		}
	}
	else
	{
		// Need at least one selected timeline object
		var selcount;
		selcount = 0
		with (obj_timeline)
		{
			if (selected)
				selcount++
		}
		if (selcount = 0)
			return false

		var hobj;
		hobj = history_set(action_physics_apply)

		with (hobj)
		{
			row_tl = array()
			row_pos = array()
			row_vi = array()
			row_val = array()
			row_amount = 0
			tl_ids = array()
			tl_amount = 0
		}

		// Parameters from the popup (textboxes accept expressions)
		mode = popup_physics.mode
		gravity = max(0, eval(popup_physics.tbx_gravity.text, 0.5))
		bounce = clamp(eval(popup_physics.tbx_bounce.text, 0.5), 0, 1)
		floorv = eval(popup_physics.tbx_floor.text, 0)
		velx = eval(popup_physics.tbx_vx.text, 4)
		vely = eval(popup_physics.tbx_vy.text, 6)
		velz = eval(popup_physics.tbx_vz.text, 0)
		amplitude = eval(popup_physics.tbx_amplitude.text, 45)
		period = max(1, eval(popup_physics.tbx_period.text, 24))
		damping = max(0, eval(popup_physics.tbx_damping.text, 0.04))
		frames = clamp(round(eval(popup_physics.tbx_frames.text, 30)), 1, 10000)
		step = clamp(round(eval(popup_physics.tbx_step.text, 1)), 1, frames)

		var marker;
		marker = app.timeline_marker

		// Simulate every selected object and record the baked values
		with (obj_timeline)
		{
			if (!selected)
				continue

			var y0, r0, px, py, pz, vy, f, s;
			y0 = value[e_value.POS_Y]
			r0 = value[e_value.ROT_Z]
			px = value[e_value.POS_X]
			py = y0
			pz = value[e_value.POS_Z]
			vy = vely

			for (f = 0; f <= frames; f += step)
			{
				// Advance the simulation by one step
				if (f > 0)
				{
					for (s = 0; s < step; s++)
					{
						if (mode = 0)
						{
							vy -= gravity
							py += vy
							if (py <= floorv)
							{
								py = floorv
								vy = -vy * bounce
								if (abs(vy) < gravity)
									vy = 0
							}
						}
						else if (mode = 1)
						{
							vy -= gravity
							py += vy
							px += velx
							pz += velz
						}
					}
				}

				if (mode = 0)
				{
					hobj.row_tl[hobj.row_amount] = save_id
					hobj.row_pos[hobj.row_amount] = marker + f
					hobj.row_vi[hobj.row_amount] = e_value.POS_Y
					hobj.row_val[hobj.row_amount] = py
					hobj.row_amount++
				}
				else if (mode = 1)
				{
					hobj.row_tl[hobj.row_amount] = save_id
					hobj.row_pos[hobj.row_amount] = marker + f
					hobj.row_vi[hobj.row_amount] = e_value.POS_X
					hobj.row_val[hobj.row_amount] = px
					hobj.row_amount++
					hobj.row_tl[hobj.row_amount] = save_id
					hobj.row_pos[hobj.row_amount] = marker + f
					hobj.row_vi[hobj.row_amount] = e_value.POS_Y
					hobj.row_val[hobj.row_amount] = py
					hobj.row_amount++
					hobj.row_tl[hobj.row_amount] = save_id
					hobj.row_pos[hobj.row_amount] = marker + f
					hobj.row_vi[hobj.row_amount] = e_value.POS_Z
					hobj.row_val[hobj.row_amount] = pz
					hobj.row_amount++
				}
				else if (mode = 2)
				{
					hobj.row_tl[hobj.row_amount] = save_id
					hobj.row_pos[hobj.row_amount] = marker + f
					hobj.row_vi[hobj.row_amount] = e_value.ROT_Z
					hobj.row_val[hobj.row_amount] = r0 + amplitude * cos(pi * 2 * f / period) * power(2.718281828459045, -damping * f)
					hobj.row_amount++
				}
				else
				{
					hobj.row_tl[hobj.row_amount] = save_id
					hobj.row_pos[hobj.row_amount] = marker + f
					hobj.row_vi[hobj.row_amount] = e_value.POS_Y
					hobj.row_val[hobj.row_amount] = floorv + (y0 - floorv) * cos(pi * 2 * f / period) * power(2.718281828459045, -damping * f)
					hobj.row_amount++
				}
			}

			hobj.tl_ids[hobj.tl_amount] = save_id
			hobj.tl_amount++
		}

		// Turn the recorded rows into keyframes
		var tl_bake, lastgroup2;
		for (var r = 0; r < hobj.row_amount; r++)
		{
			tl_bake = save_id_find(hobj.row_tl[r])
			if (tl_bake = null)
				continue

			tl_bake.value[hobj.row_vi[r]] = hobj.row_val[r]

			lastgroup2 = false
			if (r = hobj.row_amount - 1)
				lastgroup2 = true
			else if (hobj.row_tl[r + 1] != hobj.row_tl[r])
				lastgroup2 = true
			else if (hobj.row_pos[r + 1] != hobj.row_pos[r])
				lastgroup2 = true

			if (lastgroup2)
			{
				with (tl_bake)
					tl_keyframe_add(hobj.row_pos[r])
			}
		}

		// Restore the values at the current frame
		for (var t = 0; t < hobj.tl_amount; t++)
		{
			var tl_restore;
			tl_restore = save_id_find(hobj.tl_ids[t])
			if (tl_restore = null)
				continue
			with (tl_restore)
				tl_update_values()
		}

		toast_new(e_toast.POSITIVE, text_get("physicsbaked", hobj.tl_amount))
		log("Physics: baked", hobj.tl_amount, "object(s),", hobj.row_amount, "keyframe values")
	}

	tl_update_matrix()
	tl_update_length()
	app_update_tl_edit()

	return true
}
