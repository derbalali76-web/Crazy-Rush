"""
توليد نموذج فوكسي ثلاثي الأبعاد بهيكل عظمي وحركات وتصديره GLB (Godot 4).

التشغيل (Blender 4.x/5.x أو وحدة bpy):
    blender -b -P tools/blender/build_foxy.py -- --out assets/characters/foxy.glb
أو:
    python3 tools/blender/build_foxy.py --out assets/characters/foxy.glb      (pip install bpy)

المدخلات: tools/blender/foxy_clips.json  (يُولَّد بـ: godot --headless -s tools/dump_clips.gd)
المخرجات: foxy.glb  (3 شبكات: Body, Scarf, Glossy + Skeleton3D + 13 مقطع حركة)

الاتجاه: الوجه نحو +Y في Blender (يصبح -Z في Godot). Z للأعلى.
الألوان تُخزَّن كـ Color Attribute (Float) وتُقرأ في Godot عبر شيدر الكرتون (COLOR).
"""
import json
import math
import os
import sys

import bpy
import bmesh
from mathutils import Euler, Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
OUT = os.path.join(HERE, "..", "..", "assets", "characters", "foxy.glb")
for i, a in enumerate(argv):
    if a == "--out" and i + 1 < len(argv):
        OUT = argv[i + 1]
OUT = os.path.abspath(OUT)
FPS = 60

# ------------------------------------------------------------------ ألوان (نفس ألوان Foxy.gd)
C_ORANGE = (1.0, 0.478, 0.094)
C_CREAM = (1.0, 0.941, 0.847)
C_DARK = (0.137, 0.133, 0.18)
C_BLACK = (0.078, 0.075, 0.102)
C_GREEN = (0.184, 0.761, 0.31)
C_GREEN_D = (0.11, 0.561, 0.227)
C_CYAN = (0.224, 0.839, 1.0)
C_STRAP = (0.176, 0.169, 0.227)
C_YELLOW = (1.0, 0.824, 0.227)
C_SHOE = (0.957, 0.957, 0.965)
C_EYE_G = (0.204, 0.761, 0.353)
C_BROW = (0.478, 0.184, 0.031)
C_EAR_IN = (0.93, 0.80, 0.68)

# godot (x,y,z) -> blender (x,-z,y)
M = Matrix(((1, 0, 0), (0, 0, -1), (0, 1, 0)))
M4 = M.to_4x4()
HIPS_Y = 0.70


def g2b(v):
    return Vector((v[0], -v[2], v[1] + HIPS_Y))


def xf(pos=(0, 0, 0), rot=(0, 0, 0), scl=(1, 1, 1), basis=None):
    """مصفوفة في فضاء Godot (أصلها عند الوركين) ثم تحويل إلى Blender."""
    b = basis if basis is not None else Euler(rot, "YXZ").to_matrix()
    s = Matrix.Diagonal(Vector(scl))
    t = (b @ s).to_4x4()
    t.translation = Vector(pos)
    full = M4 @ t
    full.translation = g2b(pos)
    return full


def aim(pos, direction, scl=(1, 1, 1)):
    y = Vector(direction).normalized()
    ref = Vector((0, 0, -1)) if abs(y.dot(Vector((0, 0, -1)))) < 0.9 else Vector((1, 0, 0))
    x = y.cross(ref).normalized()
    z = x.cross(y).normalized()
    b = Matrix(((x[0], y[0], z[0]), (x[1], y[1], z[1]), (x[2], y[2], z[2])))
    return xf(pos, scl=scl, basis=b)


