/// shader_pack_apply(pack)
/// @arg pack
/// @desc Applies a shader pack to the selected camera at the current frame:
/// every shader-scope camera value is reset to its default first, then the
/// pack's values are set. One undoable action, like editing the values by
/// hand. Pass no pack (or an invalid map) to only reset to defaults.

function shader_pack_apply()
{
	var pack;
	pack = (argument_count > 0 ? argument[0] : undefined)
	
	if (!ds_map_valid(pack))
	{
		// Reset only
		shader_pack_apply_start()
		shader_pack_apply_done()
		return true
	}
	
	var values, setcount;
	values = pack[?"values"]
	setcount = 0
	
	shader_pack_apply_start()
	
	// The pack's values (colors arrive as "#RRGGBB" strings)
	var key;
	key = ds_map_find_first(values)
	repeat (ds_map_size(values))
	{
		var vid, val;
		vid = -1
		if (ds_map_exists(shader_value_map, key))
			vid = shader_value_map[?key]
		
		if (vid >= 0)
		{
			val = values[?key]
			if (tl_value_is_color(vid) && is_string(val))
				val = hex_to_color(val)
			
			tl_value_set(vid, val, false)
			setcount++
		}
		else
			log("Shaders: unknown value in pack", pack[?"file"], key)
		
		key = ds_map_find_next(values, key)
	}
	
	shader_pack_apply_done()
	
	log("Shaders: applied", pack[?"name"], "-", setcount, "values")
	return true
}

/// shader_pack_apply_start() - resets all shader-scope values to defaults
/// inside a value-set action

function shader_pack_apply_start()
{
	tl_value_set_start(shader_pack_apply, false)
	
	for (var i = 0; i < ds_list_size(shader_value_list); i++)
	{
		var vid;
		vid = shader_value_list[|i]
		tl_value_set(vid, tl_value_default(vid), false)
	}
}

/// shader_pack_apply_done() - ends the value-set action

function shader_pack_apply_done()
{
	tl_value_set_done()
}
