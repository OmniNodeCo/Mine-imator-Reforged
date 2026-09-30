/// action_tl_frame_cam_shaders(value)
/// @arg value
/// @desc Shader menu on the camera: -1 resets the camera's shader values to
/// defaults, -2 opens the install dialog, anything else applies the shader
/// pack at that index in shader_pack_list.

function action_tl_frame_cam_shaders(value)
{
	if (value = -1)
	{
		shader_pack_apply()
		toast_new(e_toast.POSITIVE, text_get("shaderreset"))
		return true
	}
	
	if (value = -2)
	{
		action_install_shaders()
		return true
	}
	
	if (value < 0 || value >= ds_list_size(shader_pack_list))
		return false
	
	var pack;
	pack = shader_pack_list[|value]
	shader_pack_apply(pack)
	toast_new(e_toast.POSITIVE, text_get("shaderapplied", pack[?"name"]))
	return true
}
