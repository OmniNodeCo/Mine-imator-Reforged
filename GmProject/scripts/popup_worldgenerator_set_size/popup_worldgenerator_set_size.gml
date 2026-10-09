/// popup_worldgenerator_set_size(size)
/// @arg size
/// @desc Radio button callback: picks a world size preset (also fills the
/// custom size field, so the height field and seed keep applying).

function popup_worldgenerator_set_size(size)
{
	popup_worldgenerator.tbx_size.text = string(size)
}
