"""يبسّط مجسمات الأشجار/الجذوع/الجذور (work/models) إلى 3 مستويات LOD ويصدّرها GLB بلا مواد، ويخرج نسيجًا 1024 JPG لكل مجسم.
المخرجات: assets/art/props/<id>_lod{0,1,2}.glb و assets/art/props/tex/<id>_{diff,nor}.jpg"""
import bpy, os, glob, json
from PIL import Image
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SRC = os.path.join(ROOT, "work/models")
OUT = os.path.join(ROOT, "assets/art/props"); TEX = os.path.join(OUT, "tex")
os.makedirs(TEX, exist_ok=True)
TARGETS = {"tree_stump_01": (4000, 1500, 500), "tree_stump_02": (4000, 1500, 500), "dead_tree_trunk": (5000, 2000, 700),
           "dead_tree_trunk_02": (6000, 2500, 800), "root_cluster_01": (5000, 2000, 700), "single_root": (3500, 1400, 500),
           "dead_quiver_trunk": (3500, 1400, 500)}

def tri(o):
    o.data.calc_loop_triangles(); return len(o.data.loop_triangles)

def load(aid):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    f = glob.glob(os.path.join(SRC, aid, "*.gltf"))[0]
    bpy.ops.import_scene.gltf(filepath=f)
    ms = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    bpy.ops.object.select_all(action="DESELECT")
    for o in ms: o.select_set(True)
    bpy.context.view_layer.objects.active = ms[0]
    if len(ms) > 1: bpy.ops.object.join()
    return bpy.context.view_layer.objects.active

def convert_tex(aid):
    for kind, pat in (("diff", "*_diff_1k.*"), ("nor", "*_nor_gl_1k.*")):
        fs = [x for x in glob.glob(os.path.join(SRC, aid, "**", pat), recursive=True)]
        if fs:
            im = Image.open(fs[0]).convert("RGB"); im.thumbnail((1024, 1024)); im.save(os.path.join(TEX, f"{aid}_{kind}.jpg"), quality=85)

report = []
for aid, targets in TARGETS.items():
    if not os.path.isdir(os.path.join(SRC, aid)): continue
    convert_tex(aid)
    for lod, tgt in enumerate(targets):
        o = load(aid); n0 = tri(o)
        if n0 > tgt:
            m = o.modifiers.new("d", "DECIMATE"); m.ratio = max(tgt / n0, 0.005)
            bpy.ops.object.modifier_apply(modifier=m.name)
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        vs = [v.co for v in o.data.vertices]
        minz = min(v.z for v in vs); cx = (min(v.x for v in vs) + max(v.x for v in vs)) / 2; cy = (min(v.y for v in vs) + max(v.y for v in vs)) / 2
        for v in o.data.vertices: v.co.x -= cx; v.co.y -= cy; v.co.z -= minz
        bpy.ops.object.select_all(action="DESELECT"); o.select_set(True)
        p = os.path.join(OUT, f"{aid}_lod{lod}.glb")
        bpy.ops.export_scene.gltf(filepath=p, export_format="GLB", use_selection=True, export_yup=True, export_materials="NONE", export_apply=True)
        report.append((aid, lod, n0, tri(o), os.path.getsize(p)))
for r in report: print("BAKED %-20s lod%d src=%8d -> %6d tris %6.0f KB" % (r[0], r[1], r[2], r[3], r[4] / 1024))
