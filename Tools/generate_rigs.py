#!/usr/bin/env python3
"""Generates the Reforged feature rigs: the video screens (TV, monitor,
billboard) and the posable mannequin. Community rigs in Rigs/*.zip are
curated downloads - see Rigs/CREDITS.md and Rigs/index.json.

Model JSON conventions (verified against the bundled steve.mimodel and
model_file_load*/model_shape_generate_block):
  - Arrays are Minecraft-style [x, y_up, z_forward] (the loader swaps y/z).
  - Box "uv" is the FRONT face top-left in the texture. Face rects:
      top (u, v-d) w x d, bottom (u+w, v-d) w x d, right (u-d, v) d x h,
      front (u, v) w x h, left (u+w, v) d x h, back (u+w+d, v) w x h.
  - The engine squares every texture grid (texture_size -> max(w,h)) and
    pads loaded textures to squares: declare logical sizes and ship any
    aspect png.
  - A part textured screen.png whose box spans the full (squared) grid
    shows the whole texture on its front face -> the attached video fills
    the face. normalize_screen_parts() rewrites such parts into square
    noscale boxes + a Y scale (rendered footprint stays the same).
  - Limbs with bend {part: "lower", axis: "x", end_offset > 0} are IK-ready.
"""
import json, os, random, zipfile
from PIL import Image, ImageDraw

random.seed(1234)
os.makedirs('Rigs', exist_ok=True)

PROJECT_FORMAT = 35          # e_project.FORMAT_CTB_106 (project_format macro)
MATERIAL_FORMAT_LABPBR = 2   # e_material.FORMAT_LABPBR (resource default)
CREATED_IN = "2.0.2 Reforged 1.0.7"

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

class TexPacker:
    """Allocates box unwrap regions side by side on one texture."""
    def __init__(self, name):
        self.name = name
        self.regions = []
        self.width = 0
        self.height = 0
    def add(self, w, h, d):
        rw, rh = 2 * w + 2 * d, h + d
        x, y = self.width, 0
        self.regions.append((x, y, w, h, d))
        self.width += rw + 1
        self.height = max(self.height, rh)
        return [x + d, y + d]  # uv = front face top-left
    def finish(self):
        return canvas(self.width, max(self.height, 1)), [self.width, self.height]

