/// action_worldgenerator_generate()
/// @desc World generator: builds a random blocky landscape (layered hills,
/// optional water and trees) from the seed and settings in the world
/// generator popup, writes it as an uncompressed Sponge v1 .schematic NBT
/// file next to the project and loads it in as a new scenery on the
/// workbench. The same seed and settings always produce the same world.
/// Blocks that the current texture pack does not know are swapped for
/// similar ones, so the generator works with any pack.

function action_worldgenerator_generate()
{
	var size, height, rough, trees, water, seedstr, seed;
	
	// Settings (textboxes accept expressions)
	size = clamp(round(eval(popup_worldgenerator.tbx_size.text, 64)), 8, 96)
	height = clamp(round(eval(popup_worldgenerator.tbx_height.text, 48)), 8, 64)
	rough = clamp(eval(popup_worldgenerator.tbx_roughness.text, 50), 0, 100) / 100
	trees = popup_worldgenerator.trees
	water = popup_worldgenerator.water
	seedstr = popup_worldgenerator.tbx_seed.text
	seed = worldgenerator_seed_hash(seedstr)
	
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
			h += (worldgenerator_noise(x, z, 16, seed) - 0.5) * height * 0.5 * rough
			h += (worldgenerator_noise(x, z, 8, seed + 51) - 0.5) * height * 0.25 * rough
			h += (worldgenerator_noise(x, z, 4, seed + 97) - 0.5) * height * 0.15 * rough
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
				if (worldgenerator_hash(x + 3, z + 3, seed + 777) > 0.5)
					continue
				
				var tx, tz;
				tx = x + 1 + floor(worldgenerator_hash(x, z, seed + 881) * 4)
				tz = z + 1 + floor(worldgenerator_hash(x, z, seed + 997) * 4)
				if (tx < 2 || tx > size - 3 || tz < 2 || tz > size - 3)
					continue
				
				h = heights[tz * size + tx]
				if (h <= water_level + 1)
					continue
				
				trunk = 4 + floor(worldgenerator_hash(tx, tz, seed + 111) * 3)
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
							if (blocks[idx] = 0 && (abs(lx) < 2 || abs(lz) < 2 || worldgenerator_hash(tx + lx * 3 + y, tz + lz * 3, seed + 222) >= 0.5))
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
	fn = folder + "/generated-world-" + string(seed) + "-" + string(size) + "x" + string(size) + "x" + string(height) + ".schematic"
	
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
	
	toast_new(e_toast.POSITIVE, text_get("worldgeneratorgenerated", size, size, height))
	log("World generator: seed", seed, "size", string(size) + "x" + string(size) + "x" + string(height))
	
	return true
}

/// worldgenerator_seed_hash(seed)
/// @arg seed
/// @desc Turns any seed text into a number (0 - 16777215).

function worldgenerator_seed_hash(str)
{
	var h, i;
	h = 1
	for (i = 1; i <= string_length(str); i++)
		h = (h * 31 + ord(string_char_at(str, i))) mod 16777216
	return h
}

/// worldgenerator_hash(x, z, seed)
/// @arg x
/// @arg z
/// @arg seed
/// @desc Deterministic hash of two coordinates and a seed, as a number
/// between 0 and 1.

function worldgenerator_hash(x, z, seed)
{
	var h;
	h = (x * 73856093 + z * 19349663 + seed * 83492791) mod 4294967296
	h = (h * 104729 + 12345) mod 4294967296
	h = (h + ((h - h mod 65536) / 65536) * 97) mod 4294967296
	h = (h * 104729 + 12345) mod 4294967296
	return h / 4294967296
}

/// worldgenerator_noise(x, z, cell, seed)
/// @arg x
/// @arg z
/// @arg cell
/// @arg seed
/// @desc Smooth (bilinear with smoothstep) value noise: random values on a
/// grid with the given cell size, faded in between. Returns 0 - 1.

function worldgenerator_noise(x, z, cell, seed)
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
	n00 = worldgenerator_hash(x0, z0, seed)
	n10 = worldgenerator_hash(x1, z0, seed)
	n01 = worldgenerator_hash(x0, z1, seed)
	n11 = worldgenerator_hash(x1, z1, seed)
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