# ------------------------------------------------------------------ منشئ الشبكات
class Builder:
    def __init__(self, name):
        self.name = name
        self.bm = bmesh.new()
        self.col = self.bm.loops.layers.float_color.new("Col")
        self.dvl = self.bm.verts.layers.deform.new()
        self.gids = {n: i for i, n in enumerate(BONES)}

    def _paint(self, verts, color, alpha=1.0):
        c = (color[0], color[1], color[2], alpha)
        for v in verts:
            for loop in v.link_loops:
                loop[self.col] = c

    def _finish(self, verts, color, wfn, alpha=1.0, smooth=True):
        verts = [v for v in verts]
        self._paint(verts, color, alpha)
        for v in verts:
            for bone, w in wfn(v.co.copy()).items():
                if w > 1e-4:
                    v[self.dvl][self.gids[bone]] = w
        for f in {f for v in verts for f in v.link_faces}:
            f.smooth = smooth

    def ellipsoid(self, r, color, mat, wfn, seg=16, rings=10, alpha=1.0):
        res = bmesh.ops.create_uvsphere(self.bm, u_segments=seg, v_segments=rings, radius=1.0,
                                        matrix=mat @ Matrix.Diagonal(Vector((r[0], r[1], r[2], 1.0))))
        self.bm.verts.index_update()
        self._finish(res["verts"], color, wfn, alpha)

    def cone(self, r_bottom, r_top, h, color, mat, wfn, seg=10):
        # قاعدة عند الأصل، تمتد على +Y (في فضاء Godot) => محور Z المحلي في Blender بعد التحويل
        res = bmesh.ops.create_cone(self.bm, cap_ends=True, cap_tris=False, segments=seg,
                                    radius1=r_bottom, radius2=r_top, depth=h,
                                    matrix=mat @ Matrix.Translation((0, h * 0.5, 0)) @ Matrix.Rotation(-math.pi / 2, 4, "X"))
        self.bm.verts.index_update()
        self._finish(res["verts"], color, wfn)

    def torus(self, major, minor, color, mat, wfn, seg=20, tube=6):
        verts = []
        ring = []
        for i in range(seg):
            a = math.tau * i / seg
            row = []
            for j in range(tube):
                b = math.tau * j / tube
                rr = major + minor * math.cos(b)
                p = Vector((math.cos(a) * rr, math.sin(a) * rr, minor * math.sin(b)))
                row.append(self.bm.verts.new(mat @ Matrix.Rotation(-math.pi / 2, 4, "X") @ p))
            ring.append(row)
        for i in range(seg):
            for j in range(tube):
                a = ring[i][j]
                b = ring[(i + 1) % seg][j]
                c = ring[(i + 1) % seg][(j + 1) % tube]
                d = ring[i][(j + 1) % tube]
                try:
                    self.bm.faces.new((a, b, c, d))
                except ValueError:
                    pass
            verts.extend(ring[i])
        self.bm.verts.index_update()
        bmesh.ops.recalc_face_normals(self.bm, faces=list({f for v in verts for f in v.link_faces}))
        self._finish(verts, color, wfn)

    def strip(self, pts, widths, color, wfn):
        """شريط مسطّح (الوشاح) بنقاط في فضاء Godot، عرضه على المحور X."""
        rows = []
        for p, w in zip(pts, widths):
            rows.append((self.bm.verts.new(g2b((p[0] - w, p[1], p[2]))),
                         self.bm.verts.new(g2b((p[0] + w, p[1], p[2])))))
        verts = [v for r in rows for v in r]
        for i in range(len(rows) - 1):
            self.bm.faces.new((rows[i][0], rows[i][1], rows[i + 1][1], rows[i + 1][0]))
        self.bm.verts.index_update()
        self._finish(verts, color, wfn, smooth=False)

    def to_object(self):
        me = bpy.data.meshes.new(self.name)
        self.bm.normal_update()
        self.bm.to_mesh(me)
        obj = bpy.data.objects.new(self.name, me)
        bpy.context.scene.collection.objects.link(obj)
        for n in BONES:
            obj.vertex_groups.new(name=n)
        return obj


# ------------------------------------------------------------------ العظام (فضاء Godot، نسبةً إلى الوركين)
BONES = {}   # name -> (parent, head, tail)


def _bone(name, parent, head, tail):
    BONES[name] = (parent, head, tail)


_bone("root", None, (0, -HIPS_Y, 0), (0, -HIPS_Y + 0.25, 0))
_bone("hips", "root", (0, 0, 0), (0, 0.3, 0))
_bone("head", "hips", (0, 0.82, -0.01), (0, 1.25, -0.01))
for s, sd in (("L", -1.0), ("R", 1.0)):
    _bone("arm." + s, "hips", (0.375 * sd, 0.43, 0), (0.375 * sd, 0.15, 0))
    _bone("forearm." + s, "arm." + s, (0.375 * sd, 0.15, 0), (0.375 * sd, -0.15, 0))
    _bone("thigh." + s, "hips", (0.14 * sd, -0.02, 0), (0.14 * sd, -0.30, 0))
    _bone("shin." + s, "thigh." + s, (0.14 * sd, -0.30, 0), (0.14 * sd, -0.58, 0))
    d = Vector((0.38 * sd, 1.0, 0.12)).normalized() * 0.5
    eh = Vector((0.26 * sd, 0.82 + 0.25, 0.0))
    _bone("ear." + s, "head", tuple(eh), tuple(eh + d))