def paint_faces(img, uv, w, h, d, top, bottom, right, front, left, back):
    u, v = uv
    for (x, y, rw, rh, col) in (
        (u, v - d, w, d, top), (u + w, v - d, w, d, bottom),
        (u - d, v, d, h, right), (u, v, w, h, front),
        (u + w, v, d, h, left), (u + w + d, v, w, h, back),
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

def normalize_screen_parts(parts):
    """Rewrites video-screen parts into square noscale boxes + Y scale so
    the video frame fills the whole face (see module docstring)."""
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
    member = slug.replace('-', '_')
    safe = "".join(c if c.isalnum() or c == '_' else '_' for c in member)
    with zipfile.ZipFile(f'Rigs/{slug}.zip', 'w', zipfile.ZIP_DEFLATED) as z:
        z.write(f'Rigs/{slug}.json', member + '.mimodel')
        z.writestr(member + '.miobject', json.dumps(miobject(model['name'], member, safe), indent=1))
        for fn in textures:
            z.write(f'Rigs/{fn}', fn)
    print(f"  {slug}.zip")

def screen_texture(name, size):
    """Square placeholder (the engine pads textures to squares; the video
    frame replaces this texture at runtime and fills the whole square)."""
    img = canvas(size, size)
    for y in range(size):
        g = 16 + int(10 * y / size)
        for x in range(size):
            img.putpixel((x, y), (g - 2, g - 1, g + 4, 255))
    d = ImageDraw.Draw(img)
    d.ellipse([size - size // 14, size - size // 14, size - 2, size - 2],
              fill=(60, 160, 70, 255))
    img.save(f'Rigs/{name}')

# ---------------------------------------------------------------- mannequin
def mannequin():
    img = canvas(64, 64)
    skin, dark, hair = (168, 158, 142), (120, 110, 96), (96, 84, 70)
    suit, suitd = (108, 128, 158), (88, 104, 132)
    joint = (70, 78, 92)
    for (x, y) in ((0, 8), (8, 8), (16, 8), (24, 8)):
        noise(img, x, y, 8, 8, skin)
    noise(img, 8, 0, 8, 8, hair)
    noise(img, 16, 0, 8, 8, skin)
    d = ImageDraw.Draw(img)
    d.rectangle([10, 11, 11, 12], fill=(40, 40, 44, 255))
    d.rectangle([14, 11, 15, 12], fill=(40, 40, 44, 255))
    d.rectangle([11, 14, 13, 14], fill=(120, 96, 88, 255))
    d.line([8, 8, 15, 8], fill=hair, width=2)
    noise(img, 20, 20, 8, 12, suit); noise(img, 32, 20, 8, 12, suit)
    noise(img, 16, 20, 4, 12, suitd); noise(img, 28, 20, 4, 12, suitd)
    noise(img, 20, 16, 8, 4, suitd); noise(img, 28, 16, 8, 4, dark)
    d.rectangle([20, 26, 27, 27], fill=joint)
    for (x, y) in ((40, 20), (44, 20), (48, 20), (52, 20)):
        noise(img, x, y, 4, 12, skin)
    noise(img, 44, 16, 4, 4, suitd); noise(img, 48, 16, 4, 4, dark)
    d.rectangle([44, 23, 47, 24], fill=joint)
    for (x, y) in ((32, 52), (36, 52), (40, 52), (44, 52)):
        noise(img, x, y, 4, 12, skin)
    noise(img, 36, 48, 4, 4, suitd); noise(img, 40, 48, 4, 4, dark)
    d.rectangle([36, 55, 39, 56], fill=joint)
    for (x, y) in ((0, 20), (4, 20), (8, 20), (12, 20)):
        noise(img, x, y, 4, 12, suitd)
    noise(img, 4, 16, 4, 4, suitd); noise(img, 8, 16, 4, 4, dark)
    d.rectangle([4, 26, 7, 27], fill=joint)
    for (x, y) in ((16, 52), (20, 52), (24, 52), (28, 52)):
        noise(img, x, y, 4, 12, suitd)
    noise(img, 20, 48, 4, 4, suitd); noise(img, 24, 48, 4, 4, dark)
    d.rectangle([20, 58, 23, 59], fill=joint)
    img.save('Rigs/mannequin.png')

    model = {
        "name": "IK mannequin",
        "texture": "mannequin.png",
        "texture_size": [64, 64],
        "player_skin": True,
        "description": "Posable mannequin with IK-ready arms and legs. Works with player skins.",
        "parts": [
            {"name": "body", "position": [0, 12, 0],
             "bend": {"offset": 6, "end_offset": 6, "size": 10, "part": "upper", "axis": ["x", "y", "z"]},
             "shapes": [shape([-4, 0, -2], [4, 12, 2], [20, 20])],
             "parts": [
                 {"name": "head", "position": [0, 12, 0],
                  "shapes": [shape([-4, 0, -4], [4, 8, 4], [8, 8])]},
                 {"name": "right_arm", "position": [-6, 10, 0],
                  "bend": {"offset": -4, "end_offset": 6, "part": "lower", "axis": "x", "direction_min": 0, "invert": True},
                  "shapes": [shape([-2, -10, -2], [2, 2, 2], [44, 20])]},
                 {"name": "left_arm", "position": [6, 10, 0],
                  "bend": {"offset": -4, "end_offset": 6, "part": "lower", "axis": "x", "direction_min": 0, "invert": True},
                  "shapes": [shape([-2, -10, -2], [2, 2, 2], [36, 52])]},
             ]},
            {"name": "right_leg", "position": [-2, 12, 0],
             "bend": {"offset": -6, "end_offset": 6, "part": "lower", "axis": "x", "direction_min": 0},
             "shapes": [shape([-2, -12, -2], [2, 0, 2], [4, 20])]},
            {"name": "left_leg", "position": [2, 12, 0],
             "bend": {"offset": -6, "end_offset": 6, "part": "lower", "axis": "x", "direction_min": 0},
             "shapes": [shape([-2, -12, -2], [2, 0, 2], [20, 52])]},
        ],
    }
    write_rig('mannequin', model, ['mannequin.png'])

# ---------------------------------------------------------------- TV
def tv():
    p = TexPacker('tv')
    plastic, plastic_d, plastic_l = (52, 46, 40), (38, 34, 30), (66, 60, 52)
    uv_feet = p.add(6, 2.5, 3)
    uv_body = p.add(18, 12, 5)
    img, size = p.finish()
    paint_faces(img, uv_feet, 6, 2.5, 3, plastic_d, plastic_d, plastic_d, plastic, plastic_d, plastic_d)
    def face(i, x, y, w, h):
        noise(i, x, y, w, h, plastic)
        d = ImageDraw.Draw(i)
        d.rectangle([x + 2, y + 2, x + w - 3, y + h - 3], outline=plastic_d, width=2)
        d.rectangle([x + 4, y + 4, x + w - 5, y + h - 5], fill=(16, 17, 20, 255))
        d.line([x + 5, y + 5, x + w - 6, y + 5], fill=plastic_l, width=1)
    paint_faces(img, uv_body, 18, 12, 5, plastic_d, plastic_d, plastic_d, face, plastic_d, face)
    img.save('Rigs/tv.png')
    screen_texture('screen.png', 56)  # square placeholder, video fills it

    model = {
        "name": "TV",
        "texture": "tv.png",
        "texture_size": size,
        "description": "Retro TV - attach a video file and it plays on the screen.",
        "parts": [
            {"name": "feet", "position": [0, 1.25, 0],
             "shapes": [shape([-3, -1.25, -1.5], [3, 1.25, 1.5], uv_feet)]},
            {"name": "body", "position": [0, 8.5, 0],
             "shapes": [shape([-9, -6, -2.5], [9, 6, 2.5], uv_body)]},
            {"name": "screen", "position": [0, 8.5, 2.55],
             "texture": "screen.png", "texture_size": [14, 8],
             "shapes": [shape([-7, -4, -0.05], [7, 4, 0.05], [0, 0])]},
        ],
    }
    write_rig('tv', model, ['tv.png', 'screen.png'])

# ---------------------------------------------------------------- monitor
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
    img.save('Rigs/monitor.png')
    screen_texture('monitor_screen.png', 64)

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
             "texture": "monitor_screen.png", "texture_size": [16, 9],
             "shapes": [shape([-8, 0, 0], [8, 9, 0.2], [0, 0])]},
        ],
    }
    write_rig('monitor', model, ['monitor.png', 'monitor_screen.png'])

# ---------------------------------------------------------------- billboard
def billboard():
    p = TexPacker('billboard')
    metal, metal_d = (94, 98, 104), (70, 74, 80)
    uv_leg = p.add(2, 10, 2)
    uv_frame = p.add(36, 22, 2)
    img, size = p.finish()
    paint_faces(img, uv_leg, 2, 10, 2, metal_d, metal_d, metal_d, metal, metal_d, metal_d)
    paint_faces(img, uv_frame, 36, 22, 2, metal, metal, metal_d, metal, metal_d, metal)
    img.save('Rigs/billboard.png')
    screen_texture('billboard_screen.png', 128)

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
             "texture": "billboard_screen.png", "texture_size": [32, 18],
             "shapes": [shape([-16, 0, 0], [16, 18, 0.2], [0, 0])]},
        ],
    }
    write_rig('billboard', model, ['billboard.png', 'billboard_screen.png'])

if __name__ == '__main__':
    print("Generating feature rigs...")
    mannequin(); tv(); monitor(); billboard()
    print("Done. (Community rigs are curated - see Rigs/index.json)")
