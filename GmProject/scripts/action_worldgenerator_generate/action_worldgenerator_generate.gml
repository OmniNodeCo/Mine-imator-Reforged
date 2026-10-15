/// action_worldgenerator_generate()
/// @desc World generator: builds a random blocky landscape (layered hills,
/// optional water and trees) from the seed and settings in the world
/// generator popup, writes it as an uncompressed Sponge v1 .schematic NBT
/// file next to the project and loads it in as a new scenery on the
/// workbench. Seeds run through Minecraft's seed engine (see
/// worldgenerator_mc_seed): the same seed text always produces the same
/// world, and an empty seed field rolls a fresh random seed every time.
/// Blocks that the current texture pack does not know are swapped for
/// similar ones, so the generator works with any pack.

function action_worldgenerator_generate()
{
	var size, height, rough, roughpct, trees, water, seedstr, seed;
	
	// Settings (textboxes accept expressions)
	size = clamp(round(eval(popup_worldgenerator.tbx_size.text, 64)), 8, 96)
	height = clamp(round(eval(popup_worldgenerator.tbx_height.text, 48)), 8, 64)
	roughpct = clamp(round(eval(popup_worldgenerator.tbx_roughness.text, 50)), 0, 100)
	rough = roughpct / 100
	trees = popup_worldgenerator.trees
	water = popup_worldgenerator.water
	seedstr = popup_worldgenerator.tbx_seed.text
	seed = worldgenerator_mc_seed(seedstr)
	
	// Feature salts: separate Minecraft-style salt offsets keep the noise
	// octaves and the tree features on independent random streams, the
	// same trick real Minecraft's structure placement uses (e.g. 14357620
	// is the swamp hut salt)
	var salt_hill, salt_bump, salt_detail, salt_tree, salt_treex, salt_treez, salt_trunk, salt_leaf;
	salt_hill = 14357617
	salt_bump = 14357618
	salt_detail = 14357619
	salt_tree = 14357620
	salt_treex = 14357621
	salt_treez = 14357622
	salt_trunk = 14357623
	salt_leaf = 14357624
	
	// Palette: look up which blocks the current texture pack knows
	// 0 air, 1 stone, 2 dirt, 3 grass, 4 sand, 5 water, 6 oak log, 7 oak leaves
	var pal_names, pal, pal_written, nextidx, i;
	pal_names = array("minecraft:air", "minecraft:stone", "minecraft:dirt", "minecraft:grass_block", "minecraft:sand", "minecraft:water", "minecraft:oak_log", "minecraft:oak_leaves")
	pal = array()
	pal_written = array()
	nextidx = 0
	for (i = 0; i < 8; i++)
	{
		pal[i] = -1
		pal_written[i] = false
		if (i = 0 || ds_map_exists(mc_assets.block_id_map, pal_names[i]))
		{
			pal[i] = nextidx
			pal_written[i] = true
			nextidx++
		}
	}
	// Missing blocks fall back to a similar one
	if (pal[2] = -1)
		pal[2] = pal[1]
	if (pal[3] = -1)
		pal[3] = pal[2]
	if (pal[4] = -1)
		pal[4] = pal[1]
	if (pal[1] = -1)
		pal[1] = pal[0]
	pal[2] = max(pal[2], pal[0])
	pal[3] = max(pal[3], pal[0])
	pal[4] = max(pal[4], pal[0])
	trees = trees && pal[6] >= 0 && pal[7] >= 0
	water = water && pal[5] >= 0
	
	// Heightmap: smooth value noise in three octaves, roughness scales
	// the amplitude, trees get their headroom reserved
	var heights, water_level, x, z, y, h;
	water_level = max(2, floor(height * 0.32))
	heights = array()
	for (x = 0; x < size; x++)
	{
		for (z = 0; z < size; z++)
		{
			h = height * 0.38
			h += (worldgenerator_noise(x, z, 16, seed, salt_hill) - 0.5) * height * 0.5 * rough
			h += (worldgenerator_noise(x, z, 8, seed, salt_bump) - 0.5) * height * 0.25 * rough
			h += (worldgenerator_noise(x, z, 4, seed, salt_detail) - 0.5) * height * 0.15 * rough
			h = round(h)
			if (trees)
				h = min(h, height - 9)
			heights[z * size + x] = clamp(h, 2, height - 1)
		}
	}
	
	// Blocks (BlockData index order: vertical * size * size + depth * size + width)
	var blocks, total, type, idx;
	total = size * size * height
	blocks = array()
	for (i = 0; i < total; i++)
		blocks[i] = 0
	
	for (x = 0; x < size; x++)
	{
		for (z = 0; z < size; z++)
		{
			h = heights[z * size + x]
			for (y = 0; y < h; y++)
			{
				if (y < h - 3)
					type = 1
				else if (y < h - 1)
					type = (h <= water_level + 1 ? 4 : 2)
				else
					type = (h <= water_level + 1 ? 4 : 3)
				
				if (pal[type] < 0)
					type = 0
				blocks[y * size * size + z * size + x] = pal[type]
			}
			
			// Fill up to the water level with water
			if (water)
			{
				for (y = h; y < water_level; y++)
					blocks[y * size * size + z * size + x] = pal[5]
			}
		}
	}
	
	// Trees: one candidate per jittered 6 x 6 cell, never in or near water
	var trunk, top, lx, lz;
	if (trees)
	{
		for (x = 0; x < size; x += 6)
		{
			for (z = 0; z < size; z += 6)
			{
				if (worldgenerator_mc_value(seed, x + 3, z + 3, salt_tree) > 0.5)
					continue
				
				var tx, tz;
				tx = x + 1 + floor(worldgenerator_mc_value(seed, x, z, salt_treex) * 4)
				tz = z + 1 + floor(worldgenerator_mc_value(seed, x, z, salt_treez) * 4)
				if (tx < 2 || tx > size - 3 || tz < 2 || tz > size - 3)
					continue
				
				h = heights[tz * size + tx]
				if (h <= water_level + 1)
					continue
				
				trunk = 4 + floor(worldgenerator_mc_value(seed, tx, tz, salt_trunk) * 3)
				top = h + trunk - 1
				
				// Trunk
				for (y = h; y <= top; y++)
					blocks[y * size * size + tz * size + tx] = pal[6]
				
				// Leaf blob: two wide layers, a smaller one on top
				for (lx = -2; lx <= 2; lx++)
				{
					for (lz = -2; lz <= 2; lz++)
					{
						for (y = top - 1; y <= top; y++)
						{
							idx = y * size * size + (tz + lz) * size + tx + lx
							if (blocks[idx] = 0 && (abs(lx) < 2 || abs(lz) < 2 || worldgenerator_mc_value(seed, tx + lx * 3 + y, tz + lz * 3, salt_leaf) >= 0.5))
								blocks[idx] = pal[7]
						}
					}
				}
				for (lx = -1; lx <= 1; lx++)
				{
					for (lz = -1; lz <= 1; lz++)
					{
						idx = (top + 1) * size * size + (tz + lz) * size + tx + lx
						if (blocks[idx] = 0 && (lx = 0 || lz = 0))
							blocks[idx] = pal[7]
					}
				}
				idx = (top + 2) * size * size + tz * size + tx
				if (blocks[idx] = 0)
					blocks[idx] = pal[7]
			}
		}
	}
	
	// Write the uncompressed .schematic (big-endian NBT): a root
	// compound named "Schematic" holding Width/Length/Height (short),
	// Version (int, 1), Palette (compound, name -> index) and BlockData
	// (byte array, one palette index per block). The loader reads the
	// root tag's name as the map key, so the root itself must be named
	// "Schematic" (classic MCEdit layout)
	var folder, fn, bf;
	folder = project_folder + "/Generated worlds"
	directory_create_lib(folder)
	fn = folder + "/generated-world-" + worldgenerator_mc_seed_string(seed) + "-" + string(size) + "x" + string(size) + "x" + string(height) + "-r" + string(roughpct) + (trees ? "-trees" : "") + (water ? "-water" : "") + ".schematic"
	
	bf = buffer_create(total + 2048, buffer_grow, 1)
	
	// Root compound header, named "Schematic"
	worldgenerator_write_byte(bf, 10)
	worldgenerator_write_string_nbt(bf, "Schematic")
	worldgenerator_write_byte(bf, 2)
	worldgenerator_write_string_nbt(bf, "Width")
	worldgenerator_write_short_be(bf, size)
	worldgenerator_write_byte(bf, 2)
	worldgenerator_write_string_nbt(bf, "Length")
	worldgenerator_write_short_be(bf, size)
	worldgenerator_write_byte(bf, 2)
	worldgenerator_write_string_nbt(bf, "Height")
	worldgenerator_write_short_be(bf, height)
	worldgenerator_write_byte(bf, 3)
	worldgenerator_write_string_nbt(bf, "Version")
	worldgenerator_write_int_be(bf, 1)
	
	// Palette compound
	worldgenerator_write_byte(bf, 10)
	worldgenerator_write_string_nbt(bf, "Palette")
	for (i = 0; i < 8; i++)
	{
		if (pal_written[i])
		{
			worldgenerator_write_byte(bf, 3)
			worldgenerator_write_string_nbt(bf, pal_names[i])
			worldgenerator_write_int_be(bf, pal[i])
		}
	}
	worldgenerator_write_byte(bf, 0)
	
	// BlockData byte array
	worldgenerator_write_byte(bf, 7)
	worldgenerator_write_string_nbt(bf, "BlockData")
	worldgenerator_write_int_be(bf, total)
	for (i = 0; i < total; i++)
		worldgenerator_write_byte(bf, blocks[i])
	
	// Close the root compound
	worldgenerator_write_byte(bf, 0)
	
	buffer_save(bf, fn)
	buffer_delete(bf)
	
	if (!file_exists_lib(fn))
	{
		toast_new(e_toast.NEGATIVE, text_get("worldgeneratorfail"))
		return false
	}
	
	// Load it in as a new scenery on the workbench (same flow as
	// browsing for a .schematic file, undo restores the previous bench
	// scenery)
	var res;
	res = new_res(fn, e_res_type.SCENERY)
	if (res.replaced)
	{
		res_edit = res
		action_res_replace(fn)
	}
	else
	{
		history_set_res(action_bench_scenery, fn, bench_settings.scenery, res)
		with (res)
			res_load()
		bench_settings.scenery = res
		bench_settings.preview.update = true
	}
	
	toast_new(e_toast.POSITIVE, text_get("worldgeneratorgenerated", size, size, height, worldgenerator_mc_seed_string(seed)))
	log("World generator: seed", worldgenerator_mc_seed_string(seed), seedstr != "" ? seedstr : "random", "size", string(size) + "x" + string(size) + "x" + string(height))
	
	return true
}

