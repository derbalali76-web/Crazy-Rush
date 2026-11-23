"""يبني مجسمات الديكور (صخور/سراخس) بمستويات LOD من نماذج Poly Haven (CC0) بعد التبسيط.
التشغيل: python3 -I tools/blender/bake_props.py   (يتطلب حزمة bpy)
المخرجات: assets/art/props/<name>_lod{0,1,2}.glb  (الأصل عند الإحداثيات: القاعدة y=0، مركزه x=z=0)"""
import bpy, os, sys, math

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SRC = os.path.join(ROOT, "assets/src/models")
OUT = os.path.join(ROOT, "assets/art/props")
os.makedirs(OUT, exist_ok=True)

# (المجموعة، ملف gltf، قائمة الأجزاء -> اسم الناتج، أهداف المثلثات LOD0/1/2)
JOBS = [
    ("rock_moss_set_01", "rock_moss_set_01_1k.gltf", {f"rock_moss_set_01_rock0{i}": f"rock{i}" for i in range(1, 7)}, (2500, 900, 300)),
    ("fern_02", "fern_02_1k.gltf", "ALL:fern", (1800, 700, 250)),
    ("anthurium_botany_01", "anthurium_botany_01_1k.gltf", "ALL:anthurium", (2200, 900, 300)),
    ("calathea_orbifolia_01", "calathea_orbifolia_01_1k.gltf", "ALL:calathea", (2000, 800, 280)),
]

def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def tri_count(o):
    me = o.data
    me.calc_loop_triangles()
    return len(me.loop_triangles)

def select_only(objs):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]

def decimate_to(o, target):
    n = tri_count(o)
    if n <= target:
        return
    m = o.modifiers.new("dec", "DECIMATE")
    m.ratio = max(target / n, 0.02)
    select_only([o])
    bpy.ops.object.modifier_apply(modifier=m.name)

def normalize(o, scale_to_height=None):
    # القاعدة على y=0 ومركز x/z عند الصفر (غلتف: Y-up في الاستيراد يصبح Z-up في بلندر)
    bpy.ops.object.select_all(action="DESELECT")
    o.select_set(True)
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    vs = [o.matrix_world @ v.co for v in o.data.vertices]
    minz = min(v.z for v in vs)
    cx = (min(v.x for v in vs) + max(v.x for v in vs)) / 2
    cy = (min(v.y for v in vs) + max(v.y for v in vs)) / 2
    for v in o.data.vertices:
        v.co.x -= cx
        v.co.y -= cy
        v.co.z -= minz

def export(objs, name, lod):
    select_only(objs)
    path = os.path.join(OUT, f"{name}_lod{lod}.glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True,
                              export_yup=True, export_materials="NONE",
                              export_apply=True)
    return os.path.getsize(path)

def load(group, f):
    reset()
    bpy.ops.import_scene.gltf(filepath=os.path.join(SRC, group, f))
    return [o for o in bpy.context.scene.objects if o.type == "MESH"]

report = []
for group, f, parts, targets in JOBS:
    for lod, target in enumerate(targets):
        meshes = load(group, f)
        if isinstance(parts, dict):
            items = [(o, parts[o.name]) for o in meshes if o.name in parts]
        else:
            select_only(meshes)
            if len(meshes) > 1:
                bpy.ops.object.join()
            items = [(bpy.context.view_layer.objects.active, parts.split(":")[1])]
        for o, name in items:
            # أحجار: الهدف لكل صخرة؛ نباتات: الهدف للمجموعة
            decimate_to(o, target)
            normalize(o)
            size = export([o], name, lod)
            report.append((name, lod, tri_count(o), size))
for r in report:
    print("BAKED %-10s lod%d tris=%5d  %6.0f KB" % (r[0], r[1], r[2], r[3] / 1024))
