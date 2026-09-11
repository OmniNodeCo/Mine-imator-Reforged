#!/usr/bin/env python3
"""Generates the Rigs/ catalog: textures, model JSONs and zips.

Model JSON conventions (verified against the bundled steve.mimodel and
model_file_load*/model_shape_generate_block):
  - Arrays are Minecraft-style [x, y_up, z_forward] (the loader swaps y/z).
  - Box "uv" is the FRONT face top-left in the texture. Face rects:
      top    (u,     v-d)  w x d
      bottom (u+w,   v-d)  w x d   (v-flipped)
      right  (u-d,   v  )  d x h
      front  (u,     v  )  w x h
      left   (u+w,   v  )  d x h
      back   (u+w+d, v  )  w x h
  - A part with texture screen.png and uv [0,0] sized [w, h] shows the
    whole texture on its front face -> the video player fills the face.
  - Limbs with bend {part: "lower", axis: "x", end_offset > 0} are IK-ready.
"""
import json, os, random, zipfile
from PIL import Image, ImageDraw

random.seed(1234)
os.makedirs('Rigs', exist_ok=True)

# ---------------------------------------------------------------- helpers
def canvas(w, h):
    return Image.new('RGBA', (w, h), (0, 0, 0, 0))

def noise(img, x0, y0, w, h, base, jitter=8, alpha=255):
    x0, y0, w, h = int(x0), int(y0), int(w), int(h)
    d = ImageDraw.Draw(img)
    for yy in range(y0, y0 + h):
        for xx in range(x0, x0 + w):
            n = random.randint(-jitter, jitter)
            d.point((xx, yy), fill=tuple(max(0, min(255, c + n)) for c in base[:3]) + (alpha,))

def flat(img, x0, y0, w, h, color):
    d = ImageDraw.Draw(img)
    d.rectangle([x0, y0, x0 + w - 1, y0 + h - 1], fill=color)

def box_region(w, h, d):
    """Texture size needed for one box unwrap (region at origin)."""
    return (2 * w + 2 * d, h + d)

class TexPacker:
    """Allocates box unwrap regions side by side on one texture."""
    def __init__(self, name):
        self.name = name
        self.regions = []  # (x, y, w, h, d) region origin + box dims
        self.width = 0
        self.height = 0
    def add(self, w, h, d):
        rw, rh = box_region(w, h, d)
        x, y = self.width, 0
        self.regions.append((x, y, w, h, d))
        self.width += rw + 1
        self.height = max(self.height, rh)
        # uv = front face top-left = region origin + (d, d)
        return [x + d, y + d]
    def finish(self):
        img = canvas(self.width, max(self.height, 1))
        return img, [self.width, self.height]

def paint_faces(img, uv, w, h, d, top, bottom, right, front, left, back):
    """Paint the six face rects of a box at the given uv anchor."""
    u, v = uv
    for (x, y, rw, rh, col) in (
        (u,     v - d, w, d, top),    # top
        (u + w, v - d, w, d, bottom), # bottom
        (u - d, v,     d, h, right),  # right
        (u,     v,     w, h, front),  # front
        (u + w, v,     d, h, left),   # left
        (u+w+d, v,     w, h, back),   # back
    ):
        if col is None:
            continue
        if callable(col):
            col(img, x, y, rw, rh)
        else:
            noise(img, x, y, rw, rh, col)

def shape(from_, to, uv, **kw):
    s = {"type": "box", "from": from_, "to": to, "uv": uv}
    s.update(kw)
    return s

PROJECT_FORMAT = 35          # e_project.FORMAT_CTB_106 (project_format macro)
MATERIAL_FORMAT_LABPBR = 2   # e_material.FORMAT_LABPBR (resource default)
CREATED_IN = "2.0.2 Reforged 1.0.5"

def normalize_screen_parts(parts):
    """Makes every video-screen part sample the whole texture.

    The engine squares each part's texture grid (texture_size -> max(w,h)),
    so a non-square screen face would only show a cropped part of the video
    frame. A square noscale box spanning the full grid ([0,1] UV) plus a Y
    scale keeps the same rendered footprint while showing the full frame.
    """
    for part in parts:
        if part.get('texture', '').endswith('screen.png') and part.get('shapes'):
            s = part['shapes'][0]
            w = s['to'][0] - s['from'][0]
            h = s['to'][1] - s['from'][1]
            assert w > 0 and h > 0, part['name']
            cx = part['position'][0] + (s['from'][0] + s['to'][0]) / 2
            cy = part['position'][1] + (s['from'][1] + s['to'][1]) / 2
            s['from'] = [-w / 2, -w / 2, s['from'][2]]
            s['to'] = [w / 2, w / 2, s['to'][2]]
            part['position'] = [cx, cy, part['position'][2]]
            part['scale'] = [1, h / w, 1]
            part['texture_size'] = [w, w]
            s['uv'] = [0, 0]
        normalize_screen_parts(part.get('parts', []))

