/// action_physics_apply()
/// @desc Bakes the physics motion configured in the physics popup into every
/// selected timeline object as keyframes, starting at the current frame.
/// Gravity acts along the world's up axis (Z, towards the ground plane):
/// fall and bounce, throw, pendulum swing, settle, scenery collapse (which
/// drops every unsupported block of the selected sceneries onto the block
/// or floor below it) or ragdoll (which crumples selected rigs part by
/// part). Fully undoable: undo removes exactly the keyframes the bake
/// created and restores any keyframes it overwrote - the user's own
/// keyframes are never touched.

function action_physics_apply()
{
	var mode, gravity, bounce, floorv, velx, vely, velz, amplitude, period, damping, frames, step;
	
	if (history_undo)
	{
		with (history_data)
		{
			// Remove exactly the keyframes this bake created (recorded
			// instance ids - no searching by position, which could hit a
			// keyframe the user made themselves)
			for (var g = 0; g < grp_amount; g++)
			{
				if (instance_exists(grp_kf[g]))
				{
					with (grp_kf[g])
						instance_destroy()
				}
			}
			
			// Restore the values the bake overwrote in pre-existing
			// keyframes
			for (var o = 0; o < reuse_amount; o++)
			{
				if (instance_exists(reuse_kf[o]))
				{
					with (reuse_kf[o])
						value[other.reuse_vi[o]] = other.reuse_old[o]
				}
			}
			
			// Recompute the current values of every affected timeline
			for (var t = 0; t < tl_amount; t++)
			{
				var tl_undo;
				tl_undo = save_id_find(tl_ids[t])
				if (tl_undo = null)
					continue
				
				with (tl_undo)
					tl_update_values()
			}
		}
	}
	else if (history_redo)
	{
		with (history_data)
		{
			var kf_existing;
			
			// Re-apply the bake: overwrite the same pre-existing keyframes
			// (their pre-bake values are only restored on undo) and
			// re-create the keyframes that were created, recording their
			// new ids so the next undo removes exactly those again
			grp_amount = 0
			
			for (var r = 0; r < row_amount; r++)
			{
				var tl_redo;
				tl_redo = save_id_find(row_tl[r])
				if (tl_redo = null)
					continue
				
				// Group start: does a keyframe already sit at this position?
				if (r = 0 || row_tl[r] != row_tl[r - 1] || row_pos[r] != row_pos[r - 1])
					kf_existing = physics_find_keyframe(tl_redo, row_pos[r])
				
				if (kf_existing != null)
				{
					with (kf_existing)
						value[other.row_vi[r]] = other.row_val[r]
				}
				else
				{
					tl_redo.value[row_vi[r]] = row_val[r]
					
					// Group end: create the keyframe and record its id
					if (r = row_amount - 1 || row_tl[r + 1] != row_tl[r] || row_pos[r + 1] != row_pos[r])
					{
						with (tl_redo)
							grp_kf[other.grp_amount] = tl_keyframe_add(other.row_pos[r])
						grp_amount++
					}
				}
			}
			
			for (var t2 = 0; t2 < tl_amount; t2++)
			{
				var tl_redo2;
				tl_redo2 = save_id_find(tl_ids[t2])
				if (tl_redo2 = null)
					continue
				
				with (tl_redo2)
					tl_update_values()
			}
		}
	}
	else
	{
		// Selection check: any mode needs selected timelines, collapse
		// specifically needs selected sceneries and ragdoll selected rigs
		// (characters, mobs and model rigs)
		var selcount, selcountany, selrigs;
		selcount = 0
		selcountany = 0
		selrigs = 0
		with (obj_timeline)
		{
			if (selected)
			{
				selcountany++
				if (type = e_tl_type.SCENERY)
					selcount++
				if (type = e_tl_type.CHARACTER || type = e_tl_type.MODEL)
					selrigs++
			}
		}
		if (selcountany = 0)
			return false
		if (popup_physics.mode = 4 && selcount = 0)
			return false
		if (popup_physics.mode = 5 && selrigs = 0)
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
			grp_kf = array()
			grp_amount = 0
			reuse_kf = array()
			reuse_vi = array()
			reuse_old = array()
			reuse_amount = 0
			tl_ids = array()
			tl_amount = 0
		}
		
		// Parameters from the popup (textboxes accept expressions)
		mode = popup_physics.mode
		gravity = max(0.01, eval(popup_physics.tbx_gravity.text, 0.5))
		bounce = clamp(eval(popup_physics.tbx_bounce.text, 0.5), 0, 1)
		floorv = eval(popup_physics.tbx_floor.text, 0)
		velx = eval(popup_physics.tbx_vx.text, 4)
		vely = eval(popup_physics.tbx_vy.text, 0)
		velz = eval(popup_physics.tbx_vz.text, 6)
		amplitude = eval(popup_physics.tbx_amplitude.text, 45)
		period = max(1, eval(popup_physics.tbx_period.text, 24))
		damping = max(0, eval(popup_physics.tbx_damping.text, 0.04))
		frames = clamp(round(eval(popup_physics.tbx_frames.text, 30)), 1, 10000)
		step = clamp(round(eval(popup_physics.tbx_step.text, 1)), 1, frames)
		
		var marker, floorauto;
		marker = app.timeline_marker
		floorauto = (popup_physics.tbx_floor.text = "")
		
		if (mode = 4)
		{
			// ---- Scenery collapse: drop unsupported blocks ----
			// Every block rests either on the block below it in its column
			// or on the floor; supported blocks keep perfectly still, only
			// floating blocks get fall keyframes.
			action_physics_collapse(hobj, gravity, floorauto, floorv, frames, step, marker)
		}
		else if (mode = 5)
		{
			// ---- Ragdoll: rigs crumble part by part ----
			// Every body part falls with gravity and flops around its joint
			// like a damped pendulum, staggered by chain depth (root first,
			// limbs whip after).
			action_physics_ragdoll(hobj, gravity, floorauto, floorv, amplitude, period, damping, frames, step, marker)
		}
		else
		{
			// ---- Per-object motions (fall, throw, pendulum, settle) ----
			with (obj_timeline)
			{
				if (!selected)
					continue
				
				var z0, r0, px, py, pz, vx, vy, vz, f, s;
				z0 = value[e_value.POS_Z]
				r0 = value[e_value.ROT_X]
				px = value[e_value.POS_X]
				py = value[e_value.POS_Y]
				pz = z0
				vz = velz
				vx = velx
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
								vz -= gravity
								pz += vz
								if (pz <= floorv)
								{
									pz = floorv
									vz = -vz * bounce
									if (abs(vz) < gravity)
										vz = 0
								}
							}
							else if (mode = 1)
							{
								vz -= gravity
								pz += vz
								px += vx
								py += vy
							}
						}
					}
					
					if (mode = 0)
					{
						hobj.row_tl[hobj.row_amount] = save_id
						hobj.row_pos[hobj.row_amount] = marker + f
						hobj.row_vi[hobj.row_amount] = e_value.POS_Z
						hobj.row_val[hobj.row_amount] = pz
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
						hobj.row_vi[hobj.row_amount] = e_value.ROT_X
						hobj.row_val[hobj.row_amount] = r0 + amplitude * cos(pi * 2 * f / period) * power(2.718281828459045, -damping * f)
						hobj.row_amount++
					}
					else
					{
						hobj.row_tl[hobj.row_amount] = save_id
						hobj.row_pos[hobj.row_amount] = marker + f
						hobj.row_vi[hobj.row_amount] = e_value.POS_Z
						hobj.row_val[hobj.row_amount] = floorv + (z0 - floorv) * cos(pi * 2 * f / period) * power(2.718281828459045, -damping * f)
						hobj.row_amount++
					}
				}
				
				hobj.tl_ids[hobj.tl_amount] = save_id
				hobj.tl_amount++
			}
		}
		
		// ---- Turn the recorded rows into keyframes ----
		// When a keyframe already sits at a target position, its baked
		// values are overwritten in place (the old values are recorded so
		// undo can restore them) instead of stacking a second keyframe
		// next to it. Created keyframes are recorded by id, so undo removes
		// exactly what this bake made.
		var tl_bake, kf_existing, rb, tb;
		for (rb = 0; rb < hobj.row_amount; rb++)
		{
			tl_bake = save_id_find(hobj.row_tl[rb])
			if (tl_bake = null)
				continue
			
			// Group start: does a keyframe already sit at this position?
			if (rb = 0 || hobj.row_tl[rb] != hobj.row_tl[rb - 1] || hobj.row_pos[rb] != hobj.row_pos[rb - 1])
				kf_existing = physics_find_keyframe(tl_bake, hobj.row_pos[rb])
			
			if (kf_existing != null)
			{
				// Overwrite the value inside the existing keyframe
				hobj.reuse_kf[hobj.reuse_amount] = kf_existing
				hobj.reuse_vi[hobj.reuse_amount] = hobj.row_vi[rb]
				hobj.reuse_old[hobj.reuse_amount] = kf_existing.value[hobj.row_vi[rb]]
				hobj.reuse_amount++
				
				kf_existing.value[hobj.row_vi[rb]] = hobj.row_val[rb]
			}
			else
			{
				tl_bake.value[hobj.row_vi[rb]] = hobj.row_val[rb]
				
				// Group end: create the keyframe and record its id
				if (rb = hobj.row_amount - 1 || hobj.row_tl[rb + 1] != hobj.row_tl[rb] || hobj.row_pos[rb + 1] != hobj.row_pos[rb])
				{
					with (tl_bake)
						hobj.grp_kf[hobj.grp_amount] = tl_keyframe_add(hobj.row_pos[rb])
					hobj.grp_amount++
				}
			}
		}
		
		// Restore the values at the current frame
		for (tb = 0; tb < hobj.tl_amount; tb++)
		{
			var tl_restore;
			tl_restore = save_id_find(hobj.tl_ids[tb])
			if (tl_restore = null)
				continue
			
			with (tl_restore)
				tl_update_values()
		}
		
		toast_new(e_toast.POSITIVE, text_get("physicsbaked", hobj.tl_amount))
		log("Physics: baked", hobj.tl_amount, "object(s),", hobj.row_amount, "keyframe values,", hobj.grp_amount, "new keyframes,", hobj.reuse_amount, "overwritten")
	}
	
	tl_update_matrix()
	tl_update_length()
	app_update_tl_edit()
	
	return true
}

/// physics_find_keyframe(timeline, position)
/// @arg timeline
/// @arg position
/// @desc Returns the keyframe of the given timeline at the given position,
/// or null when there is none. Read-only: never destroys anything.

function physics_find_keyframe(tl, pos)
{
	var k, kflist, kfcount;
	
	with (tl)
	{
		kflist = keyframe_list
		kfcount = ds_list_size(kflist)
		for (k = 0; k < kfcount; k++)
		{
			if (kflist[|k].position = pos)
				return kflist[|k]
		}
	}
	
	return null
}