/// worldgenerator_mc_seed(seed)
/// @arg seed
/// @desc Turns the seed text into a 48-bit world seed exactly the way
/// Minecraft does: a plain (optionally negative) number that fits in a
/// signed 64-bit long is used as-is, anything else is hashed with Java's
/// String.hashCode, and an empty seed rolls a fresh random seed. Only
/// the low 48 bits are kept - that is all java.util.Random's 48-bit LCG
/// state ever looks at, so the random streams match Java exactly while
/// every step stays a small, exactly representable double (no 64-bit
/// math needed anywhere, keeping it lightweight for Mine-imator).

function worldgenerator_mc_seed(str)
{
	var first, digits, sign, isnum, h, d, i, c, k, below, above, maxstr;
	
	// Empty seed = a fresh random one, like Minecraft's world creation
	if (str = "")
		return worldgenerator_mc_random_seed()
	
	// Optional sign
	first = string_char_at(str, 1)
	sign = 1
	digits = str
	if (first = "-" || first = "+")
	{
		digits = string_delete(str, 1, 1)
		if (first = "-")
			sign = -1
	}
	
	// Strip leading zeros
	while (string_length(digits) > 1 && string_char_at(digits, 1) = "0")
		digits = string_delete(digits, 1, 1)
	
	// A number seed only if what is left is 1 - 19 digits (Minecraft
	// falls back to the text hash when the number does not fit in a
	// signed 64-bit long)
	isnum = string_length(digits) > 0
	for (i = 1; i <= string_length(digits) && isnum; i++)
	{
		c = ord(string_char_at(digits, i))
		if (c < 48 || c > 57)
			isnum = false
	}
	if (isnum && string_length(digits) > 19)
		isnum = false
	
	if (isnum)
	{
		// Parse the digits modulo 2^48 (each step stays exact in a double)
		h = 0
		for (i = 1; i <= string_length(digits); i++)
		{
			d = ord(string_char_at(digits, i)) - 48
			h = (h * 10 + d) mod 281474976710656
		}
		
		// 19 digits: reject anything above the signed 64-bit range.
		// Equal-length digit strings compare numerically char by char,
		// and Java's parseLong accepts exactly -9223372036854775808 too
		if (string_length(digits) = 19)
		{
			maxstr = sign < 0 ? "9223372036854775808" : "9223372036854775807"
			below = false
			above = false
			for (k = 1; k <= 19; k++)
			{
				d = ord(string_char_at(digits, k))
				c = ord(string_char_at(maxstr, k))
				if (d < c)
				{
					below = true
					break
				}
				else if (d > c)
				{
					above = true
					break
				}
			}
			if (above)
				isnum = false
		}
		
		if (isnum)
		{
			// Two's complement of the low 48 bits for negative seeds
			if (sign < 0 && h != 0)
				h = 281474976710656 - h
			return h
		}
	}
	
	// Text seed: Java's String.hashCode (32-bit int), sign-extended
	// into the 48-bit LCG domain
	h = 0
	for (i = 1; i <= string_length(str); i++)
		h = (h * 31 + ord(string_char_at(str, i))) mod 4294967296
	if (h >= 2147483648)
		h = (h + 281470681743360) mod 281474976710656
	return h
}

