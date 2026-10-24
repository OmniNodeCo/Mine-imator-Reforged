/// action_worldgenerator_generate()
/// @desc World generator: builds a random blocky landscape (layered hills,
/// caves with ore veins, optional water and trees) from the seed and
/// settings in the world generator popup, writes it as an uncompressed
/// Sponge v1 .schematic NBT file next to the project and loads it in as a
/// new scenery on the workbench. Seeds run through Minecraft's seed engine
/// (see worldgenerator_mc_seed) plus one decorrelating LCG step, so nearby
/// numeric seeds no longer come out as near-identical worlds: the same
/// seed text always produces the same world, and an empty seed field rolls
/// a fresh random seed every time. Blocks that the current texture pack
/// does not know are swapped for similar ones (or their feature is
/// skipped), so the generator works with any pack.

function action_worldgenerator_generate()
{
	var size, height, rough, roughpct, trees, water, caves, seedstr, seed, wseed;
	
	// Settings (textboxes accept expressions)
	size = clamp(round(eval(popup_worldgenerator.tbx_size.text, 64)), 8, 96)
	height = clamp(round(eval(popup_worldgenerator.tbx_height.text, 48)), 8, 64)
	roughpct = clamp(round(eval(popup_worldgenerator.tbx_roughness.text, 50)), 0, 100)
	rough = roughpct / 100
	trees = popup_worldgenerator.trees
	water = popup_worldgenerator.water
	caves = popup_worldgenerator.caves
	seedstr = popup_worldgenerator.tbx_seed.text
	seed = worldgenerator_mc_seed(seedstr)
	// One LCG step before any use: the raw seed enters the position
	// hashes additively, so seeds only a few numbers apart (3 and 5, or
	// 1 and -1) used to come out as near-identical worlds
	wseed = worldgenerator_mc_scramble(seed)
	
	// Feature salts: separate salt offsets keep every feature on its own
	// random stream. They are spaced a million apart on purpose - the
	// seed engine's scrambling does not decorrelate small salt
	// differences, so salts a few numbers apart would make those
	// features place on the same spots (the swamp hut salt 14357620 is
	// kept as the origin of the numbering)
	var salt_hill, salt_bump, salt_detail, salt_tree, salt_treex, salt_treez, salt_trunk, salt_leaf;
	var salt_cave1, salt_cave2, salt_cave3, salt_bedrock, salt_spruce;
	salt_hill = 14357617
	salt_bump = 15357617
	salt_detail = 16357617
	salt_tree = 17357617
	salt_treex = 18357617
	salt_treez = 19357617
	salt_trunk = 20357617
	salt_leaf = 21357617
	salt_cave1 = 22357617
	salt_cave2 = 23357617
	salt_cave3 = 24357617
	salt_bedrock = 25357617
	salt_spruce = 36357617
	var off;
	off = 1000000
	
	// Palette: look up which blocks the current texture pack knows
	// 0 air, 1 stone, 2 dirt, 3 grass, 4 sand, 5 water, 6 oak log, 7 oak leaves,
	// 8 gravel, 9 andesite, 10 granite, 11 diorite, 12 sandstone, 13 bedrock,
	// 14 snow, 15 coal, 16 iron, 17 gold, 18 redstone, 19 lapis, 20 diamond,
	// 21 spruce log, 22 spruce leaves
	var pal_names, pal, pal_written, nextidx, i;
	pal_names = array("minecraft:air", "minecraft:stone", "minecraft:dirt", "minecraft:grass_block", "minecraft:sand", "minecraft:water", "minecraft:oak_log", "minecraft:oak_leaves", "minecraft:gravel", "minecraft:andesite", "minecraft:granite", "minecraft:diorite", "minecraft:sandstone", "minecraft:bedrock", "minecraft:snow_block", "minecraft:coal_ore", "minecraft:iron_ore", "minecraft:gold_ore", "minecraft:redstone_ore", "minecraft:lapis_ore", "minecraft:diamond_ore", "minecraft:spruce_log", "minecraft:spruce_leaves")
	pal = array()
	pal_written = array()
	nextidx = 0
	for (i = 0; i < 23; i++)
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
	// Missing core blocks fall back to a similar one; the extra blocks
	// (variants, ores, sandstone, bedrock, snow, spruce) simply skip
	// their feature when the pack does not know them
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
			h += (worldgenerator_noise(x, z, 16, wseed, salt_hill) - 0.5) * height * 0.5 * rough
			h += (worldgenerator_noise(x, z, 8, wseed, salt_bump) - 0.5) * height * 0.25 * rough
			h += (worldgenerator_noise(x, z, 4, wseed, salt_detail) - 0.5) * height * 0.15 * rough
			h = round(h)
			if (trees)
				h = min(h, height - 9)
			heights[z * size + x] = clamp(h, 2, height - 1)
		}
	}
	
	// Blocks (BlockData index order: vertical * size * size + depth * size + width)
	var blocks, total, type, idx, beach, bt;
	total = size * size * height
	blocks = array()
	for (i = 0; i < total; i++)
		blocks[i] = 0
	
	for (x = 0; x < size; x++)
	{
		for (z = 0; z < size; z++)
		{
			h = heights[z * size + x]
			beach = h <= water_level + 1
			for (y = 0; y < h; y++)
			{
				// Bedrock floor with Minecraft's noisy edge (the same
				// random draw feeds the y = 1 and y = 2 layers)
				if (y = 0)
					type = (pal[13] >= 0 ? 13 : 1)
				else if (y = 1 && pal[13] >= 0 && worldgenerator_mc_value(wseed, x, z, salt_bedrock) < 0.6)
					type = 13
				else if (y = 2 && pal[13] >= 0 && worldgenerator_mc_value(wseed, x, z, salt_bedrock) < 0.25)
					type = 13
				else if (y < h - 3)
				{
					// Sandstone sits under beaches and the sea floor
					type = (beach && y >= h - 6 && pal[12] >= 0 ? 12 : 1)
				}
				else if (y < h - 1)
					type = (beach ? 4 : 2)
				else
					type = (beach ? 4 : 3)
				
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
	
	// Caves: two independent tunnel noise fields carve where both pass
	// close to 0.5 (the intersection of two thin bands is a winding
	// tunnel - Minecraft 1.18's "spaghetti" approach), plus a deeper
	// "cheese" field that opens bigger caverns the further down it is.
	// The lattices are sampled once and interpolated per block, so a
	// whole volume costs about as much as the heightmap does
	if (caves)
	{
		var gx, gy, gx2, gy2, lat_a, lat_b, lat_c, cut, va, vb, vc;
		gx = ceil(size / 8) + 2
		gy = ceil(height / 4) + 2
		gx2 = ceil(size / 16) + 2
		gy2 = ceil(height / 8) + 2
		lat_a = worldgenerator_lattice3(wseed, salt_cave1, gx, gy, gx)
		lat_b = worldgenerator_lattice3(wseed, salt_cave2, gx, gy, gx)
		lat_c = worldgenerator_lattice3(wseed, salt_cave3, gx2, gy2, gx2)
		
		for (x = 0; x < size; x++)
		{
			for (z = 0; z < size; z++)
			{
				h = heights[z * size + x]
				// Never carve at or near the water level: the water is a
				// static fill, carving underneath would leave it floating
				if (h <= water_level + 2)
					continue
				
				for (y = 1; y < h; y++)
				{
					idx = y * size * size + z * size + x
					if (blocks[idx] = pal[13]) // the bedrock floor stays
						continue
					
					cut = false
					va = worldgenerator_lerp3(lat_a, gx, gy, gx, x, y, z, 8, 4, 8)
					if (abs(va - 0.5) < 0.05)
					{
						vb = worldgenerator_lerp3(lat_b, gx, gy, gx, x, y, z, 8, 4, 8)
						cut = abs(vb - 0.5) < 0.05
					}
					if (!cut && y <= h - 7)
					{
						vc = worldgenerator_lerp3(lat_c, gx2, gy2, gx2, x, y, z, 16, 8, 16)
						cut = vc > 0.74 + 0.16 * y / height
					}
					if (cut)
						blocks[idx] = pal[0]
				}
			}
		}
	}
	
	// Snow caps on the highest terrain, with spruces instead of oaks
	var hmax, snowline, snowy;
	hmax = 0
	for (i = 0; i < size * size; i++)
	{
		if (heights[i] > hmax)
			hmax = heights[i]
	}
	snowline = height
	if (hmax - water_level >= 14 && pal[14] >= 0)
		snowline = water_level + floor((hmax - water_level) * 0.68)
	for (x = 0; x < size; x++)
	{
		for (z = 0; z < size; z++)
		{
			h = heights[z * size + x]
			if (h >= snowline)
			{
				for (y = h - 2; y <= h - 1; y++)
				{
					idx = y * size * size + z * size + x
					bt = blocks[idx]
					if (bt = pal[1] || bt = pal[2] || bt = pal[3])
						blocks[idx] = pal[14]
				}
			}
		}
	}
	
	// Stone variety and ores, placed like Minecraft's features: one
	// attempt per feature per 8 x 8 cell, ellipsoid blobs for gravel /
	// andesite / granite / diorite and random-walk veins for the ores,
	// both only ever replacing stone-family blocks
	var vtypes, vsalts, cx, cz, cellid, vi, vt, bx, bz, by, hcol, rx, ry, rz, dx, dy, dz, px, py, pz;
	var otypes, oatt, oprob, oymin, oymax, onmin, onmax, osalts, oi, ot, at, vx, vy, vz, n, st, ytop;
	vtypes = array(8, 9, 10, 11)
	vsalts = array(26357617, 27357617, 28357617, 29357617)
	otypes = array(15, 16, 17, 18, 19, 20)
	oatt = array(3, 2, 1, 1, 1, 1)
	oprob = array(1, 1, 0.30, 0.40, 0.22, 0.15)
	oymin = array(4, 2, 2, 2, 2, 2)
	oymax = array(height - 8, floor(height * 0.55), 16, 14, 16, 12)
	onmin = array(6, 4, 3, 4, 3, 2)
	onmax = array(10, 6, 5, 6, 5, 4)
	osalts = array(30357617, 31357617, 32357617, 33357617, 34357617, 35357617)
	for (cx = 0; cx < ceil(size / 8); cx++)
	{
		for (cz = 0; cz < ceil(size / 8); cz++)
		{
			cellid = cx * 64 + cz
			
			// Blobs: gravel, andesite, granite, diorite
			for (vi = 0; vi < 4; vi++)
			{
				vt = vtypes[vi]
				if (pal[vt] < 0)
					continue
				if (worldgenerator_mc_value(wseed, cx, cz, vsalts[vi]) >= 0.42)
					continue
				bx = cx * 8 + floor(worldgenerator_mc_value(wseed, cx, cz, vsalts[vi] + off) * 8)
				bz = cz * 8 + floor(worldgenerator_mc_value(wseed, cx, cz, vsalts[vi] + off * 2) * 8)
				if (bx >= size || bz >= size)
					continue
				hcol = heights[bz * size + bx]
				if (hcol < 10)
					continue
				by = 3 + floor(worldgenerator_mc_value(wseed, cx, cz, vsalts[vi] + off * 3) * (hcol - 9))
				rx = 2 + floor(worldgenerator_mc_value(wseed, cx, cz, vsalts[vi] + off * 4) * 2)
				ry = 1 + floor(worldgenerator_mc_value(wseed, cx, cz, vsalts[vi] + off * 5) * 2)
				rz = 2 + floor(worldgenerator_mc_value(wseed, cx, cz, vsalts[vi] + off * 6) * 2)
				for (dx = -rx; dx <= rx; dx++)
				{
					for (dy = -ry; dy <= ry; dy++)
					{
						for (dz = -rz; dz <= rz; dz++)
						{
							px = bx + dx
							py = by + dy
							pz = bz + dz
							if (px < 0 || px >= size || pz < 0 || pz >= size || py < 1 || py >= height - 1)
								continue
							if (dx * dx / (rx * rx) + dy * dy / (ry * ry) + dz * dz / (rz * rz) > 1)
								continue
							if (worldgenerator_mc_value(wseed, px * 3 + dy, pz * 3 - dy, vsalts[vi]) < 0.72)
							{
								idx = py * size * size + pz * size + px
								bt = blocks[idx]
								if (bt = pal[1] || bt = pal[9] || bt = pal[10] || bt = pal[11])
									blocks[idx] = pal[vt]
							}
						}
					}
				}
			}
			
			// Ore veins: coal, iron, gold, redstone, lapis, diamond
			for (oi = 0; oi < 6; oi++)
			{
				ot = otypes[oi]
				if (pal[ot] < 0)
					continue
				for (at = 0; at < oatt[oi]; at++)
				{
					if (worldgenerator_mc_value(wseed, cellid + at * 17, oi, osalts[oi]) >= oprob[oi])
						continue
					vx = cx * 8 + floor(worldgenerator_mc_value(wseed, cellid + at * 17, oi + 50, osalts[oi]) * 8)
					vz = cz * 8 + floor(worldgenerator_mc_value(wseed, cellid + at * 17, oi + 60, osalts[oi]) * 8)
					if (vx >= size || vz >= size)
						continue
					hcol = heights[vz * size + vx]
					ytop = min(oymax[oi], min(height - 6, hcol - 5))
					vy = oymin[oi] + floor(worldgenerator_mc_value(wseed, cellid + at * 17, oi + 70, osalts[oi]) * max(1, ytop - oymin[oi] + 1))
					n = onmin[oi] + floor(worldgenerator_mc_value(wseed, cellid + at * 17, oi + 80, osalts[oi]) * (onmax[oi] - onmin[oi] + 1))
					for (st = 0; st < n; st++)
					{
						if (vx >= 0 && vx < size && vz >= 0 && vz < size && vy >= 1 && vy < height - 1)
						{
							idx = vy * size * size + vz * size + vx
							bt = blocks[idx]
							if (bt = pal[1] || bt = pal[9] || bt = pal[10] || bt = pal[11])
								blocks[idx] = pal[ot]
						}
						vx = clamp(vx + floor(worldgenerator_mc_value(wseed, cellid * 13 + st * 3, oi * 7 + 1, osalts[oi]) * 3) - 1, 0, size - 1)
						vy = clamp(vy + floor(worldgenerator_mc_value(wseed, cellid * 13 + st * 3, oi * 7 + 2, osalts[oi]) * 3) - 1, 1, height - 2)
						vz = clamp(vz + floor(worldgenerator_mc_value(wseed, cellid * 13 + st * 3, oi * 7 + 3, osalts[oi]) * 3) - 1, 0, size - 1)
					}
				}
			}
		}
	}
	
	// Trees: one candidate per jittered 6 x 6 cell, never in or near
	// water, never over a cave entrance; snowy peaks grow spruces
	var trunk, top, lx, lz;
	if (trees)
	{
		for (x = 0; x < size; x += 6)
		{
			for (z = 0; z < size; z += 6)
			{
				if (worldgenerator_mc_value(wseed, x + 3, z + 3, salt_tree) > 0.5)
					continue
				
				var tx, tz;
				tx = x + 1 + floor(worldgenerator_mc_value(wseed, x, z, salt_treex) * 4)
				tz = z + 1 + floor(worldgenerator_mc_value(wseed, x, z, salt_treez) * 4)
				if (tx < 2 || tx > size - 3 || tz < 2 || tz > size - 3)
					continue
				
				h = heights[tz * size + tx]
				if (h <= water_level + 1)
					continue
				if (blocks[(h - 1) * size * size + tz * size + tx] = pal[0])
					continue
				
				snowy = h >= snowline
				if (snowy && pal[21] >= 0 && pal[22] >= 0)
				{
					// Spruce: taller trunk, conical leaf crown
					trunk = 5 + floor(worldgenerator_mc_value(wseed, tx, tz, salt_spruce) * 3)
					top = h + trunk - 1
					
					for (y = h; y <= top; y++)
						blocks[y * size * size + tz * size + tx] = pal[21]
					
					for (lx = -2; lx <= 2; lx++)
					{
						for (lz = -2; lz <= 2; lz++)
						{
							for (y = top - 3; y <= top + 1; y++)
							{
								if (y >= height)
									continue
								var rr;
								rr = 1
								if (y <= top - 2)
									rr = 2
								else if (y = top + 1)
									rr = 0
								if (abs(lx) > rr || abs(lz) > rr)
									continue
								if (lx = 0 && lz = 0 && y <= top)
									continue
								if (rr = 1 && y = top && abs(lx) = 1 && abs(lz) = 1)
									continue
								if (rr = 2 && abs(lx) = 2 && abs(lz) = 2 && worldgenerator_mc_value(wseed, tx + lx * 3 + y, tz + lz * 3, salt_leaf) < 0.5)
									continue
								idx = y * size * size + (tz + lz) * size + tx + lx
								if (blocks[idx] = pal[0])
									blocks[idx] = pal[22]
							}
						}
					}
				}
				else
				{
					// Oak: the classic blob
					trunk = 4 + floor(worldgenerator_mc_value(wseed, tx, tz, salt_trunk) * 3)
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
								if (blocks[idx] = pal[0] && (abs(lx) < 2 || abs(lz) < 2 || worldgenerator_mc_value(wseed, tx + lx * 3 + y, tz + lz * 3, salt_leaf) >= 0.5))
									blocks[idx] = pal[7]
							}
						}
					}
					for (lx = -1; lx <= 1; lx++)
					{
						for (lz = -1; lz <= 1; lz++)
						{
							idx = (top + 1) * size * size + (tz + lz) * size + tx + lx
							if (blocks[idx] = pal[0] && (lx = 0 || lz = 0))
								blocks[idx] = pal[7]
						}
					}
					idx = (top + 2) * size * size + tz * size + tx
					if (blocks[idx] = pal[0])
						blocks[idx] = pal[7]
				}
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
	fn = folder + "/generated-world-" + worldgenerator_mc_seed_string(seed) + "-" + string(size) + "x" + string(size) + "x" + string(height) + "-r" + string(roughpct) + (trees ? "-trees" : "") + (water ? "-water" : "") + (caves ? "-caves" : "") + ".schematic"
	
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
	for (i = 0; i < 23; i++)
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
	log("World generator: seed", worldgenerator_mc_seed_string(seed), seedstr != "" ? string(seedstr) : "random", "size", string(size) + "x" + string(size) + "x" + string(height), caves ? "caves" : "no caves")
	
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

/// worldgenerator_mc_scramble(seed)
/// @arg seed
/// @desc Runs a 48-bit seed through setSeed's XOR scrambling and one LCG
/// step, the exact transition java.util.Random makes between setSeed and
/// the first nextDouble. The world generator hashes block positions by
/// adding the seed, so two seeds a few numbers apart (3 and 5, or 1 and
/// -1) survive the scrambling as near-identical random streams and used
/// to come out as near-identical worlds - this step decorrelates them.

function worldgenerator_mc_scramble(seed)
{
	return worldgenerator_mc_lcg(worldgenerator_mc_xor48(seed, 25214903917))
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

/// worldgenerator_mc_value3(seed, x, y, z, salt)
/// @arg seed
/// @arg x
/// @arg y
/// @arg z
/// @arg salt
/// @desc The 3D counterpart of worldgenerator_mc_value: a deterministic
/// random value in 0 - 1 for a block position, with the y axis mixed in
/// through its own large multiplier (668268263) in the same style the
/// feature salts mix x and z. Used for the cave noise lattices.

function worldgenerator_mc_value3(seed, x, y, z, salt)
{
	var s, hi, lo;
	s = (seed + x * 341873128712 + z * 132897987541 + y * 668268263 + salt) mod 281474976710656
	if (s < 0)
		s += 281474976710656
	s = worldgenerator_mc_xor48(s, 25214903917)
	s = worldgenerator_mc_lcg(s)
	hi = floor(s / 4194304)
	s = worldgenerator_mc_lcg(s)
	lo = floor(s / 2097152)
	return (hi * 134217728 + lo) / 9007199254740992
}

/// worldgenerator_lattice3(seed, salt, gx, gy, gz)
/// @arg seed
/// @arg salt
/// @arg gx
/// @arg gy
/// @arg gz
/// @desc Fills a gx x gy x gz lattice of Minecraft-seeded random values
/// for 3D value noise (index order: (j * gz + k) * gx + i, matching
/// worldgenerator_lerp3). Sampling the lattice once and interpolating
/// per block keeps whole-volume noise about as cheap as the heightmap.

function worldgenerator_lattice3(seed, salt, gx, gy, gz)
{
	var lat, i, j, k;
	lat = array()
	for (k = 0; k < gz; k++)
	{
		for (j = 0; j < gy; j++)
		{
			for (i = 0; i < gx; i++)
				lat[(j * gz + k) * gx + i] = worldgenerator_mc_value3(seed, i, j, k, salt)
		}
	}
	return lat
}

/// worldgenerator_lerp3(lat, gx, gy, gz, x, y, z, cellx, cely, cellz)
/// @arg lat
/// @arg gx
/// @arg gy
/// @arg gz
/// @arg x
/// @arg y
/// @arg z
/// @arg cellx
/// @arg cely
/// @arg cellz
/// @desc Trilinear interpolation with smoothstep fading, sampling a
/// lattice filled by worldgenerator_lattice3 at world position x, y, z
/// with the given cell sizes. Returns 0 - 1.

function worldgenerator_lerp3(lat, gx, gy, gz, x, y, z, cellx, cely, cellz)
{
	var fx, fy, fz, i0, j0, k0, i1, j1, k1, tx, ty, tz;
	var c00, c10, c01, c11, c0, c1;
	fx = x / cellx
	fy = y / cely
	fz = z / cellz
	i0 = floor(fx)
	j0 = floor(fy)
	k0 = floor(fz)
	tx = fx - i0
	ty = fy - j0
	tz = fz - k0
	tx = tx * tx * (3 - 2 * tx)
	ty = ty * ty * (3 - 2 * ty)
	tz = tz * tz * (3 - 2 * tz)
	i1 = i0 + 1
	j1 = j0 + 1
	k1 = k0 + 1
	if (i1 >= gx)
		i1 = gx - 1
	if (j1 >= gy)
		j1 = gy - 1
	if (k1 >= gz)
		k1 = gz - 1
	c00 = lat[(j0 * gz + k0) * gx + i0] + (lat[(j0 * gz + k0) * gx + i1] - lat[(j0 * gz + k0) * gx + i0]) * tx
	c10 = lat[(j1 * gz + k0) * gx + i0] + (lat[(j1 * gz + k0) * gx + i1] - lat[(j1 * gz + k0) * gx + i0]) * tx
	c01 = lat[(j0 * gz + k1) * gx + i0] + (lat[(j0 * gz + k1) * gx + i1] - lat[(j0 * gz + k1) * gx + i0]) * tx
	c11 = lat[(j1 * gz + k1) * gx + i0] + (lat[(j1 * gz + k1) * gx + i1] - lat[(j1 * gz + k1) * gx + i0]) * tx
	c0 = c00 + (c10 - c00) * ty
	c1 = c01 + (c11 - c01) * ty
	return c0 + (c1 - c0) * tz
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