def miobject(name, member, safe):
    """Builds a .miobject (engine object save format) importing the rig's
    model resource as a library template. Verified against object_save /
    project_save_objects / project_load_objects."""
    return {
        "format": PROJECT_FORMAT,
        "created_in": CREATED_IN,
        "templates": [{
            "id": f"reftpl_{safe}",
            "type": "model",
            "name": name,
            "model": f"refres_{safe}",
            # The engine writes null references as the string "null"
            # (json_save_value quotes it, value_get_save_id converts back)
            "model_tex": "null",
            "model_tex_material": "null",
            "model_tex_normal": "null",
        }],
        "timelines": [],
        "resources": [{
            "id": f"refres_{safe}",
            "type": "model",
            "filename": member + ".mimodel",
            "material_format": MATERIAL_FORMAT_LABPBR,
        }],
    }

def write_rig(slug, model, textures):
    normalize_screen_parts(model['parts'])
    with open(f'Rigs/{slug}.json', 'w') as f:
        json.dump(model, f, indent=1)
    pack_rig(slug, model, textures)
    print(f"  {slug}.zip  ({len(textures)} textures)")

def pack_rig(slug, model, textures, jsonname=None):
    """Packs a rig zip: <name>.miobject (the importable object) +
    <name>.mimodel (the model resource) + textures. res_load() only takes
    the rig path for .mimodel files (.json falls through to the Minecraft
    block model loader), and rigs are imported as objects via .miobject."""
    if jsonname is None:
        jsonname = f'Rigs/{slug}.json'
    member = jsonname.replace('\\', '/').rsplit('/', 1)[-1][:-len('.json')]
    safe = "".join(c if c.isalnum() or c == '_' else '_' for c in member)
    with zipfile.ZipFile(f'Rigs/{slug}.zip', 'w', zipfile.ZIP_DEFLATED) as z:
        z.write(jsonname, member + '.mimodel')
        miobj = miobject(model['name'], member, safe)
        z.writestr(member + '.miobject', json.dumps(miobj, indent=1))
        for fn in textures:
            z.write(f'Rigs/{fn}', fn)

def save(img, name):
    img.save(f'Rigs/{name}')