/// worldgenerator_mc_random_seed()
/// @desc Rolls a fresh random 48-bit seed. Two 24-bit rolls keep every
/// step exact in Mine-imator's double-precision numbers.

function worldgenerator_mc_random_seed()
{
	return irandom_range(0, 16777215) * 16777216 + irandom_range(0, 16777215)
}

/// worldgenerator_mc_seed_string(seed)
/// @arg seed
/// @desc Formats a 48-bit seed the way Minecraft displays seeds: values
/// with the top bit set are shown as negative numbers.

function worldgenerator_mc_seed_string(seed)
{
	if (seed >= 140737488355328)
		return string(seed - 281474976710656)
	return string(seed)
}

/// worldgenerator_mc_xor48(a, b)
/// @arg a
/// @arg b
/// @desc Bitwise XOR of two 48-bit numbers, done with plain arithmetic
/// (GML has no bitwise operators). Used for java.util.Random's seed
/// scrambling. Both inputs must be in 0 .. 2^48 - 1.

function worldgenerator_mc_xor48(a, b)
{
	var r, p, i;
	r = 0
	p = 1
	for (i = 0; i < 48; i++)
	{
		if ((a mod 2) != (b mod 2))
			r += p
		a = floor(a / 2)
		b = floor(b / 2)
		p = p * 2
	}
	return r
}