_tz = 0.22
for i, ln in enumerate((0.297, 0.3375, 0.405)):
    _bone("tail.%d" % (i + 1), "hips" if i == 0 else "tail.%d" % i, (0, 0.06, _tz), (0, 0.06, _tz + ln))
    _tz += ln
_sz = 0.17
for i in range(3):
    _bone("scarf.%d" % (i + 1), "hips" if i == 0 else "scarf.%d" % i, (0, 0.50, _sz), (0, 0.50, _sz + 0.34))
    _sz += 0.34


def make_armature():
    arm = bpy.data.armatures.new("FoxyRig")
    obj = bpy.data.objects.new("FoxyRig", arm)
    bpy.context.scene.collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode="EDIT")
    for name, (parent, head, tail) in BONES.items():
        b = arm.edit_bones.new(name)
        b.head = g2b(head)
        b.tail = g2b(tail)
        if name.startswith(("arm.", "forearm.", "thigh.", "shin.")):
            b.roll = 0.0
    for name, (parent, _h, _t) in BONES.items():
        if parent:
            arm.edit_bones[name].parent = arm.edit_bones[parent]
            # لا نوصل الرؤوس: بعض الأطفال يبدؤون عند نقطة مختلفة عن ذيل الأب
    bpy.ops.object.mode_set(mode="OBJECT")
    return obj


# ------------------------------------------------------------------ دوال الأوزان
def only(bone):
    return lambda p: {bone: 1.0}


def blend_z(upper, lower, joint_z, w=0.075):
    """ينتقل الوزن من upper إلى lower حول ارتفاع المفصل (الأطراف رأسية في الوضع المرجعي)."""
    def f(p):
        t = min(max((joint_z - p.z) / (2 * w) + 0.5, 0.0), 1.0)
        return {upper: 1.0 - t, lower: t} if 0.0 < t < 1.0 else ({lower: 1.0} if t >= 1.0 else {upper: 1.0})
    return f


