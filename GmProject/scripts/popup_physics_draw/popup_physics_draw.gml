/// popup_physics_draw()
/// @desc Timeline physics popup: bakes a physics motion into the selected
/// timeline objects as keyframes, starting at the current frame. Gravity
/// pulls along the world's up axis (Z): fall + bounce, throw, pendulum
/// swing, settle, scenery collapse (blocks in the air fall while supported
/// blocks keep still) or ragdoll (rigs crumple part by part, every limb
/// falling and flopping on its joint, staggered by depth).

function popup_physics_draw()
{
	var halfw, selcount, selscenery;
	halfw = (dw - 8) / 2

	// Selected timeline objects (sceneries count for collapse, character/
	// mob/model rigs count for ragdoll)
	selcount = 0
	selscenery = 0
	selrigs = 0
	with (obj_timeline)
	{
		if (selected)
		{
			selcount++
			if (type = e_tl_type.SCENERY)
				selscenery++
			if (type = e_tl_type.CHARACTER || type = e_tl_type.MODEL)
				selrigs++
		}
	}

	// Info line
	tab_control(20)
	if (popup.mode = 4)
	{
		if (selscenery > 0)
			draw_label(text_get("physicsinfoscenery", selscenery), dx, dy + 16, fa_left, fa_middle, c_text_secondary, 1, font_label)
		else
			draw_label(text_get("physicsscenerynone"), dx, dy + 16, fa_left, fa_middle, c_text_tertiary, a_text_tertiary, font_label)
	}
	else if (popup.mode = 5)
	{
		if (selrigs > 0)
			draw_label(text_get("physicsinforig", selrigs), dx, dy + 16, fa_left, fa_middle, c_text_secondary, 1, font_label, 14, dw)
		else
			draw_label(text_get("physicsrignone"), dx, dy + 16, fa_left, fa_middle, c_text_tertiary, a_text_tertiary, font_label, 14, dw)
	}
	else if (selcount > 0)
		draw_label(text_get("physicsinfo", selcount), dx, dy + 16, fa_left, fa_middle, c_text_secondary, 1, font_label)
	else
		draw_label(text_get("physicsnone"), dx, dy + 16, fa_left, fa_middle, c_text_tertiary, a_text_tertiary, font_label)
	tab_next()

	// Motion type
	tab_control(122)
	draw_label(text_get("physicsmode"), dx, dy - 3, fa_left, fa_top, c_text_secondary, 1, font_label)
	draw_radiobutton("physicsfall", dx, dy + 22, 0, popup.mode = 0, popup_physics_set_mode)
	draw_radiobutton("physicsthrow", dx + halfw + 8, dy + 22, 1, popup.mode = 1, popup_physics_set_mode)
	draw_radiobutton("physicspendulum", dx, dy + 46, 2, popup.mode = 2, popup_physics_set_mode)
	draw_radiobutton("physicssettle", dx + halfw + 8, dy + 46, 3, popup.mode = 3, popup_physics_set_mode)
	draw_radiobutton("physicscollapse", dx, dy + 70, 4, popup.mode = 4, popup_physics_set_mode)
	draw_radiobutton("physicsragdoll", dx + halfw + 8, dy + 70, 5, popup.mode = 5, popup_physics_set_mode)
	draw_label(text_get("physicsdesc" + string(popup.mode)), dx, dy + 94, fa_left, fa_top, c_text_tertiary, a_text_tertiary, font_caption, 14, dw)
	tab_next()

	// Parameters, two fields per row
	tab_control_textfield(true, 24)
	if (popup.mode = 0)
	{
		draw_textfield("physicsgravity", dx, dy, halfw, 24, popup.tbx_gravity, null, "", "top")
		draw_textfield("physicsbounce", dx + halfw + 8, dy, halfw, 24, popup.tbx_bounce, null, "", "top")
	}
	else if (popup.mode = 1)
	{
		draw_textfield("physicsgravity", dx, dy, halfw, 24, popup.tbx_gravity, null, "", "top")
		draw_textfield("physicsvelocityz", dx + halfw + 8, dy, halfw, 24, popup.tbx_vz, null, "", "top")
	}
	else if (popup.mode = 2)
	{
		draw_textfield("physicsamplitude", dx, dy, halfw, 24, popup.tbx_amplitude, null, "", "top")
		draw_textfield("physicsperiod", dx + halfw + 8, dy, halfw, 24, popup.tbx_period, null, "", "top")
	}
	else if (popup.mode = 3)
	{
		draw_textfield("physicsfloor", dx, dy, halfw, 24, popup.tbx_floor, null, "", "top")
		draw_textfield("physicsperiod", dx + halfw + 8, dy, halfw, 24, popup.tbx_period, null, "", "top")
	}
	else
	{
		draw_textfield("physicsgravity", dx, dy, halfw, 24, popup.tbx_gravity, null, "", "top")
		draw_textfield("physicsfloor", dx + halfw + 8, dy, halfw, 24, popup.tbx_floor, null, "", "top")
	}
	tab_next()

	tab_control_textfield(true, 24)
	if (popup.mode = 0)
	{
		draw_textfield("physicsfloor", dx, dy, halfw, 24, popup.tbx_floor, null, "", "top")
		draw_textfield("physicsframes", dx + halfw + 8, dy, halfw, 24, popup.tbx_frames, null, "", "top")
	}
	else if (popup.mode = 1)
	{
		draw_textfield("physicsvelocityx", dx, dy, halfw, 24, popup.tbx_vx, null, "", "top")
		draw_textfield("physicsvelocityy", dx + halfw + 8, dy, halfw, 24, popup.tbx_vy, null, "", "top")
	}
	else if (popup.mode = 2)
	{
		draw_textfield("physicsdamping", dx, dy, halfw, 24, popup.tbx_damping, null, "", "top")
		draw_textfield("physicsframes", dx + halfw + 8, dy, halfw, 24, popup.tbx_frames, null, "", "top")
	}
	else if (popup.mode = 3)
	{
		draw_textfield("physicsdamping", dx, dy, halfw, 24, popup.tbx_damping, null, "", "top")
		draw_textfield("physicsframes", dx + halfw + 8, dy, halfw, 24, popup.tbx_frames, null, "", "top")
	}
	else if (popup.mode = 5)
	{
		draw_textfield("physicsamplitude", dx, dy, halfw, 24, popup.tbx_amplitude, null, "", "top")
		draw_textfield("physicsperiod", dx + halfw + 8, dy, halfw, 24, popup.tbx_period, null, "", "top")
	}
	else
	{
		draw_textfield("physicsframes", dx, dy, halfw, 24, popup.tbx_frames, null, "", "top")
		draw_textfield("physicsstep", dx + halfw + 8, dy, halfw, 24, popup.tbx_step, null, "", "top")
	}
	tab_next()

	tab_control_textfield(true, 24)
	if (popup.mode = 1)
	{
		draw_textfield("physicsframes", dx, dy, halfw, 24, popup.tbx_frames, null, "", "top")
		draw_textfield("physicsstep", dx + halfw + 8, dy, halfw, 24, popup.tbx_step, null, "", "top")
	}
	else if (popup.mode = 5)
	{
		draw_textfield("physicsdamping", dx, dy, halfw, 24, popup.tbx_damping, null, "", "top")
		draw_textfield("physicsframes", dx + halfw + 8, dy, halfw, 24, popup.tbx_frames, null, "", "top")
	}
	else if (popup.mode != 4)
	{
		draw_textfield("physicsstep", dx, dy, halfw, 24, popup.tbx_step, null, "", "top")
	}
	else
	{
		// Collapse: floor hint instead of more fields
		draw_label(text_get("physicsfloorauto"), dx, dy + 16, fa_left, fa_middle, c_text_tertiary, a_text_tertiary, font_caption)
	}
	tab_next()

	// Ragdoll: floor hint (auto floor = the rig's lowest part)
	if (popup.mode = 5)
	{
		tab_control(18)
		draw_label(text_get("physicsfloorautoragdoll"), dx, dy + 14, fa_left, fa_middle, c_text_tertiary, a_text_tertiary, font_caption, 12, dw)
		tab_next()
	}

	// Bake
	var canbake;
	canbake = (popup.mode = 4 ? selscenery > 0 : (popup.mode = 5 ? selrigs > 0 : selcount > 0))

	tab_control_button_label()
	if (draw_button_label("physicsapply", dx + dw, dy, null, null, e_button.PRIMARY, null, e_anchor.RIGHT, !canbake))
	{
		if (action_physics_apply())
			popup_close()
	}
	tab_next()
}