/// worldgenerator_mc_lcg(state)
/// @arg state
/// @desc One step of java.util.Random's LCG:
/// state = (state * 0x5DEECE66D + 0xB) mod 2^48. The multiplication is
/// split into 24-bit halves so every intermediate stays an exactly
/// representable double - the full 64-bit math is never needed.

function worldgenerator_mc_lcg(state)
{
	var s1, s0;
	s1 = floor(state / 16777216)
	s0 = state mod 16777216
	// 25214903917 = 1502 * 2^24 + 15525485
	return (((s1 * 15525485 + s0 * 1502) mod 16777216) * 16777216 + s0 * 15525485 + 11) mod 281474976710656
}

/// worldgenerator_mc_value(seed, x, z, salt)
/// @arg seed
/// @arg x
/// @arg z
/// @arg salt
/// @desc A deterministic random value in 0 - 1 for a position, drawn
/// from Minecraft's seed engine: java.util.Random is seeded exactly like
/// Minecraft's worldgen feature placement
/// (setSeed(worldSeed + x * 341873128712 + z * 132897987541 + salt)) and
/// its first nextDouble() is returned. The same seed gives the same
/// value on every machine, and different seeds give completely
/// different worlds.

function worldgenerator_mc_value(seed, x, z, salt)
{
	var s, hi, lo;
	s = (seed + x * 341873128712 + z * 132897987541 + salt) mod 281474976710656
	if (s < 0)
		s += 281474976710656
	// setSeed's scramble: seed ^ 0x5DEECE66D, on the low 48 bits
	s = worldgenerator_mc_xor48(s, 25214903917)
	// nextDouble(): the top 26 bits and then the top 27 bits of two LCG
	// steps, as a 53-bit fraction
	s = worldgenerator_mc_lcg(s)
	hi = floor(s / 4194304)
	s = worldgenerator_mc_lcg(s)
	lo = floor(s / 2097152)
	return (hi * 134217728 + lo) / 9007199254740992
}