def build_body():
    b = Builder("Body")
    g = Builder("Glossy")
    sc = Builder("Scarf")
    H = only("hips")
    HD = only("head")

    # ---- الجذع
    b.ellipsoid((0.30, 0.17, 0.26), C_DARK, xf((0, -0.02, 0)), H, 16, 10)
    b.ellipsoid((0.29, 0.34, 0.25), C_ORANGE, xf((0, 0.22, 0)), H, 18, 12)
    b.ellipsoid((0.19, 0.25, 0.13), C_CREAM, xf((0, 0.20, -0.15)), H, 14, 10)
    b.torus(0.275, 0.028, C_STRAP, xf((0, 0.08, 0), scl=(1, 1, 0.9)).copy() @ Matrix.Identity(4), H)
    b.ellipsoid((0.05, 0.045, 0.02), C_YELLOW, xf((0, 0.08, -0.255)), H, 8, 6)
    b.torus(0.235, 0.085, C_GREEN, xf((0, 0.52, 0), (0.12, 0, 0), (1.0, 1.0, 0.92)), H, 22, 8)
    b.ellipsoid((0.10, 0.10, 0.09), C_GREEN_D, xf((0.20, 0.47, 0.05)), H, 10, 8)
    b.ellipsoid((0.07, 0.07, 0.03), C_YELLOW, xf((0.0, 0.47, -0.275)), H, 10, 6)   # نجمة الوشاح (مبسّطة)

    # ---- الرأس (أصله عند مفصل الرأس)
    hp = (0, 0.82, -0.01)

    def hx(p, rot=(0, 0, 0), scl=(1, 1, 1)):
        return xf((hp[0] + p[0], hp[1] + p[1], hp[2] + p[2]), rot, scl)

    b.ellipsoid((0.45, 0.37, 0.39), C_ORANGE, hx((0, 0, 0)), HD, 24, 16)
    b.ellipsoid((0.33, 0.21, 0.27), C_CREAM, hx((0, -0.13, -0.15)), HD, 16, 10)
    b.ellipsoid((0.17, 0.125, 0.15), C_CREAM, hx((0, -0.07, -0.385)), HD, 14, 10)
    b.ellipsoid((0.062, 0.045, 0.05), C_BLACK, hx((0, -0.018, -0.525)), HD, 10, 8)
    # ابتسامة (قوس رفيع من كرات صغيرة)
    for k in range(9):
        t = k / 8.0
        for sd in (-1.0, 1.0):
            x = t * 0.13
            y = -0.115 - math.sin(t * math.pi) * 0.035 + t * 0.045
            z = -0.512 + t * 0.07
            b.ellipsoid((0.014, 0.012, 0.012), (0.2, 0.07, 0.03), hx((sd * x, y, z)), HD, 6, 4)
    for sd in (-1.0, 1.0):
        # حاجب
        for a, c2 in (((0.30, 0.215, -0.30), (0.19, 0.205, -0.35)), ((0.19, 0.205, -0.35), (0.08, 0.155, -0.375))):
            mid = ((a[0] + c2[0]) / 2 * sd, (a[1] + c2[1]) / 2, (a[2] + c2[2]) / 2)
            b.ellipsoid((0.075, 0.03, 0.03), C_BROW, hx(mid, (0, 0, -0.35 * sd)), HD, 8, 6)
        # خصل الخدود
        b.cone(0.075, 0.0, 0.26, C_CREAM, aim((hp[0] + 0.38 * sd, hp[1] - 0.08, hp[2] - 0.12), (1.0 * sd, -0.1, 0.25)), HD, 8)
        b.cone(0.065, 0.0, 0.22, C_CREAM, aim((hp[0] + 0.36 * sd, hp[1] - 0.17, hp[2] - 0.07), (0.85 * sd, -0.45, 0.2)), HD, 8)
        b.cone(0.06, 0.0, 0.20, C_CREAM, aim((hp[0] + 0.37 * sd, hp[1] + 0.01, hp[2] - 0.12), (0.9 * sd, 0.3, 0.2)), HD, 8)
    b.torus(0.305, 0.034, C_STRAP, hx((0, 0.255, 0.0), (-0.1, 0, 0), (1.0, 1.0, 0.88)), HD, 24, 6)

    # ---- الأذنان (عظمة لكل أذن)
    for s, sd in (("L", -1.0), ("R", 1.0)):
        ear = only("ear." + s)
        base = (hp[0] + 0.26 * sd, hp[1] + 0.25, hp[2] + 0.01)
        dirv = (0.38 * sd, 1.0, 0.12)
        b.cone(0.185, 0.0, 0.52, C_ORANGE, aim(base, dirv, (1, 1, 0.55)), ear, 14)
        b.cone(0.12, 0.0, 0.40, C_EAR_IN, aim((base[0], base[1], base[2] - 0.045), dirv, (1, 1, 0.5)), ear, 12)
        dn = Vector(dirv).normalized()
        b.cone(0.075, 0.0, 0.17, C_BLACK, aim((base[0] + dn[0] * 0.37, base[1] + dn[1] * 0.37, base[2] + dn[2] * 0.37), dirv, (1, 1, 0.55)), ear, 10)

    # ---- النظارات والعينان (خامة لامعة)
    for sd in (-1.0, 1.0):
        rot = (-0.72, 0.0, -0.18 * sd)
        lp = (0.145 * sd, 0.315, -0.205)
        g.torus(0.108, 0.032, C_STRAP, hx(lp, rot), HD, 18, 6)
        g.ellipsoid((0.105, 0.028, 0.105), C_CYAN, hx(lp, rot), HD, 14, 8, alpha=0.62)
        ex = 0.185 * sd
        g.ellipsoid((0.108, 0.138, 0.06), (1, 1, 1), hx((ex, 0.055, -0.335), (0, 0.22 * sd, 0)), HD, 16, 12)
        g.ellipsoid((0.078, 0.108, 0.045), C_EYE_G, hx((ex + 0.004 * sd, 0.05, -0.376), (0, 0.2 * sd, 0)), HD, 14, 10)
        g.ellipsoid((0.046, 0.074, 0.032), C_BLACK, hx((ex + 0.006 * sd, 0.045, -0.396), (0, 0.2 * sd, 0)), HD, 12, 10)
        g.ellipsoid((0.024, 0.03, 0.02), (1, 1, 1), hx((ex - 0.025 * sd, 0.1, -0.413), (0, 0.2 * sd, 0)), HD, 8, 6, alpha=0.1)

    # ---- الذراعان
    for s, sd in (("L", -1.0), ("R", 1.0)):
        sh = (0.375 * sd, 0.43, 0)
        el = (0.375 * sd, 0.15, 0)
        wf = blend_z("arm." + s, "forearm." + s, el[2] if False else (el[1] + HIPS_Y))
        P = lambda dx, dy, dz, base=sh: (base[0] + dx, base[1] + dy, base[2] + dz)
        b.ellipsoid((0.095, 0.095, 0.095), C_ORANGE, xf(sh), wf, 12, 8)
        b.ellipsoid((0.075, 0.19, 0.075), C_ORANGE, xf(P(0, -0.14, 0)), wf, 12, 8)
        b.ellipsoid((0.078, 0.078, 0.078), C_ORANGE, xf(el), wf, 10, 8)
        b.ellipsoid((0.07, 0.15, 0.07), C_ORANGE, xf(P(0, -0.28 - 0.10, 0)), wf, 12, 8)
        b.torus(0.075, 0.042, C_CREAM, xf(P(0, -0.28 - 0.2, 0)), wf, 14, 6)
        b.ellipsoid((0.108, 0.105, 0.108), C_DARK, xf(P(0, -0.28 - 0.30, 0)), wf, 14, 10)
        b.ellipsoid((0.04, 0.045, 0.045), C_DARK, xf(P(0.07 * sd, -0.28 - 0.27, -0.06)), wf, 8, 6)
        b.ellipsoid((0.075, 0.03, 0.08), C_BLACK, xf(P(0, -0.28 - 0.34, -0.02)), wf, 10, 6)

    # ---- الساقان
    for s, sd in (("L", -1.0), ("R", 1.0)):
        hpv = (0.14 * sd, -0.02, 0)
        wf = blend_z("thigh." + s, "shin." + s, (-0.30 + HIPS_Y))
        P = lambda dx, dy, dz, base=hpv: (base[0] + dx, base[1] + dy, base[2] + dz)
        b.ellipsoid((0.115, 0.11, 0.115), C_DARK, xf(hpv), wf, 12, 8)
        b.ellipsoid((0.10, 0.19, 0.10), C_ORANGE, xf(P(0, -0.14, 0)), wf, 12, 8)
        b.ellipsoid((0.09, 0.09, 0.09), C_ORANGE, xf(P(0, -0.28, 0)), wf, 10, 8)
        b.ellipsoid((0.082, 0.16, 0.082), C_ORANGE, xf(P(0, -0.28 - 0.12, 0)), wf, 12, 8)
        b.torus(0.088, 0.045, C_CREAM, xf(P(0, -0.28 - 0.23, 0)), wf, 14, 6)
        b.ellipsoid((0.125, 0.093, 0.2), C_SHOE, xf(P(0, -0.28 - 0.30, -0.06)), wf, 16, 10)
        b.ellipsoid((0.128, 0.05, 0.12), C_GREEN, xf(P(0, -0.28 - 0.285, -0.10)), wf, 12, 8)
        b.ellipsoid((0.11, 0.075, 0.075), C_DARK, xf(P(0, -0.28 - 0.315, -0.2)), wf, 10, 8)
        b.ellipsoid((0.13, 0.032, 0.215), C_DARK, xf(P(0, -0.28 - 0.375, -0.06)), wf, 12, 6)

    # ---- الذيل (3 عظام)
    z0 = 0.22
    sizes = ((0.14, 0.14, 0.22), (0.18, 0.18, 0.25), (0.22, 0.22, 0.30))
    for k, r in enumerate(sizes):
        bn = only("tail.%d" % (k + 1))
        b.ellipsoid(r, C_ORANGE, xf((0, 0.06, z0 + r[2] * 0.75)), bn, 14, 10)
        if k == 2:
            b.ellipsoid((r[0] * 0.86, r[1] * 0.86, r[2] * 0.55), C_CREAM, xf((0, 0.06, z0 + r[2] * 1.55)), bn, 12, 8)
        z0 += r[2] * 1.35

    # ---- أطراف الوشاح (شرائط مزدوجة الوجه)
    z = 0.17
    for k in range(3):
        pts = [(0, 0.50, z + t * 0.34) for t in (0, 1 / 3, 2 / 3, 1)]
        wid = [0.17 + (0.2 if k < 2 else 0.14) * 0.0 + (((0.2 if k < 2 else 0.14) - 0.17) * t) for t in (0, 1 / 3, 2 / 3, 1)]
        sc.strip(pts, [w * 0.5 for w in wid], C_GREEN if k % 2 == 0 else (0.17, 0.70, 0.29), only("scarf.%d" % (k + 1)))
        z += 0.34
    return b, g, sc