# ---------------------------------------------------------------- 1. IK mannequin
# Exact Steve structure (positions, shapes, bends) so every limb is posable
# and IK-capable; own texture in the classic 64x64 skin layout, plus
# player_skin so any Minecraft skin can be applied to it.
def mannequin():
    img = canvas(64, 64)
    skin   = (168, 158, 142)   # warm light tan
    dark   = (120, 110, 96)
    hair   = (96, 84, 70)
    suit   = (108, 128, 158)   # blue-gray body suit
    suitd  = (88, 104, 132)
    joint  = (70, 78, 92)      # dark joint bands at bend areas
    # head (uv 8,8): front(8,8) right(0,8) left(16,8) back(24,8) top(8,0) bottom(16,0)
    for (x, y) in ((0, 8), (8, 8), (16, 8), (24, 8)):
        noise(img, x, y, 8, 8, skin)
    noise(img, 8, 0, 8, 8, hair)       # top
    noise(img, 16, 0, 8, 8, skin)      # bottom
    d = ImageDraw.Draw(img)
    # face on the front (8,8)-(16,16)
    d.rectangle([10, 11, 11, 12], fill=(40, 40, 44, 255))   # eyes
    d.rectangle([14, 11, 15, 12], fill=(40, 40, 44, 255))
    d.rectangle([11, 14, 13, 14], fill=(120, 96, 88, 255))  # mouth
    d.line([8, 8, 15, 8], fill=hair, width=2)               # hairline
    # body (uv 20,20): front(20,20)8x12 right(16,20)4x12 left(28,20) back(32,20) top(20,16) bottom(28,16)
    noise(img, 20, 20, 8, 12, suit)
    noise(img, 32, 20, 8, 12, suit)
    noise(img, 16, 20, 4, 12, suitd)
    noise(img, 28, 20, 4, 12, suitd)
    noise(img, 20, 16, 8, 4, suitd)
    noise(img, 28, 16, 8, 4, dark)
    d.rectangle([20, 26, 27, 27], fill=joint)  # waist joint band (front)
    # right arm (uv 44,20): front(44,20)4x12 right(40,20) left(48,20) back(52,20) top(44,16) bottom(48,16)
    for (x, y) in ((40, 20), (44, 20), (48, 20), (52, 20)):
        noise(img, x, y, 4, 12, skin)
    noise(img, 44, 16, 4, 4, suitd)
    noise(img, 48, 16, 4, 4, dark)
    d.rectangle([44, 23, 47, 24], fill=joint)  # elbow band
    # left arm (uv 36,52): front(36,52) right(32,52) left(40,52) back(44,52) top(36,48) bottom(40,48)
    for (x, y) in ((32, 52), (36, 52), (40, 52), (44, 52)):
        noise(img, x, y, 4, 12, skin)
    noise(img, 36, 48, 4, 4, suitd)
    noise(img, 40, 48, 4, 4, dark)
    d.rectangle([36, 55, 39, 56], fill=joint)
    # right leg (uv 4,20): front(4,20) right(0,20) left(8,20) back(12,20) top(4,16) bottom(8,16)
    for (x, y) in ((0, 20), (4, 20), (8, 20), (12, 20)):
        noise(img, x, y, 4, 12, suitd)
    noise(img, 4, 16, 4, 4, suitd)
    noise(img, 8, 16, 4, 4, dark)
    d.rectangle([4, 26, 7, 27], fill=joint)  # knee band
    # left leg (uv 20,52): front(20,52) right(16,52) left(24,52) back(28,52) top(20,48) bottom(24,48)
    for (x, y) in ((16, 52), (20, 52), (24, 52), (28, 52)):
        noise(img, x, y, 4, 12, suitd)
    noise(img, 20, 48, 4, 4, suitd)
    noise(img, 24, 48, 4, 4, dark)
    d.rectangle([20, 58, 23, 59], fill=joint)
    save(img, 'mannequin.png')

    model = {
        "name": "IK mannequin",
        "texture": "mannequin.png",
        "texture_size": [64, 64],
        "player_skin": True,
        "description": "Posable mannequin with IK-ready arms and legs. Works with player skins.",
        "parts": [
            {
                "name": "body",
                "position": [0, 12, 0],
                "bend": {"offset": 6, "end_offset": 6, "size": 10, "part": "upper", "axis": ["x", "y", "z"]},
                "shapes": [shape([-4, 0, -2], [4, 12, 2], [20, 20])],
                "parts": [
                    {
                        "name": "head",
                        "position": [0, 12, 0],
                        "shapes": [shape([-4, 0, -4], [4, 8, 4], [8, 8])],
                    },
                    {
                        "name": "right_arm",
                        "position": [-6, 10, 0],
                        "bend": {"offset": -4, "end_offset": 6, "part": "lower", "axis": "x", "direction_min": 0, "invert": True},
                        "shapes": [shape([-2, -10, -2], [2, 2, 2], [44, 20])],
                    },
                    {
                        "name": "left_arm",
                        "position": [6, 10, 0],
                        "bend": {"offset": -4, "end_offset": 6, "part": "lower", "axis": "x", "direction_min": 0, "invert": True},
                        "shapes": [shape([-2, -10, -2], [2, 2, 2], [36, 52])],
                    },
                ],
            },
            {
                "name": "right_leg",
                "position": [-2, 12, 0],
                "bend": {"offset": -6, "end_offset": 6, "part": "lower", "axis": "x", "direction_min": 0},
                "shapes": [shape([-2, -12, -2], [2, 0, 2], [4, 20])],
            },
            {
                "name": "left_leg",
                "position": [2, 12, 0],
                "bend": {"offset": -6, "end_offset": 6, "part": "lower", "axis": "x", "direction_min": 0},
                "shapes": [shape([-2, -12, -2], [2, 0, 2], [20, 52])],
            },
        ],
    }
    write_rig('mannequin', model, ['mannequin.png'])

# ---------------------------------------------------------------- 2. Stick figure (IK)
def stickman():
    p = TexPacker('stickman')
    wood = (232, 200, 152)
    dark = (196, 160, 110)
    red  = (214, 84, 74)

    uv_head = p.add(3, 3, 3)
    uv_body = p.add(2, 10, 2)
    uv_arm  = p.add(1, 10, 1)
    uv_leg  = p.add(1, 10, 1)
    img, size = p.finish()

    paint_faces(img, uv_head, 3, 3, 3, wood, wood, wood, wood, wood, wood)
    d = ImageDraw.Draw(img)
    fx, fy = uv_head
    d.rectangle([fx + 0.6, fy + 1, fx + 1.1, fy + 1.4], fill=(40, 40, 44, 255))
    d.rectangle([fx + 1.9, fy + 1, fx + 2.4, fy + 1.4], fill=(40, 40, 44, 255))
    paint_faces(img, uv_body, 2, 10, 2, red, red, dark, red, dark, red)
    paint_faces(img, uv_arm, 1, 10, 1, wood, dark, wood, wood, wood, wood)
    paint_faces(img, uv_leg, 1, 10, 1, dark, dark, dark, dark, dark, dark)
    save(img, 'stickman.png')

    limb_bend = {"offset": -5, "end_offset": 5, "part": "lower", "axis": "x", "direction_min": 0}
    arm_bend = dict(limb_bend, invert=True)
    model = {
        "name": "Stick figure",
        "texture": "stickman.png",
        "texture_size": size,
        "description": "Thin posable stick figure with IK-ready limbs.",
        "parts": [
            {
                "name": "body",
                "position": [0, 10, 0],
                "shapes": [shape([-1, 0, -1], [1, 10, 1], uv_body)],
                "parts": [
                    {"name": "head", "position": [0, 10, 0],
                     "shapes": [shape([-1.5, 0, -1.5], [1.5, 3, 1.5], uv_head)]},
                    {"name": "right_arm", "position": [-1.5, 9, 0], "bend": arm_bend,
                     "shapes": [shape([-0.5, -9, -0.5], [0.5, 1, 0.5], uv_arm)]},
                    {"name": "left_arm", "position": [1.5, 9, 0], "bend": arm_bend,
                     "shapes": [shape([-0.5, -9, -0.5], [0.5, 1, 0.5], uv_arm)]},
                ],
            },
            {"name": "right_leg", "position": [-0.75, 10, 0], "bend": limb_bend,
             "shapes": [shape([-0.5, -10, -0.5], [0.5, 0, 0.5], uv_leg)]},
            {"name": "left_leg", "position": [0.75, 10, 0], "bend": limb_bend,
             "shapes": [shape([-0.5, -10, -0.5], [0.5, 0, 0.5], uv_leg)]},
        ],
    }
    write_rig('stickman', model, ['stickman.png'])