/// worldgenerator_noise(x, z, cell, seed, salt)
/// @arg x
/// @arg z
/// @arg cell
/// @arg seed
/// @arg salt
/// @desc Smooth (bilinear with smoothstep) value noise: Minecraft-seeded
/// random values on a grid with the given cell size, faded in between.
/// Returns 0 - 1.

function worldgenerator_noise(x, z, cell, seed, salt)
{
	var fx, fz, x0, z0, x1, z1, tx, tz, n00, n10, n01, n11, a, b;
	fx = x / cell
	fz = z / cell
	x0 = floor(fx)
	z0 = floor(fz)
	x1 = x0 + 1
	z1 = z0 + 1
	tx = fx - x0
	tz = fz - z0
	tx = tx * tx * (3 - 2 * tx)
	tz = tz * tz * (3 - 2 * tz)
	n00 = worldgenerator_mc_value(seed, x0, z0, salt)
	n10 = worldgenerator_mc_value(seed, x1, z0, salt)
	n01 = worldgenerator_mc_value(seed, x0, z1, salt)
	n11 = worldgenerator_mc_value(seed, x1, z1, salt)
	a = n00 + (n10 - n00) * tx
	b = n01 + (n11 - n01) * tx
	return a + (b - a) * tz
}

/// worldgenerator_write_byte(buffer, value)
/// @arg buffer
/// @arg value

function worldgenerator_write_byte(bf, val)
{
	buffer_write(bf, buffer_u8, val)
}

/// worldgenerator_write_short_be(buffer, value)
/// @arg buffer
/// @arg value
/// @desc Writes a 16-bit big-endian integer (NBT number format).

function worldgenerator_write_short_be(bf, val)
{
	buffer_write(bf, buffer_u8, (val - val mod 256) / 256)
	buffer_write(bf, buffer_u8, val mod 256)
}

/// worldgenerator_write_int_be(buffer, value)
/// @arg buffer
/// @arg value
/// @desc Writes a 32-bit big-endian integer (NBT number format).

function worldgenerator_write_int_be(bf, val)
{
	buffer_write(bf, buffer_u8, (val - val mod 16777216) / 16777216)
	val = val mod 16777216
	buffer_write(bf, buffer_u8, (val - val mod 65536) / 65536)
	val = val mod 65536
	buffer_write(bf, buffer_u8, (val - val mod 256) / 256)
	buffer_write(bf, buffer_u8, val mod 256)
}

/// worldgenerator_write_string_nbt(buffer, string)
/// @arg buffer
/// @arg string
/// @desc Writes an NBT string: 16-bit big-endian length, then the bytes.

function worldgenerator_write_string_nbt(bf, str)
{
	var i;
	worldgenerator_write_short_be(bf, string_length(str))
	for (i = 1; i <= string_length(str); i++)
		worldgenerator_write_byte(bf, ord(string_char_at(str, i)))
}