def finish_mesh(builder, rig, mat_name):
    obj = builder.to_object()
    me = obj.data
    # مجموعات الرؤوس
    if not os.environ.get("NOSKIN"):
        mod = obj.modifiers.new("Armature", "ARMATURE")
        mod.object = rig
        obj.parent = rig
    me.color_attributes.active_color = me.color_attributes["Col"]
    me.color_attributes.render_color_index = 0
    mat = bpy.data.materials.new(mat_name)
    me.materials.append(mat)
    return obj


# ------------------------------------------------------------------ الحركات
NODE_BONES = [("hips", "hips"), ("head", "head"), ("arm_l", "arm.L"), ("elbow_l", "forearm.L"),
              ("arm_r", "arm.R"), ("elbow_r", "forearm.R"), ("leg_l", "thigh.L"), ("knee_l", "shin.L"),
              ("leg_r", "thigh.R"), ("knee_r", "shin.R")]

# معاملات الحركة الثانوية لكل مقطع: (انحناء الذيل، زاوية الأذن، رفرفة الأذن، سعة الوشاح، دورات الذيل)
SECONDARY = {
    "idle": (0.3, 0.05, 0.0, 0.2, 3), "run": (0.5, 0.30, 0.07, 1.0, 1), "dash": (0.5, 0.75, 0.12, 1.4, 1),
    "turn_l": (0.5, 0.30, 0.07, 1.0, 1), "turn_r": (0.5, 0.30, 0.07, 1.0, 1),
    "jump": (1.0, -0.12, 0.05, 1.2, 1), "fall": (0.2, 0.55, 0.1, 1.2, 1), "land": (0.4, 0.2, 0.0, 0.8, 1),
    "slide": (0.2, 0.85, 0.0, 0.6, 1), "stumble": (0.0, 0.1, 0.5, 1.0, 2), "pit_fall": (1.2, 0.9, 0.2, 1.6, 2),
    "victory": (0.8, -0.08, 0.05, 0.9, 1), "punch": (0.5, 0.30, 0.07, 1.0, 1),
    "punch_l": (0.5, 0.30, 0.07, 1.0, 1),
}


