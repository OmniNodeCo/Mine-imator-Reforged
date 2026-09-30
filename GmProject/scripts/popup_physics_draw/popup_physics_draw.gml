/// popup_physics_draw()
/// @desc Timeline physics popup: bakes a physics motion (fall, throw,
/// pendulum swing or settle) into the selected timeline objects as
/// keyframes, starting at the current frame.

function popup_physics_draw()
{
	var halfw, selcount;
	halfw = (dw - 8) / 2

	// Selected timeline objects
	selcount = 0
	with (obj_timeline)
	{
		if (selected)
			selcount++
	}

	// Info line
	tab_control(20)
	if (selcount > 0)
		draw_label(text_get("physicsinfo", selcount), dx, dy + 16, fa_left, fa_middle, c_text_secondary, 1, font_label)
	else
		draw_label(text_get("physicsnone"), dx, dy + 16, fa_left, fa_middle, c_text_tertiary, a_text_tertiary, font_label)
	tab_next()

	// Motion type
	tab_control(74)
	draw_label(text_get("physicsmode"), dx, dy - 3, fa_left, fa_top, c_text_secondary, 1, font_label)
	draw_radiobutton("physicsfall", dx, dy + 22, 0, popup.mode = 0, popup_physics_set_mode)
	draw_radiobutton("physicsthrow", dx + halfw + 8, dy + 22, 1, popup.mode = 1, popup_physics_set_mode)
	draw_radiobutton("physicspendulum", dx, dy + 46, 2, popup.mode = 2, popup_physics_set_mode)
	draw_radiobutton("physicssettle", dx + halfw + 8, dy + 46, 3, popup.mode = 3, popup_physics_set_mode)
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
		draw_textfield("physicsvelocityy", dx + halfw + 8, dy, halfw, 24, popup.tbx_vy, null, "", "top")
	}
	else if (popup.mode = 2)
	{
		draw_textfield("physicsamplitude", dx, dy, halfw, 24, popup.tbx_amplitude, null, "", "top")
		draw_textfield("physicsperiod", dx + halfw + 8, dy, halfw, 24, popup.tbx_period, null, "", "top")
	}
	else
	{
		draw_textfield("physicsfloor", dx, dy, halfw, 24, popup.tbx_floor, null, "", "top")
		draw_textfield("physicsperiod", dx + halfw + 8, dy, halfw, 24, popup.tbx_period, null, "", "top")
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
		draw_textfield("physicsvelocityz", dx + halfw + 8, dy, halfw, 24, popup.tbx_vz, null, "", "top")
	}
	else if (popup.mode = 2)
	{
		draw_textfield("physicsdamping", dx, dy, halfw, 24, popup.tbx_damping, null, "", "top")
		draw_textfield("physicsframes", dx + halfw + 8, dy, halfw, 24, popup.tbx_frames, null, "", "top")
	}
	else
	{
		draw_textfield("physicsdamping", dx, dy, halfw, 24, popup.tbx_damping, null, "", "top")
		draw_textfield("physicsframes", dx + halfw + 8, dy, halfw, 24, popup.tbx_frames, null, "", "top")
	}
	tab_next()

	tab_control_textfield(true, 24)
	if (popup.mode = 1)
	{
		draw_textfield("physicsframes", dx, dy, halfw, 24, popup.tbx_frames, null, "", "top")
		draw_textfield("physicsstep", dx + halfw + 8, dy, halfw, 24, popup.tbx_step, null, "", "top")
	}
	else
	{
		draw_textfield("physicsstep", dx, dy, halfw, 24, popup.tbx_step, null, "", "top")
	}
	tab_next()

	// Bake
	tab_control_button_label()
	if (draw_button_label("physicsapply", dx + dw, dy, null, null, e_button.PRIMARY, null, e_anchor.RIGHT, selcount = 0))
	{
		if (action_physics_apply())
			popup_close()
	}
	tab_next()
}
