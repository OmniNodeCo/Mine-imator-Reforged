/// popup_worldgenerator_show()
/// @desc Opens the world generator popup. The seed field is left alone:
/// an empty field rolls a fresh random seed on every generate (like
/// Minecraft's world creation screen), while a typed seed keeps
/// reproducing its world.

function popup_worldgenerator_show()
{
	popup_show(popup_worldgenerator)
}
