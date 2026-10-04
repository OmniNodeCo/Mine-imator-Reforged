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
/// @desc Ragdoll pass for characters, mobs and model rigs: the rig falls
/// to the floor as a whole (the root timeline's world position drops with
/// gravity, exact landing frame) while every body part of its part tree
/// flops around its joint like a damped pendulum, staggered by chain depth
/// - the torso tips as it drops and the limbs whip after it, so the rig
/// crumples like a puppet. Rotations are baked in each part's local space
/// (that IS the joint rotation); positions of parts are left untouched.

function action_physics_ragdoll(hobj, gravity, floorauto, floorv, amplitude, period, damping, frames, step, marker)
{
	with (obj_timeline)
	{
		// Rigs only: characters, mobs (mob models are characters) and
		// ModelBench/model rigs. Scenery has its own mode (collapse).
		if (!selected || (type != e_tl_type.CHARACTER && type != e_tl_type.MODEL))
			continue
		
		// ---- Collect the full body-part tree (nested subparts included) ----
		// Parts are BODYPART timelines parented into tree_list; a flat
		// part_list only ever holds the direct parts and misses everything
		// nested (lower arms, hats, ...).
		var parts, depths;
		parts = ds_list_create()
		depths = ds_list_create()
		physics_ragdoll_collect_tree(id, 0, parts, depths)
		
		if (ds_list_size(parts) = 0)
		{
			ds_list_destroy(parts)
			ds_list_destroy(depths)
			continue
		}
		
		// Floor: an explicit Floor Z, or the world ground plane (Z = 0)
		if (floorauto)
			floorv = 0
		
		// ---- Root fall: the whole rig drops with gravity ----
		var z0, rx0, ry0, drop, tland, rootphase, f;
		z0 = value[e_value.POS_Z]
		rx0 = value[e_value.ROT_X]
		ry0 = value[e_value.ROT_Y]
		
		// The root tips over as it falls (same pendulum as the parts)
		rootphase = 0
		
		drop = z0 - floorv
		tland = clamp(ceil(sqrt(2 * max(0, drop) / gravity)), 1, frames)
		
		for (f = 0; f <= frames; f += step)
		{
			// Fall: parabolic drop with an exact rest afterwards
			var z, rootswing, ff;
			if (drop < 2)
				z = z0
			else if (f >= tland)
				z = floorv
			else
				z = max(floorv, z0 - 0.5 * gravity * f * f)
			
			// Tip: damped swing that starts at rest (frame 0 = current
			// rotation, no snap at the marker)
			ff = f
			rootswing = amplitude * .5 * (sin(pi * 2 * ff / period + rootphase) - sin(rootphase)) * power(2.718281828459045, -damping * ff)
			
			if (drop >= 2)
			{
				hobj.row_tl[hobj.row_amount] = save_id
				hobj.row_pos[hobj.row_amount] = marker + f
				hobj.row_vi[hobj.row_amount] = e_value.POS_Z
				hobj.row_val[hobj.row_amount] = z
				hobj.row_amount++
			}
			hobj.row_tl[hobj.row_amount] = save_id
			hobj.row_pos[hobj.row_amount] = marker + f
			hobj.row_vi[hobj.row_amount] = e_value.ROT_X
			hobj.row_val[hobj.row_amount] = rx0 + rootswing
			hobj.row_amount++
			hobj.row_tl[hobj.row_amount] = save_id
			hobj.row_pos[hobj.row_amount] = marker + f
			hobj.row_vi[hobj.row_amount] = e_value.ROT_Y
			hobj.row_val[hobj.row_amount] = ry0 + rootswing * .6
			hobj.row_amount++
		}
		
		// Exact landing keyframe when the step grid skips it
		if (drop >= 2 && tland <= frames && (tland mod step) != 0)
		{
			hobj.row_tl[hobj.row_amount] = save_id
			hobj.row_pos[hobj.row_amount] = marker + tland
			hobj.row_vi[hobj.row_amount] = e_value.POS_Z
			hobj.row_val[hobj.row_amount] = floorv
			hobj.row_amount++
		}
		
		hobj.tl_ids[hobj.tl_amount] = save_id
		hobj.tl_amount++
		
		// ---- Joint flops: every body part swings around its joint ----
		for (var c = 0; c < ds_list_size(parts); c++)
		{
			var part, depth, prx0, pry0, phase, delay;
			part = parts[|c]
			depth = depths[|c]
			
			prx0 = part.value[e_value.ROT_X]
			pry0 = part.value[e_value.ROT_Y]
			
			// Per-part swing phase (golden-angle spread) and depth stagger:
			// the deeper the limb, the later it starts moving
			phase = (depth * 1.31 + c * 2.399) mod (pi * 2)
			delay = depth * 2
			
			for (f = 0; f <= frames; f += step)
			{
				var pff, swing;
				pff = max(0, f - delay)
				
				// Flop: damped swing around the joint that starts at rest
				// (the phase offset is subtracted so frame 0 is exactly the
				// current rotation - no snap at the marker)
				swing = amplitude * (sin(pi * 2 * pff / period + phase) - sin(phase)) * power(2.718281828459045, -damping * pff)
				
				hobj.row_tl[hobj.row_amount] = part.save_id
				hobj.row_pos[hobj.row_amount] = marker + f
				hobj.row_vi[hobj.row_amount] = e_value.ROT_X
				hobj.row_val[hobj.row_amount] = prx0 + swing
				hobj.row_amount++
				hobj.row_tl[hobj.row_amount] = part.save_id
				hobj.row_pos[hobj.row_amount] = marker + f
				hobj.row_vi[hobj.row_amount] = e_value.ROT_Y
				hobj.row_val[hobj.row_amount] = pry0 + swing * .6
				hobj.row_amount++
			}
			
			hobj.tl_ids[hobj.tl_amount] = part.save_id
			hobj.tl_amount++
		}
		
		ds_list_destroy(parts)
		ds_list_destroy(depths)
	}
}

/// physics_ragdoll_collect_tree(timeline, depth, parts, depths)
/// @arg timeline
/// @arg depth
/// @arg parts
/// @arg depths
/// @desc Recursively collects the timeline's body-part tree (BODYPART
/// children, nested subparts included) with their chain depth.

function physics_ragdoll_collect_tree(tl, depth, parts, depths)
{
	var i, child;
	for (i = 0; i < ds_list_size(tl.tree_list); i++)
	{
		child = tl.tree_list[|i]
		
		if (child.type = e_tl_type.BODYPART)
		{
			ds_list_add(parts, child)
			ds_list_add(depths, depth)
			physics_ragdoll_collect_tree(child, depth + 1, parts, depths)
		}
	}
	
	return ds_list_size(parts)
}
