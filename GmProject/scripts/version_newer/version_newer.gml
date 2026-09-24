/// version_newer(version, other)
/// @arg version
/// @arg other
/// @desc Whether a Minecraft version id is newer than another (26.3 > 26.3-rc-1 > 26.3-pre-2 > 26.3-snapshot-9 > 26.2 > 1.21).

function version_newer(a, b)
{
	if (a = b)
		return false
	if (b = "")
		return (a != "")
	if (a = "")
		return false
	
	var aa, bb;
	aa = version_tokens(a)
	bb = version_tokens(b)
	
	for (var i = 0; i < max(array_length(aa), array_length(bb)); i++)
	{
		var ta, tb;
		ta = (i < array_length(aa) ? aa[i] : "")
		tb = (i < array_length(bb) ? bb[i] : "")
		
		if (ta = tb)
			continue
		
		// Numeric tokens compare numerically
		if (ta != "" && tb != "" && string_digits(ta) = ta && string_digits(tb) = tb)
			return (real(ta) > real(tb))
		
		// A missing token: a numeric tail means a newer version (26.3.1),
		// a word tail means a pre-release (26.3-snapshot-9)
		if (ta = "" || tb = "")
		{
			var present;
			present = (ta != "" ? ta : tb)
			if (string_digits(present) = present)
				return (ta != "")
			else
				return (ta = "")
		}
		
		// Pre-release words have a fixed order (snapshot < pre < rc)
		var ra, rb;
		ra = version_word_rank(ta)
		rb = version_word_rank(tb)
		if (ra != rb)
			return (ra > rb)
		return (ta > tb)
	}
	return false
}

function version_tokens(str)
{
	var tokens, token;
	tokens = array()
	token = ""
	
	for (var i = 1; i <= string_length(str); i++)
	{
		var c;
		c = string_char_at(str, i)
		
		if (c = "." || c = "-" || c = "_")
		{
			if (token != "")
				tokens[array_length(tokens)] = token
			token = ""
		}
		else
			token += c
	}
	
	if (token != "")
		tokens[array_length(tokens)] = token
	
	return tokens
}

function version_word_rank(word)
{
	switch (word)
	{
		case "snapshot": return 0
		case "pre": return 1
		case "rc": return 2
		default: return 3
	}
}
