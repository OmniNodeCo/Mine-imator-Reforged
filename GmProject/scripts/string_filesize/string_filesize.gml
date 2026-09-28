/// string_filesize(bytes)
/// @arg bytes
/// @desc Formats a byte count as a human-readable size (e.g. 640 KB, 3.4 MB).

function string_filesize(bytes)
{
	if (bytes < 1024)
		return string(floor(bytes)) + " B"
	
	var kb;
	kb = bytes / 1024
	if (kb < 1024)
		return string_decimals(kb) + " KB"
	
	var mb;
	mb = kb / 1024
	if (mb < 1024)
		return string_decimals(mb) + " MB"
	
	return string_decimals(mb / 1024) + " GB"
}