# ---------------------------------------------------------------- screen texture helper
def screen_texture(name, size):
    """Square placeholder (the engine pads textures to squares; the video
    frame replaces this texture at runtime and fills the whole square)."""
    img = canvas(size, size)
    for y in range(size):
        g = 16 + int(10 * y / size)
        for x in range(size):
            img.putpixel((x, y), (g - 2, g - 1, g + 4, 255))
    d = ImageDraw.Draw(img)
    d.ellipse([size - size//14, size - size//14, size - 2, size - 2],
              fill=(60, 160, 70, 255))
    save(img, name)

# ---------------------------------------------------------------- 3. Monitor (video screen)
def monitor():
    p = TexPacker('monitor')
    plastic, plastic_d = (38, 38, 42), (28, 28, 32)
    uv_foot = p.add(8, 1, 6)
    uv_stand = p.add(2, 6, 2)
    uv_frame = p.add(18, 11, 1)
    img, size = p.finish()

    paint_faces(img, uv_foot, 8, 1, 6, plastic_d, plastic_d, plastic_d, plastic, plastic_d, plastic_d)
    paint_faces(img, uv_stand, 2, 6, 2, plastic_d, plastic_d, plastic_d, plastic_d, plastic_d, plastic_d)
    def bezel(i, x, y, w, h):
        noise(i, x, y, w, h, plastic)
        d = ImageDraw.Draw(i)
        d.rectangle([x + 1, y + 1, x + w - 2, y + h - 2], fill=(16, 17, 20, 255))
    paint_faces(img, uv_frame, 18, 11, 1, plastic, plastic, plastic, bezel, plastic, plastic)
    save(img, 'monitor.png')
    screen_texture('monitor_screen.png', 64)
    ssize = [16, 16]

    model = {
        "name": "Monitor",
        "texture": "monitor.png",
        "texture_size": size,
        "description": "Desktop monitor - attach a video file and it plays on the screen.",
        "parts": [
            {"name": "foot", "position": [0, 0, 0],
             "shapes": [shape([-4, 0, -3], [4, 1, 3], uv_foot)]},
            {"name": "stand", "position": [0, 1, 0],
             "shapes": [shape([-1, 0, -1], [1, 6, 1], uv_stand)]},
            {"name": "frame", "position": [0, 7, 0],
             "shapes": [shape([-9, 0, -0.5], [9, 11, 0.5], uv_frame)]},
            {"name": "screen", "position": [0, 7.5, 0.5],
             "texture": "monitor_screen.png", "texture_size": ssize,
             "shapes": [shape([-8, 0, 0], [8, 9, 0.2], [0, 0])]},
        ],
    }
    write_rig('monitor', model, ['monitor.png', 'monitor_screen.png'])

# ---------------------------------------------------------------- 4. Billboard (video screen)
def billboard():
    p = TexPacker('billboard')
    metal, metal_d = (94, 98, 104), (70, 74, 80)
    uv_leg = p.add(2, 10, 2)
    uv_frame = p.add(36, 22, 2)
    img, size = p.finish()
    paint_faces(img, uv_leg, 2, 10, 2, metal_d, metal_d, metal_d, metal, metal_d, metal_d)
    paint_faces(img, uv_frame, 36, 22, 2, metal, metal, metal_d, metal, metal_d, metal)
    save(img, 'billboard.png')
    screen_texture('billboard_screen.png', 128)
    ssize = [32, 32]

    model = {
        "name": "Billboard",
        "texture": "billboard.png",
        "texture_size": size,
        "description": "Large roadside billboard - attach a video file and it plays on the screen.",
        "parts": [
            {"name": "leg_left", "position": [-14, 0, 0],
             "shapes": [shape([-1, 0, -1], [1, 10, 1], uv_leg)]},
            {"name": "leg_right", "position": [14, 0, 0],
             "shapes": [shape([-1, 0, -1], [1, 10, 1], uv_leg)]},
            {"name": "frame", "position": [0, 10, 0],
             "shapes": [shape([-18, 0, -1], [18, 22, 1], uv_frame)]},
            {"name": "screen", "position": [0, 12, 1],
             "texture": "billboard_screen.png", "texture_size": ssize,
             "shapes": [shape([-16, 0, 0], [16, 18, 0.2], [0, 0])]},
        ],
    }
    write_rig('billboard', model, ['billboard.png', 'billboard_screen.png'])

# ---------------------------------------------------------------- 5. Table
def table():
    p = TexPacker('table')
    wood, wood_d = (176, 140, 92), (132, 102, 64)
    uv_top = p.add(20, 2, 12)
    uv_leg = p.add(2, 14, 2)
    img, size = p.finish()
    def tabletop(i, x, y, w, h):
        noise(i, x, y, w, h, wood, 6)
        d = ImageDraw.Draw(i)
        for k in range(0, w, 5):
            d.line([x + k, y, x + k, y + h - 1], fill=wood_d, width=1)
    paint_faces(img, uv_top, 20, 2, 12, wood_d, wood_d, wood_d, tabletop, wood_d, tabletop)
    paint_faces(img, uv_leg, 2, 14, 2, wood_d, wood_d, wood_d, wood, wood_d, wood)
    save(img, 'table.png')

    model = {
        "name": "Table",
        "texture": "table.png",
        "texture_size": size,
        "description": "Wooden table with four legs.",
        "parts": [
            {"name": "top", "position": [0, 14, 0],
             "shapes": [shape([-10, 0, -6], [10, 2, 6], uv_top)]},
            {"name": "leg_front_left", "position": [-8, 0, 4],
             "shapes": [shape([-1, 0, -1], [1, 14, 1], uv_leg)]},
            {"name": "leg_front_right", "position": [8, 0, 4],
             "shapes": [shape([-1, 0, -1], [1, 14, 1], uv_leg)]},
            {"name": "leg_back_left", "position": [-8, 0, -4],
             "shapes": [shape([-1, 0, -1], [1, 14, 1], uv_leg)]},
            {"name": "leg_back_right", "position": [8, 0, -4],
             "shapes": [shape([-1, 0, -1], [1, 14, 1], uv_leg)]},
        ],
    }
    write_rig('table', model, ['table.png'])

# ---------------------------------------------------------------- 6. Chair
def chair():
    p = TexPacker('chair')
    wood, wood_d = (168, 128, 84), (124, 92, 58)
    uv_seat = p.add(8, 1, 8)
    uv_leg = p.add(1, 8, 1)
    uv_back = p.add(8, 10, 1)
    img, size = p.finish()
    paint_faces(img, uv_seat, 8, 1, 8, wood_d, wood_d, wood_d, wood, wood_d, wood_d)
    paint_faces(img, uv_leg, 1, 8, 1, wood_d, wood_d, wood_d, wood, wood_d, wood)
    def backrest(i, x, y, w, h):
        noise(i, x, y, w, h, wood)
        d = ImageDraw.Draw(i)
        d.line([x, y + h - 2, x + w - 1, y + h - 2], fill=wood_d, width=2)
    paint_faces(img, uv_back, 8, 10, 1, wood_d, wood_d, wood_d, backrest, wood_d, backrest)
    save(img, 'chair.png')

    model = {
        "name": "Chair",
        "texture": "chair.png",
        "texture_size": size,
        "description": "Wooden chair with backrest.",
        "parts": [
            {"name": "seat", "position": [0, 8, 0],
             "shapes": [shape([-4, 0, -4], [4, 1, 4], uv_seat)]},
            {"name": "leg_front_left", "position": [-3.5, 0, 3.5],
             "shapes": [shape([-0.5, 0, -0.5], [0.5, 8, 0.5], uv_leg)]},
            {"name": "leg_front_right", "position": [3.5, 0, 3.5],
             "shapes": [shape([-0.5, 0, -0.5], [0.5, 8, 0.5], uv_leg)]},
            {"name": "leg_back_left", "position": [-3.5, 0, -3.5],
             "shapes": [shape([-0.5, 0, -0.5], [0.5, 8, 0.5], uv_leg)]},
            {"name": "leg_back_right", "position": [3.5, 0, -3.5],
             "shapes": [shape([-0.5, 0, -0.5], [0.5, 8, 0.5], uv_leg)]},
            {"name": "backrest", "position": [0, 9, -3.5],
             "shapes": [shape([-4, 0, -0.5], [4, 10, 0.5], uv_back)]},
        ],
    }
    write_rig('chair', model, ['chair.png'])

# ---------------------------------------------------------------- 7. Bookshelf
def bookshelf():
    p = TexPacker('bookshelf')
    uv = p.add(16, 16, 16)
    img, size = p.finish()
    wood, wood_d = (158, 116, 70), (110, 78, 44)
    books = [(168, 60, 54), (196, 148, 62), (86, 120, 74), (88, 108, 152), (152, 88, 140), (200, 200, 188)]
    def shelf_side(i, x, y, w, h):
        noise(i, x, y, w, h, wood, 6)
        d = ImageDraw.Draw(i)
        for k in range(0, w, 4):
            d.line([x + k, y, x + k, y + h - 1], fill=wood_d, width=1)
    def shelf_face(i, x, y, w, h):
        noise(i, x, y, w, h, wood, 6)
        d = ImageDraw.Draw(i)
        # three book rows with gaps
        for row, ry in enumerate((2, 8, 13)):
            ry = int(ry * h / 16.0) + y
            rh = int(4 * h / 16.0)
            xx = x + 1
            bi = row
            while xx < x + w - 1:
                bw = random.randint(1, 2)
                col = books[bi % len(books)]
                bi += 1
                d.rectangle([xx, ry, min(xx + bw, x + w - 2), ry + rh - 1], fill=col)
                xx += bw + 1 if random.random() < 0.4 else bw
    paint_faces(img, uv, 16, 16, 16, wood_d, wood_d, shelf_side, shelf_face, shelf_side, shelf_face)
    save(img, 'bookshelf.png')

    model = {
        "name": "Bookshelf",
        "texture": "bookshelf.png",
        "texture_size": size,
        "description": "Blocky bookshelf stacked with books.",
        "parts": [
            {"name": "shelf", "position": [0, 8, 0],
             "shapes": [shape([-8, -8, -8], [8, 8, 8], uv)]},
        ],
    }
    write_rig('bookshelf', model, ['bookshelf.png'])

# ---------------------------------------------------------------- 8. Barrel
def barrel():
    p = TexPacker('barrel')
    uv = p.add(14, 16, 14)
    img, size = p.finish()
    wood, wood_d = (140, 104, 62), (100, 72, 40)
    hoop = (72, 74, 82)
    def side(i, x, y, w, h):
        noise(i, x, y, w, h, wood, 7)
        d = ImageDraw.Draw(i)
        for k in range(0, w, 3):
            d.line([x + k, y, x + k, y + h - 1], fill=wood_d, width=1)
        # hoops near top and bottom
        d.rectangle([x, y, x + w - 1, y + 1], fill=hoop)
        d.rectangle([x, y + h - 2, x + w - 1, y + h - 1], fill=hoop)
    def cap(i, x, y, w, h):
        noise(i, x, y, w, h, wood_d, 6)
        d = ImageDraw.Draw(i)
        d.rectangle([x + 2, y + 2, x + w - 3, y + h - 3], outline=hoop, width=1)
    paint_faces(img, uv, 14, 16, 14, cap, cap, side, side, side, side)
    save(img, 'barrel.png')

    model = {
        "name": "Barrel",
        "texture": "barrel.png",
        "texture_size": size,
        "description": "Wooden barrel with metal hoops.",
        "parts": [
            {"name": "barrel", "position": [0, 8, 0],
             "shapes": [shape([-7, -8, -7], [7, 8, 7], uv)]},
        ],
    }
    write_rig('barrel', model, ['barrel.png'])

# ---------------------------------------------------------------- 9. Chest (posable lid)
def chest():
    p = TexPacker('chest')
    wood, wood_d = (156, 116, 66), (108, 76, 40)
    latch = (66, 68, 76)
    uv_base = p.add(14, 10, 10)
    uv_lid = p.add(14, 5, 10)
    uv_latch = p.add(2, 3, 1)
    img, size = p.finish()
    def panel(i, x, y, w, h, border=True):
        noise(i, x, y, w, h, wood, 6)
        d = ImageDraw.Draw(i)
        if border:
            d.rectangle([x, y, x + w - 1, y + h - 1], outline=wood_d, width=1)
    def latch_face(i, x, y, w, h):
        noise(i, x, y, w, h, latch, 4)
    paint_faces(img, uv_base, 14, 10, 10, wood_d, wood_d, panel, panel, panel, panel)
    paint_faces(img, uv_lid, 14, 5, 10, wood_d, wood_d, panel, panel, panel, panel)
    paint_faces(img, uv_latch, 2, 3, 1, latch, latch, latch_face, latch_face, latch_face, latch_face)
    save(img, 'chest.png')

    model = {
        "name": "Chest",
        "texture": "chest.png",
        "texture_size": size,
        "description": "Treasure chest with a posable lid - rotate the lid part to open it.",
        "parts": [
            {"name": "base", "position": [0, 5, 0],
             "shapes": [shape([-7, -5, -5], [7, 5, 5], uv_base)]},
            {"name": "lid", "position": [0, 10, -5],
             "shapes": [
                 shape([-7, 0, 0], [7, 5, 10], uv_lid),
                 shape([-1, 1, 10], [1, 3.5, 11], uv_latch),
             ]},
        ],
    }
    write_rig('chest', model, ['chest.png'])

# ---------------------------------------------------------------- 10. Street lamp
def streetlamp():
    p = TexPacker('streetlamp')
    metal, metal_d = (74, 78, 84), (54, 58, 64)
    glass = (255, 236, 150)
    uv_base = p.add(6, 1, 6)
    uv_post = p.add(2, 26, 2)
    uv_arm = p.add(2, 1, 8)
    uv_head = p.add(4, 3, 4)
    img, size = p.finish()
    paint_faces(img, uv_base, 6, 1, 6, metal_d, metal_d, metal_d, metal, metal_d, metal_d)
    paint_faces(img, uv_post, 2, 26, 2, metal_d, metal_d, metal_d, metal, metal_d, metal_d)
    paint_faces(img, uv_arm, 2, 1, 8, metal_d, metal_d, metal_d, metal, metal_d, metal_d)
    def head(i, x, y, w, h):
        noise(i, x, y, w, h, metal)
        d = ImageDraw.Draw(i)
        d.rectangle([x + 1, y + h - 2, x + w - 2, y + h - 1], fill=glass)  # lit bottom strip
    paint_faces(img, uv_head, 4, 3, 4, metal_d, glass, metal, head, metal, head)
    save(img, 'streetlamp.png')

    model = {
        "name": "Street lamp",
        "texture": "streetlamp.png",
        "texture_size": size,
        "description": "Street lamp with a lit lamp head on an arm.",
        "parts": [
            {"name": "base", "position": [0, 0, 0],
             "shapes": [shape([-3, 0, -3], [3, 1, 3], uv_base)]},
            {"name": "post", "position": [0, 1, 0],
             "shapes": [shape([-1, 0, -1], [1, 26, 1], uv_post)]},
            {"name": "arm", "position": [0, 27, 0],
             "shapes": [shape([-1, -0.5, -1], [1, 0.5, 7], uv_arm)]},
            {"name": "head", "position": [0, 26, 7],
             "shapes": [shape([-2, -1, -2], [2, 2, 2], uv_head)]},
        ],
    }
    write_rig('streetlamp', model, ['streetlamp.png'])

# ---------------------------------------------------------------- 11. Park bench
def bench():
    p = TexPacker('bench')
    wood, wood_d = (150, 106, 62), (106, 72, 40)
    metal = (80, 84, 90)
    uv_side = p.add(2, 9, 6)
    uv_slat = p.add(16, 1, 2)
    uv_vslat = p.add(16, 2, 1)
    img, size = p.finish()
    def slat(i, x, y, w, h):
        noise(i, x, y, w, h, wood, 6)
        d = ImageDraw.Draw(i)
        for k in range(0, w, 6):
            d.line([x + k, y, x + k, y + h - 1], fill=wood_d, width=1)
    def side(i, x, y, w, h):
        noise(i, x, y, w, h, metal, 5)
    paint_faces(img, uv_side, 2, 9, 6, metal, metal, side, side, side, side)
    paint_faces(img, uv_slat, 16, 1, 2, wood_d, wood_d, wood_d, slat, wood_d, slat)
    paint_faces(img, uv_vslat, 16, 2, 1, wood_d, wood_d, wood_d, slat, wood_d, slat)
    save(img, 'bench.png')

    model = {
        "name": "Park bench",
        "texture": "bench.png",
        "texture_size": size,
        "description": "Park bench with wooden slats and metal sides.",
        "parts": [
            {"name": "side_left", "position": [-7, 0, 0],
             "shapes": [shape([-1, 0, -3], [1, 9, 3], uv_side)]},
            {"name": "side_right", "position": [7, 0, 0],
             "shapes": [shape([-1, 0, -3], [1, 9, 3], uv_side)]},
            {"name": "seat", "position": [0, 9, 0],
             "shapes": [
                 shape([-8, 0, -2.7], [8, 0.8, -0.9], uv_slat),
                 shape([-8, 0, -0.9], [8, 0.8, 0.9], uv_slat),
                 shape([-8, 0, 0.9], [8, 0.8, 2.7], uv_slat),
             ]},
            {"name": "backrest", "position": [0, 9, -3],
             "shapes": [
                 shape([-8, 0, -0.5], [8, 2, 0.5], uv_vslat),
                 shape([-8, 3, -0.5], [8, 5, 0.5], uv_vslat),
                 shape([-8, 6, -0.5], [8, 8, 0.5], uv_vslat),
             ]},
        ],
    }
    write_rig('bench', model, ['bench.png'])

# ---------------------------------------------------------------- 12. Traffic barrier
def barrier():
    p = TexPacker('barrier')
    orange = (232, 122, 40)
    white = (235, 235, 235)
    metal = (90, 94, 100)
    uv_foot = p.add(8, 1, 4)
    uv_post = p.add(2, 8, 2)
    uv_board = p.add(24, 5, 1)
    uv_rail = p.add(24, 1, 1)
    img, size = p.finish()
    def stripes(i, x, y, w, h):
        noise(i, x, y, w, h, white, 4)
        d = ImageDraw.Draw(i)
        for k in range(-h, w, 8):
            d.polygon([(x + max(0, k), y), (x + min(w, k + 4), y), (x + min(w, k + 4 + h), y + h - 1), (x + max(0, k + h), y + h - 1)], fill=orange)
    def plain(i, x, y, w, h):
        noise(i, x, y, w, h, metal, 5)
    paint_faces(img, uv_foot, 8, 1, 4, metal, metal, plain, plain, plain, plain)
    paint_faces(img, uv_post, 2, 8, 2, metal, metal, plain, plain, plain, plain)
    paint_faces(img, uv_board, 24, 5, 1, orange, orange, stripes, stripes, stripes, stripes)
    paint_faces(img, uv_rail, 24, 1, 1, metal, metal, plain, plain, plain, plain)
    save(img, 'barrier.png')

    model = {
        "name": "Traffic barrier",
        "texture": "barrier.png",
        "texture_size": size,
        "description": "Striped construction barrier.",
        "parts": [
            {"name": "foot_left", "position": [-10, 0, 0],
             "shapes": [shape([-4, 0, -2], [4, 1, 2], uv_foot)]},
            {"name": "foot_right", "position": [10, 0, 0],
             "shapes": [shape([-4, 0, -2], [4, 1, 2], uv_foot)]},
            {"name": "post_left", "position": [-10, 1, 0],
             "shapes": [shape([-1, 0, -1], [1, 8, 1], uv_post)]},
            {"name": "post_right", "position": [10, 1, 0],
             "shapes": [shape([-1, 0, -1], [1, 8, 1], uv_post)]},
            {"name": "board", "position": [0, 4, 0],
             "shapes": [shape([-12, 0, -0.5], [12, 5, 0.5], uv_board)]},
            {"name": "rail", "position": [0, 9.5, 0],
             "shapes": [shape([-12, 0, -0.5], [12, 1, 0.5], uv_rail)]},
        ],
    }
    write_rig('barrier', model, ['barrier.png'])

# ---------------------------------------------------------------- repack the pre-existing rigs
def repack_existing():
    """The four original rigs already have correct UVs in Rigs/*.json; they
    need re-packing as .miobject + .mimodel (previously packed as .json,
    which does not import). The TV screen part is normalized to a full-frame
    screen and gets a square placeholder texture."""
    screen_texture('screen.png', 56)  # square TV screen placeholder
    for slug, jsonname in (('crate', 'crate.json'), ('traffic-cone', 'traffic_cone.json'),
                           ('speaker', 'speaker.json'), ('tv', 'tv.json')):
        model = json.load(open(f'Rigs/{jsonname}'))
        normalize_screen_parts(model['parts'])
        with open(f'Rigs/{jsonname}', 'w') as f:
            json.dump(model, f, indent=1)
        textures = [model['texture']]
        def collect(parts):
            for part in parts:
                if 'texture' in part:
                    textures.append(part['texture'])
                collect(part.get('parts', []))
        collect(model['parts'])
        pack_rig(slug, model, textures, jsonname=f'Rigs/{jsonname}')
        print(f"  re-packed {slug}.zip")

# ---------------------------------------------------------------- catalog index
def index():
    catalog = [
        ("Posable mannequin (IK)", "Posable figure with IK-ready bending arms and legs - rotate parts to pose, use IK targets in the frame editor. Also works with player skins.", "mannequin.zip"),
        ("Stick figure (IK)", "Thin posable stick figure with IK-ready limbs, perfect for animation practice.", "stickman.zip"),
        ("TV (video screen)", "Retro TV - attach a video file and it plays on the screen", "tv.zip"),
        ("Monitor (video screen)", "Desktop monitor - attach a video file and it plays on the screen", "monitor.zip"),
        ("Billboard (video screen)", "Large roadside billboard - attach a video file and it plays on the screen", "billboard.zip"),
        ("Table", "Wooden table with four legs", "table.zip"),
        ("Chair", "Wooden chair with backrest", "chair.zip"),
        ("Bookshelf", "Blocky bookshelf stacked with books", "bookshelf.zip"),
        ("Barrel", "Wooden barrel with metal hoops", "barrel.zip"),
        ("Chest", "Treasure chest with a posable lid - rotate the lid part to open it", "chest.zip"),
        ("Street lamp", "Street lamp with a lit lamp head on an arm", "streetlamp.zip"),
        ("Park bench", "Park bench with wooden slats and metal sides", "bench.zip"),
        ("Traffic barrier", "Striped construction barrier", "barrier.zip"),
        ("Wooden crate", "A classic 16x16 wooden crate prop", "crate.zip"),
        ("Traffic cone", "Orange traffic cone with reflective stripe", "traffic-cone.zip"),
        ("Speaker", "Audio speaker with woofer detail", "speaker.zip"),
    ]
    d = {"rigs": [
        {"name": n, "author": "Mine-imator Reforged", "description": desc, "file": f}
        for (n, desc, f) in catalog
    ]}
    with open('Rigs/index.json', 'w') as f:
        json.dump(d, f, indent=1)
    print(f"  index.json with {len(catalog)} rigs")

if __name__ == '__main__':
    print("Generating rigs...")
    mannequin(); stickman(); monitor(); billboard(); table(); chair()
    bookshelf(); barrel(); chest(); streetlamp(); bench(); barrier()
    repack_existing()
    index()
    print("Done.")
