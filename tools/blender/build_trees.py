"""يولّد أشجار غابة (جذع مدبّب + فروع + أكوام أوراق حقيقية من مجسم الكالاثيا المبسّط) بثلاثة LOD.
المخرجات: assets/art/props/tree_{a,b}_lod{0,1,2}.glb  (سطحان: 0=لحاء، 1=أوراق)
التشغيل: python3 -I tools/blender/build_trees.py   (بعد bake_props.py)"""
import bpy, bmesh, math, random, os
from mathutils import Vector, Matrix, Euler
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "assets/art/props")

def new_mat(name):
    m = bpy.data.materials.new(name); m.use_nodes = False; return m

def tube(bm, pts, radii, sides, uv_scale=1.0):
    """أنبوب مدبّب عبر نقاط؛ يعيد حلقاته. UV أسطواني."""
    rings = []
    uv = bm.loops.layers.uv.verify()
    for i, (p, r) in enumerate(zip(pts, radii)):
        t = (pts[min(i + 1, len(pts) - 1)] - pts[max(i - 1, 0)]).normalized()
        a = Vector((1, 0, 0)) if abs(t.x) < 0.9 else Vector((0, 1, 0))
        n1 = t.cross(a).normalized(); n2 = t.cross(n1).normalized()
        ring = [bm.verts.new(p + (n1 * math.cos(2 * math.pi * k / sides) + n2 * math.sin(2 * math.pi * k / sides)) * r) for k in range(sides)]
        rings.append(ring)
    vlen = 0.0; vs = [0.0]
    for i in range(1, len(pts)):
        vlen += (pts[i] - pts[i - 1]).length; vs.append(vlen)
    for i in range(len(rings) - 1):
        for k in range(sides):
            k2 = (k + 1) % sides
            f = bm.faces.new((rings[i][k], rings[i][k2], rings[i + 1][k2], rings[i + 1][k]))
            f.material_index = 0
            for lp, (kk, ii) in zip(f.loops, ((k, i), (k + 1, i), (k + 1, i + 1), (k, i + 1))):
                lp[uv].uv = (kk / sides * 2.0, vs[ii] * uv_scale)
    return rings

def bez(p0, p1, p2, n):
    return [((1 - t) ** 2) * p0 + 2 * (1 - t) * t * p1 + t * t * p2 for t in [i / (n - 1) for i in range(n)]]

def load_leaf(lod):
    bpy.ops.import_scene.gltf(filepath=os.path.join(OUT, f"calathea_lod{lod}.glb"))
    o = [x for x in bpy.context.scene.objects if x.type == "MESH"][-1]
    me = o.data.copy(); bpy.data.objects.remove(o)
    return me

def build(name, seed, lod, trunk_h, spread, nbranch, leaf_per, leaf_scale):
    random.seed(seed)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bark, leaf = new_mat("bark"), new_mat("leaf")
    sides = (10, 7, 5)[lod]; nring = (12, 8, 5)[lod]
    bm = bmesh.new()
    # الجذع: منحنى لطيف مع قاعدة عريضة (جذور)
    lean = Vector((random.uniform(-0.6, 0.6), random.uniform(-0.6, 0.6), 0))
    p0 = Vector((0, 0, -0.2)); p1 = Vector((lean.x * 0.5, lean.y * 0.5, trunk_h * 0.55)); p2 = Vector((lean.x, lean.y, trunk_h))
    pts = bez(p0, p1, p2, nring)
    rad = [0.55 * (1 - t) ** 1.2 * 0.62 + 0.10 + (0.32 * max(0.0, 1 - t * 7) ** 2) for t in [i / (nring - 1) for i in range(nring)]]
    tube(bm, pts, rad, sides, 0.35)
    tips = []
    for b in range(nbranch):
        t0 = random.uniform(0.45, 0.9); i0 = int(t0 * (nring - 1))
        base = pts[i0]
        ang = random.uniform(0, 2 * math.pi); out = Vector((math.cos(ang), math.sin(ang), 0)) * spread * random.uniform(0.7, 1.2)
        tip = base + out + Vector((0, 0, random.uniform(0.6, 1.8)))
        mid = base + out * 0.5 + Vector((0, 0, random.uniform(0.2, 0.9)))
        bp = bez(base, mid, tip, 4 if lod < 2 else 3)
        br = [max(0.03, 0.13 * (1 - i / (len(bp) - 1))) for i in range(len(bp))]
        tube(bm, bp, br, 5 if lod < 2 else 4, 0.35)
        tips.append(tip)
        if lod == 0:
            tips.append(mid + Vector((0, 0, 0.3)))   # كتلة أوراق إضافية على منتصف الفرع (LOD0 فقط)
    tips.append(pts[-1] + Vector((0, 0, 0.5)))
    # الأوراق: أكوام من مجسم ورقة حقيقي
    leaf_mesh = load_leaf(2)   # الكتلة الأخف (333 مثلثًا = 5 أوراق) تكفي لكل المستويات
    lm = bmesh.new(); lm.from_mesh(leaf_mesh)
    luv = lm.loops.layers.uv.verify() if lm.loops.layers.uv else None
    uvl = bm.loops.layers.uv.verify()
    for tip in tips:
        for j in range(leaf_per):
            pos = tip + Vector((random.gauss(0, spread * 0.35), random.gauss(0, spread * 0.35), random.gauss(0, 0.5)))
            rot = Euler((random.uniform(-0.9, 0.9), random.uniform(-0.9, 0.9), random.uniform(0, 6.28)))
            mat = Matrix.Translation(pos) @ rot.to_matrix().to_4x4() @ Matrix.Scale(leaf_scale * random.uniform(0.8, 1.3), 4)
            vmap = {}
            for v in lm.verts:
                vmap[v.index] = bm.verts.new(mat @ v.co)
            for f in lm.faces:
                try:
                    nf = bm.faces.new([vmap[v.index] for v in f.verts])
                except ValueError:
                    continue
                nf.material_index = 1
                if luv:
                    for lp_new, lp_old in zip(nf.loops, f.loops):
                        lp_new[uvl].uv = lp_old[luv].uv
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    me.materials.append(bark); me.materials.append(leaf)
    ob = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(ob)
    bpy.ops.object.select_all(action="DESELECT"); ob.select_set(True); bpy.context.view_layer.objects.active = ob
    me.calc_loop_triangles()
    path = os.path.join(OUT, f"{name}_lod{lod}.glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True, export_yup=True, export_materials="EXPORT", export_image_format="NONE")
    return len(me.loop_triangles), os.path.getsize(path)

# المتغيّران a (طويل مستدير) وb (أعرض)
CFG = {"tree_a": dict(seed=11, trunk_h=7.5, spread=2.4, nbranch=6, leaf_per=(3, 2, 1), leaf_scale=(2.3, 2.7, 3.3)),
       "tree_b": dict(seed=29, trunk_h=6.0, spread=3.2, nbranch=7, leaf_per=(3, 2, 1), leaf_scale=(2.4, 2.8, 3.4))}
for name, c in CFG.items():
    for lod in range(3):
        tris, size = build(name, c["seed"], lod, c["trunk_h"], c["spread"], c["nbranch"], c["leaf_per"][lod], c["leaf_scale"][lod])
        print("TREE %-7s lod%d tris=%6d  %5.0f KB" % (name, lod, tris, size / 1024))
