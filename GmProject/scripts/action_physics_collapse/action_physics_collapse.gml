/// action_physics_collapse(hobj, gravity, floorauto, floorv, maxframes, step, marker)
/// @arg hobj
/// @arg gravity
/// @arg floorauto
/// @arg floorv
/// @arg maxframes
/// @arg step
/// @arg marker
/// @desc Scenery collapse pass: for every selected scenery, each block that
/// is not supported (no block directly beneath it in its grid column, not
/// on the floor) falls with gravity onto the highest resting block below it
/// or the floor. Supported blocks get no keyframes at all - a block on the
/// floor does nothing, a block in the air falls.

function action_physics_collapse(hobj, gravity, floorauto, floorv, maxframes, step, marker)
{
	with (obj_timeline)
	{
		if (!selected || type != e_tl_type.SCENERY || part_list = null)
			continue

		// ---- Collect this scenery's blocks ----
		var blocks, b, part;
		blocks = ds_list_create()
		for (b = 0; b < ds_list_size(part_list); b++)
		{
			part = part_list[|b]
			if (part.type = e_tl_type.BLOCK || part.type = e_tl_type.SPECIAL_BLOCK)
				ds_list_add(blocks, part)
		}

		if (ds_list_size(blocks) = 0)
		{
			ds_list_destroy(blocks)
			continue
		}

		// ---- Group the blocks into vertical grid columns ----
		// Blocks are one block_size cube; the column key is the rounded
		// grid cell on the ground plane, the height is the Z position
		var columns, basez, key, gx, gy;
		columns = ds_map_create()
		basez = 0

		for (b = 0; b < ds_list_size(blocks); b++)
		{
			part = blocks[|b]
			gx = round(part.value[e_value.POS_X] / block_size)
			gy = round(part.value[e_value.POS_Y] / block_size)
			key = string(gx) + "|" + string(gy)

			if (!ds_map_exists(columns, key))
				columns[?key] = ds_list_create()
			ds_list_add(columns[?key], part)

			if (b = 0 || part.value[e_value.POS_Z] < basez)
				basez = part.value[e_value.POS_Z]
		}

		// The floor each column falls onto: the given floor height, or the
		// scenery's own lowest block level (blocks resting there keep still)
		var colfloor;
		if (floorauto)
			colfloor = basez
		else
			colfloor = floorv

		// ---- Rest heights per column, bottom block up; bake the falls ----
		var colkey, column, i, below, belowrest, thisrest, d;
		colkey = ds_map_find_first(columns)
		repeat (ds_map_size(columns))
		{
			column = columns[?colkey]

			// Sort the column by height (insertion sort, columns are small)
			for (i = 1; i < ds_list_size(column); i++)
			{
				var sortpart, j;
				sortpart = column[|i]
				j = i - 1
				while (j >= 0 && column[|j].value[e_value.POS_Z] > sortpart.value[e_value.POS_Z])
				{
					column[|j + 1] = column[|j]
					j--
				}
				column[|j + 1] = sortpart
			}

			// Bottom up: a supported block keeps its height, a floating
			// block lands on the block below it (at its final height) or
			// the floor
			below = null
			belowrest = 0
			for (i = 0; i < ds_list_size(column); i++)
			{
				part = column[|i]

				var z, supported;
				z = part.value[e_value.POS_Z]
				supported = (z <= colfloor + 2)
				if (!supported && below != null && z - (below.value[e_value.POS_Z]) < block_size + 2)
					supported = (abs(z - (belowrest + block_size)) < 2)

				if (supported)
					thisrest = z
				else if (below != null)
					thisrest = max(colfloor, belowrest + block_size)
				else
					thisrest = colfloor

				d = z - thisrest

				// On the floor or resting on a block: do nothing.
				// In the air: bake the fall (d = 0.5 * g * t^2).
				if (d >= 2)
				{
					var z0, tland, f;
					z0 = z
					tland = clamp(ceil(sqrt(2 * d / gravity)), 1, maxframes)

					for (f = 0; f <= tland; f += step)
					{
						var zpos;
						if (f = 0)
							zpos = z0
						else if (f >= tland)
							zpos = thisrest
						else
							zpos = max(thisrest, z0 - 0.5 * gravity * f * f)

						hobj.row_tl[hobj.row_amount] = part.save_id
						hobj.row_pos[hobj.row_amount] = marker + f
						hobj.row_vi[hobj.row_amount] = e_value.POS_Z
						hobj.row_val[hobj.row_amount] = zpos
						hobj.row_amount++
					}

					// Exact landing keyframe when the step grid skips it
					if ((tland mod step) != 0)
					{
						hobj.row_tl[hobj.row_amount] = part.save_id
						hobj.row_pos[hobj.row_amount] = marker + tland
						hobj.row_vi[hobj.row_amount] = e_value.POS_Z
						hobj.row_val[hobj.row_amount] = thisrest
						hobj.row_amount++
					}

					hobj.tl_ids[hobj.tl_amount] = part.save_id
					hobj.tl_amount++
				}

				below = part
				belowrest = thisrest
			}

			colkey = ds_map_find_next(columns, colkey)
		}

		var dk;
		dk = ds_map_find_first(columns)
		repeat (ds_map_size(columns))
		{
			ds_list_destroy(columns[?dk])
			dk = ds_map_find_next(columns, dk)
		}
		ds_map_destroy(columns)
		ds_list_destroy(blocks)
	}
}
