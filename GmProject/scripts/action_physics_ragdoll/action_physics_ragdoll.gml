/// action_physics_ragdoll(hobj, gravity, floorauto, floorv, amplitude, period, damping, frames, step, marker)
/// @arg hobj
/// @arg gravity
/// @arg floorauto
/// @arg floorv
/// @arg amplitude
/// @arg period
/// @arg damping
/// @arg frames
/// @arg step
/// @arg marker
/// @desc Ragdoll pass for player/character rigs: every body part of the
/// selected rigs falls with gravity and flops around its joint like a
/// damped pendulum, staggered by chain depth - the root drops first and
/// the limbs whip after it, so the rig crumples like a puppet instead of
/// moving as one block. Parts at or below the floor level only flop.

function action_physics_ragdoll(hobj, gravity, floorauto, floorv, amplitude, period, damping, frames, step, marker)
{
	with (obj_timeline)
	{
		if (!selected || part_list = null)
			continue
		
		// ---- Collect the rig's parts with their chain depth (root = 0) ----
		var parts, depths;
		parts = ds_list_create()
		depths = ds_list_create()
		physics_ragdoll_collect(id, 0, parts, depths)
		
		if (ds_list_size(parts) = 0)
		{
			ds_list_destroy(parts)
			ds_list_destroy(depths)
			continue
		}
		
		// Auto floor: the rig's own lowest part level (leave Floor Z empty)
		if (floorauto)
		{
			floorv = 0
			for (var c = 0; c < ds_list_size(parts); c++)
			{
				if (c = 0 || parts[|c].value[e_value.POS_Z] < floorv)
					floorv = parts[|c].value[e_value.POS_Z]
			}
		}
		
		// ---- Bake per part: staggered fall + damped joint flop ----
		for (var c = 0; c < ds_list_size(parts); c++)
		{
			var part, depth;
			part = parts[|c]
			depth = depths[|c]
			
			var z0, rx0, ry0, phase, delay, drop, tland;
			z0 = part.value[e_value.POS_Z]
			rx0 = part.value[e_value.ROT_X]
			ry0 = part.value[e_value.ROT_Y]
			
			// Per-part swing phase (golden-angle spread) and depth stagger:
			// the deeper the limb, the later it starts moving
			phase = (depth * 1.31 + c * 2.399) mod (pi * 2)
			delay = depth * 2
			
			drop = z0 - floorv
			tland = clamp(ceil(sqrt(2 * max(0, drop) / gravity)), 1, frames)
			
			var f;
			for (f = 0; f <= frames; f += step)
			{
				var ff, z, swing;
				ff = max(0, f - delay)
				
				// Fall: parabolic drop with an exact rest afterwards
				if (drop < 2)
					z = z0
				else if (ff >= tland)
					z = floorv
				else
					z = max(floorv, z0 - 0.5 * gravity * ff * ff)
				
				// Flop: damped swing around the joint that starts at rest
				// (the phase offset is subtracted so frame 0 is exactly the
				// current rotation - no snap at the marker)
				swing = amplitude * (sin(pi * 2 * ff / period + phase) - sin(phase)) * power(2.718281828459045, -damping * ff)
				
				hobj.row_tl[hobj.row_amount] = part.save_id
				hobj.row_pos[hobj.row_amount] = marker + f
				hobj.row_vi[hobj.row_amount] = e_value.ROT_X
				hobj.row_val[hobj.row_amount] = rx0 + swing
				hobj.row_amount++
				hobj.row_tl[hobj.row_amount] = part.save_id
				hobj.row_pos[hobj.row_amount] = marker + f
				hobj.row_vi[hobj.row_amount] = e_value.ROT_Y
				hobj.row_val[hobj.row_amount] = ry0 + swing * .6
				hobj.row_amount++
				
				if (drop >= 2)
				{
					hobj.row_tl[hobj.row_amount] = part.save_id
					hobj.row_pos[hobj.row_amount] = marker + f
					hobj.row_vi[hobj.row_amount] = e_value.POS_Z
					hobj.row_val[hobj.row_amount] = z
					hobj.row_amount++
				}
			}
			
			// Exact landing keyframe when the step grid skips it
			if (drop >= 2 && tland <= frames && (tland mod step) != 0)
			{
				var ff2, swing2;
				ff2 = max(0, tland - delay)
				swing2 = amplitude * (sin(pi * 2 * ff2 / period + phase) - sin(phase)) * power(2.718281828459045, -damping * ff2)
				
				hobj.row_tl[hobj.row_amount] = part.save_id
				hobj.row_pos[hobj.row_amount] = marker + tland
				hobj.row_vi[hobj.row_amount] = e_value.ROT_X
				hobj.row_val[hobj.row_amount] = rx0 + swing2
				hobj.row_amount++
				hobj.row_tl[hobj.row_amount] = part.save_id
				hobj.row_pos[hobj.row_amount] = marker + tland
				hobj.row_vi[hobj.row_amount] = e_value.ROT_Y
				hobj.row_val[hobj.row_amount] = ry0 + swing2 * .6
				hobj.row_amount++
				hobj.row_tl[hobj.row_amount] = part.save_id
				hobj.row_pos[hobj.row_amount] = marker + tland
				hobj.row_vi[hobj.row_amount] = e_value.POS_Z
				hobj.row_val[hobj.row_amount] = floorv
				hobj.row_amount++
			}
			
			hobj.tl_ids[hobj.tl_amount] = part.save_id
			hobj.tl_amount++
		}
		
		ds_list_destroy(parts)
		ds_list_destroy(depths)
	}
}

/// physics_ragdoll_collect(parent, depth, parts, depths)
/// @arg parent
/// @arg depth
/// @arg parts
/// @arg depths
/// @desc Recursively collects a rig's part timelines and their chain depth.

function physics_ragdoll_collect(parent, depth, parts, depths)
{
	var pl, i, part;
	pl = parent.part_list
	if (pl = null)
		return 0
	
	for (i = 0; i < ds_list_size(pl); i++)
	{
		part = pl[|i]
		ds_list_add(parts, part)
		ds_list_add(depths, depth)
		physics_ragdoll_collect(part, depth + 1, parts, depths)
	}
	
	return ds_list_size(parts)
}