def build_actions(rig, clips):
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode="POSE")
    arm = rig.data
    rest = {n: arm.bones[n].matrix_local.to_3x3() for n in BONES}
    rest_inv = {n: rest[n].inverted() for n in BONES}
    for pb in rig.pose.bones:
        pb.rotation_mode = "QUATERNION"
    rig.animation_data_create()
    actions = {}

    def rot_q(bone, eul_godot):
        rg = Euler(eul_godot, "YXZ").to_matrix()
        rb = M @ rg @ M.inverted()
        return (rest_inv[bone] @ rb @ rest[bone]).to_quaternion()

    for name, clip in clips.items():
        act = bpy.data.actions.new(name)
        act.use_fake_user = True
        rig.animation_data.action = act
        frames = clip["frames"]
        n = len(frames) - 1
        length = clip["length"]
        total = max(int(round(length * FPS)), 1)
        tail_curl, ear_base, ear_flut, scarf_amp, cycles = SECONDARY[name]
        for pb in rig.pose.bones:
            pb.rotation_quaternion = (1, 0, 0, 0)
            pb.location = (0, 0, 0)
        for k in range(n + 1):
            u = k / n
            frame = 1 + u * total
            row = frames[k]
            for j, (_node, bone) in enumerate(NODE_BONES):
                e = (row[1 + j * 3], row[2 + j * 3], row[3 + j * 3])
                pb = rig.pose.bones[bone]
                pb.rotation_quaternion = rot_q(bone, e)
                pb.keyframe_insert("rotation_quaternion", frame=frame)
            hp = rig.pose.bones["hips"]
            hp.location = rest_inv["hips"] @ Vector((0, 0, row[0] - HIPS_Y))
            hp.keyframe_insert("location", frame=frame)
            lean = -1.0 if name == "turn_l" else (1.0 if name == "turn_r" else 0.0)
            # ذيل
            for i in range(3):
                ph = math.tau * cycles * u - i * 0.9
                e = (-0.28 - tail_curl * 0.12 + math.sin(ph * 0.7) * 0.06,
                     math.sin(ph) * (0.18 + 0.05 * i) - lean * 0.15, 0.0)
                pb = rig.pose.bones["tail.%d" % (i + 1)]
                pb.rotation_quaternion = rot_q(pb.name, e)
                pb.keyframe_insert("rotation_quaternion", frame=frame)
            # وشاح
            for i in range(3):
                ph = math.tau * 2 * cycles * u - i * 1.1
                fl = (0.12 + 0.28 * scarf_amp * 0.5)
                e = (0.12 + math.sin(ph) * fl * 0.4 + (0.35 if i == 0 else 0.0), math.sin(ph * 0.8 + 1.0) * fl, 0.0)
                pb = rig.pose.bones["scarf.%d" % (i + 1)]
                pb.rotation_quaternion = rot_q(pb.name, e)
                pb.keyframe_insert("rotation_quaternion", frame=frame)
            # أذنان
            for sidx, s in enumerate(("L", "R")):
                ph = math.tau * 3 * u + sidx * 1.7
                e = (ear_base + math.sin(ph) * ear_flut, 0.0, -0.06 * (1 if s == "L" else -1) - lean * 0.1)
                pb = rig.pose.bones["ear." + s]
                pb.rotation_quaternion = rot_q(pb.name, e)
                pb.keyframe_insert("rotation_quaternion", frame=frame)
        act.use_frame_range = True
        act.frame_start = 1
        act.frame_end = 1 + total
        act.use_cyclic = bool(clip["loop"])
        actions[name] = act
    bpy.ops.object.mode_set(mode="OBJECT")
    rig.animation_data.action = actions["idle"]
    return actions


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.render.fps = FPS
    with open(os.path.join(HERE, "foxy_clips.json")) as f:
        clips = json.load(f)
    rig = make_armature()
    body, glossy, scarf = build_body()
    ob = finish_mesh(body, rig, "FoxyBody")
    og = finish_mesh(glossy, rig, "FoxyGlossy")
    osf = finish_mesh(scarf, rig, "FoxyScarf")
    ob.name, og.name, osf.name = "Body", "Glossy", "Scarf"
    build_actions(rig, clips)
    # الأوجه تُقرأ بوضعها: لا نُطبّق المعدّلات (الجلد يُصدَّر كما هو)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    bpy.ops.object.select_all(action="SELECT")
    kw = dict(filepath=OUT, export_format="GLB", export_animations=True, export_skins=True,
              export_apply=False, export_yup=True, export_cameras=False, export_lights=False)
    for k, v in (("export_animation_mode", "ACTIONS"), ("export_force_sampling", True),
                 ("export_vertex_color", "ACTIVE"), ("export_active_vertex_color_when_no_material", True),
                 ("export_optimize_animation_size", False), ("export_def_bones", False),
                 ("export_materials", "EXPORT")):
        kw[k] = v
    try:
        bpy.ops.export_scene.gltf(**kw)
    except TypeError as e:
        print("بعض خيارات المصدّر غير مدعومة:", e)
        for k in ("export_vertex_color", "export_active_vertex_color_when_no_material", "export_animation_mode",
                  "export_optimize_animation_size", "export_def_bones", "export_materials"):
            kw.pop(k, None)
        bpy.ops.export_scene.gltf(**kw)
    tris = sum(len(o.data.polygons) for o in (ob, og, osf))
    print("EXPORTED", OUT, os.path.getsize(OUT), "bytes; faces:", tris, "bones:", len(BONES), "clips:", len(clips))


main()
