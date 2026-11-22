class_name Foxy
extends Node3D
## فوكسي الثعلب — شخصية ثلاثية الأبعاد مبنية برمجيًا (أصلية 100%) بأسلوب Stylized Low-Poly.
## الوجه إلى -Z. الأصل عند القدمين. الحركات إجرائية (Procedural) بمفاصل حقيقية.

enum Anim { IDLE, RUN, JUMP, SLIDE, STUMBLE, FALL, DASH, CHEER }

const SCALE_FACTOR := 0.85

# ألوان (sRGB)
const C_ORANGE := Color("ff7a18")
const C_ORANGE_D := Color("e0560c")
const C_CREAM := Color("fff0d8")
const C_DARK := Color("23222e")
const C_BLACK := Color("14131a")
const C_GREEN := Color("2fc24f")
const C_GREEN_D := Color("1c8f3a")
const C_CYAN := Color("39d6ff")
const C_STRAP := Color("2d2b3a")
const C_YELLOW := Color("ffd23a")
const C_SHOE := Color("f4f4f6")
const C_EYE_G := Color("34c25a")
const C_BROW := Color("7a2f08")

var anim: int = Anim.IDLE
var run_speed := 0.0          # م/ث — يتحكم بإيقاع الجري
var lean := 0.0               # -1..1 ميل التوجيه
var vy := 0.0                 # السرعة الرأسية (للقفز)
var punch_t := -1.0           # >= 0 أثناء الضرب
var invuln_flash := false

var _phase := 0.0
var _time := 0.0
var _pose := PackedFloat32Array()
var _target := PackedFloat32Array()

var body: Node3D
var hips: Node3D
var head: Node3D
var arm_l: Node3D
var elbow_l: Node3D
var arm_r: Node3D
var elbow_r: Node3D
var leg_l: Node3D
var knee_l: Node3D
var leg_r: Node3D
var knee_r: Node3D
var tail: Array[Node3D] = []
var scarf: Array[Node3D] = []
var _meshes: Array[MeshInstance3D] = []

const P_HIPY := 0
const P_HRX := 1
const P_HRY := 2
const P_HRZ := 3
const P_HDX := 4
const P_HDZ := 5
const P_ALX := 6
const P_ALZ := 7
const P_AEL := 8
const P_ARX := 9
const P_ARZ := 10
const P_AER := 11
const P_LLX := 12
const P_LKL := 13
const P_LRX := 14
const P_LKR := 15
const P_TAIL := 16
const P_COUNT := 17


func _ready() -> void:
	if body == null:
		build()


func build(outline := true) -> void:
	if body != null:
		return
	_pose.resize(P_COUNT)
	_target.resize(P_COUNT)
	var mat_solid := Toon.solid(outline, 0.016)
	var mat_gloss := Toon.glossy(outline, 0.012)

	body = Node3D.new()
	body.name = "Body"
	add_child(body)
	hips = Node3D.new()
	hips.position = Vector3(0, 0.70, 0)
	body.add_child(hips)

	_build_torso(mat_solid)
	_build_head(mat_solid, mat_gloss)
	_build_arms(mat_solid)
	_build_legs(mat_solid)
	_build_tail(mat_solid)
	_build_scarf_tails(mat_solid)
	scale = Vector3.ONE * SCALE_FACTOR
	_apply_pose_instant()


func _mi(mb: MeshBuilder, parent: Node3D, mat: Material, pos := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mb.build()
	mi.material_override = mat
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(mi)
	_meshes.append(mi)
	return mi


static func _pivot(parent: Node3D, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	parent.add_child(n)
	return n


## تحويل يوجّه المحور +Y نحو الاتجاه dir مع موضع pos (للمخاريط).
static func _aim(pos: Vector3, dir: Vector3, scale_xyz := Vector3.ONE) -> Transform3D:
	var y := dir.normalized()
	var ref := Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
	var x := y.cross(ref).normalized()
	var z := x.cross(y).normalized()
	var b := Basis(x, y, z)
	b = b * Basis.from_scale(scale_xyz)
	return Transform3D(b, pos)


static func _xf(pos: Vector3, rot := Vector3.ZERO, scl := Vector3.ONE) -> Transform3D:
	var b := Basis.from_euler(rot) * Basis.from_scale(scl)
	return Transform3D(b, pos)


# ------------------------------------------------------------------ الجذع
func _build_torso(mat: Material) -> void:
	var mb := MeshBuilder.new()
	# شورت داكن
	mb.add_ellipsoid(Vector3(0.30, 0.17, 0.26), C_DARK, _xf(Vector3(0, -0.02, 0)), 14, 8)
	# الجذع البرتقالي
	mb.add_ellipsoid(Vector3(0.29, 0.34, 0.25), C_ORANGE, _xf(Vector3(0, 0.22, 0)), 16, 10, C_ORANGE.lightened(0.08))
	# البطن الكريمي
	mb.add_ellipsoid(Vector3(0.19, 0.25, 0.13), C_CREAM, _xf(Vector3(0, 0.20, -0.15)), 12, 8)
	# حزام
	mb.add_torus(0.275, 0.028, C_STRAP, _xf(Vector3(0, 0.08, 0), Vector3.ZERO, Vector3(1, 1, 0.9)), 18, 6)
	mb.add_ellipsoid(Vector3(0.05, 0.045, 0.02), C_YELLOW, _xf(Vector3(0, 0.08, -0.255)), 8, 6)
	# وشاح أخضر حول الرقبة
	mb.add_torus(0.235, 0.085, C_GREEN, _xf(Vector3(0, 0.52, 0), Vector3(0.12, 0, 0), Vector3(1.0, 1.0, 0.92)), 20, 8)
	# عقدة الوشاح + نجمة
	mb.add_ellipsoid(Vector3(0.10, 0.10, 0.09), C_GREEN_D, _xf(Vector3(0.20, 0.47, 0.05)), 10, 7)
	mb.add_star(0.09, 0.04, 0.03, C_YELLOW, _xf(Vector3(0.0, 0.47, -0.27), Vector3(0.1, 0, 0.0)))
	_mi(mb, hips, mat)


# ------------------------------------------------------------------ الرأس
func _build_head(mat: Material, mat_gloss: Material) -> void:
	head = _pivot(hips, Vector3(0, 0.82, -0.01))
	var mb := MeshBuilder.new()
	# جمجمة
	mb.add_ellipsoid(Vector3(0.45, 0.37, 0.39), C_ORANGE, Transform3D.IDENTITY, 20, 14, C_ORANGE.lightened(0.07))
	# أسفل الوجه والخدود (كريمي)
	mb.add_ellipsoid(Vector3(0.33, 0.21, 0.27), C_CREAM, _xf(Vector3(0, -0.13, -0.15)), 16, 10)
	# كمامة الأنف
	mb.add_ellipsoid(Vector3(0.17, 0.125, 0.15), C_CREAM, _xf(Vector3(0, -0.07, -0.385)), 12, 8)
	mb.add_ellipsoid(Vector3(0.062, 0.045, 0.05), C_BLACK, _xf(Vector3(0, -0.018, -0.525)), 10, 7)
	# ابتسامة
	var smile_l: Array = []
	var smile_r: Array = []
	for k in range(7):
		var t := float(k) / 6.0
		var x := lerpf(0.0, 0.13, t)
		var y := -0.115 - sin(t * PI) * 0.035 + t * 0.045
		var z := -0.512 + t * 0.07
		smile_l.append(Vector3(-x, y, z))
		smile_r.append(Vector3(x, y, z))
	mb.add_tube(smile_l, 0.011, C_BROW.darkened(0.4), 5, Transform3D.IDENTITY, false, false)
	mb.add_tube(smile_r, 0.011, C_BROW.darkened(0.4), 5, Transform3D.IDENTITY, false, false)
	# حاجبان بتعبير واثق
	for s: float in [-1.0, 1.0]:
		mb.add_tube([Vector3(0.30 * s, 0.215, -0.30), Vector3(0.19 * s, 0.205, -0.35), Vector3(0.08 * s, 0.155, -0.375)], 0.026, C_BROW, 6, Transform3D.IDENTITY, true, true)
	# خصل الخدود (كريمية)
	for s: float in [-1.0, 1.0]:
		mb.add_cylinder(0.075, 0.0, 0.26, C_CREAM, _aim(Vector3(0.38 * s, -0.08, -0.12), Vector3(1.0 * s, -0.1, 0.25)), 8)
		mb.add_cylinder(0.065, 0.0, 0.22, C_CREAM, _aim(Vector3(0.36 * s, -0.17, -0.07), Vector3(0.85 * s, -0.45, 0.2)), 8)
		mb.add_cylinder(0.06, 0.0, 0.2, C_CREAM, _aim(Vector3(0.37 * s, 0.01, -0.12), Vector3(0.9 * s, 0.3, 0.2)), 8)
	# الأذنان
	for s: float in [-1.0, 1.0]:
		var dirv := Vector3(0.38 * s, 1.0, 0.12).normalized()
		var base_pos := Vector3(0.26 * s, 0.25, 0.01)
		mb.add_cylinder(0.185, 0.0, 0.52, C_ORANGE, _aim(base_pos, dirv, Vector3(1, 1, 0.55)), 12)
		mb.add_cylinder(0.12, 0.0, 0.40, C_CREAM.darkened(0.08), _aim(base_pos + Vector3(0, 0.0, -0.045), dirv, Vector3(1, 1, 0.5)), 10)
		mb.add_cylinder(0.075, 0.0, 0.17, C_BLACK, _aim(base_pos + dirv * 0.37 + Vector3(0, 0, 0.002), dirv, Vector3(1, 1, 0.55)), 10)
	# حزام النظارات
	mb.add_torus(0.305, 0.034, C_STRAP, _xf(Vector3(0, 0.255, 0.0), Vector3(-0.1, 0, 0), Vector3(1.0, 1.0, 0.88)), 22, 6)
	_mi(mb, head, mat)

	# عدسات النظارات (لامعة) + العينان
	var mg := MeshBuilder.new()
	for s: float in [-1.0, 1.0]:
		var rot := Vector3(-0.72, 0.0, -0.18 * s)
		var lens_pos := Vector3(0.145 * s, 0.315, -0.205)
		mg.add_torus(0.108, 0.032, C_STRAP, _xf(lens_pos, rot), 18, 6)
		mg.add_ellipsoid(Vector3(0.105, 0.028, 0.105), Color(C_CYAN.r, C_CYAN.g, C_CYAN.b, 0.62), _xf(lens_pos + Vector3(0, 0.0, 0), rot), 14, 6)
		mg.add_ellipsoid(Vector3(0.035, 0.012, 0.022), Color(1, 1, 1, 0.3), _xf(lens_pos + Vector3(-0.03 * s, 0.03, -0.045), rot), 8, 5)
		# العين
		var ex := 0.185 * s
		mg.add_ellipsoid(Vector3(0.108, 0.138, 0.06), Color.WHITE, _xf(Vector3(ex, 0.055, -0.335), Vector3(0, 0.22 * s, 0)), 14, 10)
		mg.add_ellipsoid(Vector3(0.078, 0.108, 0.045), C_EYE_G, _xf(Vector3(ex + 0.004 * s, 0.05, -0.376), Vector3(0, 0.2 * s, 0)), 12, 8)
		mg.add_ellipsoid(Vector3(0.046, 0.074, 0.032), C_BLACK, _xf(Vector3(ex + 0.006 * s, 0.045, -0.396), Vector3(0, 0.2 * s, 0)), 10, 8)
		mg.add_ellipsoid(Vector3(0.024, 0.03, 0.02), Color(1, 1, 1, 0.1), _xf(Vector3(ex - 0.025 * s, 0.1, -0.413), Vector3(0, 0.2 * s, 0)), 8, 6)
		mg.add_ellipsoid(Vector3(0.012, 0.014, 0.01), Color(1, 1, 1, 0.1), _xf(Vector3(ex + 0.03 * s, 0.0, -0.42), Vector3(0, 0.2 * s, 0)), 6, 5)
	_mi(mg, head, mat_gloss)


# ------------------------------------------------------------------ الذراعان
func _build_arms(mat: Material) -> void:
	for side in [-1, 1]:
		var s := float(side)
		var sh := _pivot(hips, Vector3(0.325 * s, 0.43, 0.0))
		var mb := MeshBuilder.new()
		mb.add_ellipsoid(Vector3(0.095, 0.095, 0.095), C_ORANGE, Transform3D.IDENTITY, 10, 7)
		mb.add_capsule(0.075, 0.34, C_ORANGE, _xf(Vector3(0, -0.14, 0)), 10, 4, C_ORANGE.lightened(0.05))
		_mi(mb, sh, mat)
		var el := _pivot(sh, Vector3(0, -0.28, 0))
		var mf := MeshBuilder.new()
		mf.add_ellipsoid(Vector3(0.078, 0.078, 0.078), C_ORANGE, Transform3D.IDENTITY, 8, 6)
		mf.add_capsule(0.07, 0.26, C_ORANGE, _xf(Vector3(0, -0.10, 0)), 10, 4)
		mf.add_torus(0.075, 0.042, C_CREAM, _xf(Vector3(0, -0.2, 0)), 12, 6)
		# القفاز الأسود
		mf.add_ellipsoid(Vector3(0.108, 0.105, 0.108), C_DARK, _xf(Vector3(0, -0.30, 0)), 12, 8)
		mf.add_ellipsoid(Vector3(0.04, 0.045, 0.045), C_DARK, _xf(Vector3(0.07 * s, -0.27, -0.06)), 8, 6)
		mf.add_ellipsoid(Vector3(0.075, 0.03, 0.08), C_BLACK, _xf(Vector3(0, -0.34, -0.02)), 8, 5)
		_mi(mf, el, mat)
		if side < 0:
			arm_l = sh
			elbow_l = el
		else:
			arm_r = sh
			elbow_r = el


# ------------------------------------------------------------------ الساقان
func _build_legs(mat: Material) -> void:
	for side in [-1, 1]:
		var s := float(side)
		var hp := _pivot(hips, Vector3(0.14 * s, -0.02, 0.0))
		var mb := MeshBuilder.new()
		mb.add_ellipsoid(Vector3(0.115, 0.11, 0.115), C_DARK, Transform3D.IDENTITY, 10, 7)
		mb.add_capsule(0.10, 0.34, C_ORANGE, _xf(Vector3(0, -0.14, 0)), 10, 4)
		_mi(mb, hp, mat)
		var kn := _pivot(hp, Vector3(0, -0.28, 0))
		var mf := MeshBuilder.new()
		mf.add_ellipsoid(Vector3(0.09, 0.09, 0.09), C_ORANGE, Transform3D.IDENTITY, 8, 6)
		mf.add_capsule(0.082, 0.30, C_ORANGE, _xf(Vector3(0, -0.12, 0)), 10, 4)
		mf.add_torus(0.088, 0.045, C_CREAM, _xf(Vector3(0, -0.23, 0)), 12, 6)
		# الحذاء: أبيض مع شريط أخضر ومقدمة داكنة ونعل
		mf.add_ellipsoid(Vector3(0.125, 0.093, 0.2), C_SHOE, _xf(Vector3(0, -0.30, -0.06)), 14, 9, C_SHOE)
		mf.add_ellipsoid(Vector3(0.128, 0.05, 0.12), C_GREEN, _xf(Vector3(0, -0.285, -0.10)), 12, 7)
		mf.add_ellipsoid(Vector3(0.11, 0.075, 0.075), C_DARK, _xf(Vector3(0, -0.315, -0.2)), 10, 7)
		mf.add_ellipsoid(Vector3(0.13, 0.032, 0.215), C_DARK, _xf(Vector3(0, -0.375, -0.06)), 12, 6)
		_mi(mf, kn, mat)
		if side < 0:
			leg_l = hp
			knee_l = kn
		else:
			leg_r = hp
			knee_r = kn


# ------------------------------------------------------------------ الذيل
func _build_tail(mat: Material) -> void:
	var parent: Node3D = _pivot(hips, Vector3(0, 0.06, 0.22))
	var sizes := [Vector3(0.14, 0.14, 0.22), Vector3(0.18, 0.18, 0.25), Vector3(0.22, 0.22, 0.30)]
	for k in range(3):
		var mb := MeshBuilder.new()
		var r: Vector3 = sizes[k]
		mb.add_ellipsoid(r, C_ORANGE, _xf(Vector3(0, 0, r.z * 0.75)), 14, 9, C_ORANGE.lightened(0.06))
		if k == 2:
			# طرف الذيل أبيض
			mb.add_ellipsoid(Vector3(r.x * 0.86, r.y * 0.86, r.z * 0.55), C_CREAM, _xf(Vector3(0, 0, r.z * 1.55)), 12, 8)
		_mi(mb, parent, mat)
		tail.append(parent)
		var nxt := _pivot(parent, Vector3(0, 0, r.z * 1.35))
		parent = nxt


# ------------------------------------------------------------------ ذيول الوشاح
func _build_scarf_tails(mat: Material) -> void:
	var parent: Node3D = _pivot(hips, Vector3(0.0, 0.50, 0.17))
	for k in range(3):
		var mb := MeshBuilder.new()
		var pts: Array = []
		var wid: Array = []
		for j in range(4):
			var t := float(j) / 3.0
			pts.append(Vector3(0, -t * 0.0, t * 0.34))
			wid.append(lerpf(0.17, 0.2 if k < 2 else 0.14, t))
		mb.add_strip(pts, wid, C_GREEN if k % 2 == 0 else C_GREEN.darkened(0.08), Vector3.RIGHT, Transform3D.IDENTITY, C_GREEN_D)
		if k == 2:
			mb.add_star(0.07, 0.032, 0.012, C_YELLOW, _xf(Vector3(0, 0.0, 0.2), Vector3(-PI * 0.5, 0, 0)))
		_mi(mb, parent, Toon.double_sided(false))
		scarf.append(parent)
		parent = _pivot(parent, Vector3(0, 0, 0.34))


# ================================================================== الحركة
func play(a: int) -> void:
	anim = a


func start_punch() -> void:
	punch_t = 0.0


func _process(delta: float) -> void:
	if body == null:
		return
	_time += delta
	_compute_target(delta)
	var k := 1.0 - exp(-delta * (16.0 if anim != Anim.IDLE else 8.0))
	for i in range(P_COUNT):
		_pose[i] = lerpf(_pose[i], _target[i], k)
	_apply_pose()
	_update_chains(delta)


func _compute_target(delta: float) -> void:
	var t := _target
	for i in range(P_COUNT):
		t[i] = 0.0
	t[P_TAIL] = 0.0
	match anim:
		Anim.RUN, Anim.DASH:
			var sp := maxf(run_speed, 6.0)
			var mult := 1.0 if anim == Anim.RUN else 1.35
			_phase += delta * (sp * 0.62) * mult
			var ph := _phase
			var s := sin(ph)
			var c := cos(ph)
			var ph2 := ph + PI
			var s2 := sin(ph2)
			var c2 := cos(ph2)
			var dash := 1.0 if anim == Anim.DASH else 0.0
			t[P_HIPY] = absf(s) * 0.07 - 0.05 - 0.02 * dash
			t[P_HRX] = -0.2 - 0.05 * clampf(sp - 10.0, 0.0, 6.0) / 6.0 - 0.35 * dash
			t[P_HRY] = s * 0.14 - lean * 0.28
			t[P_HRZ] = -lean * 0.24 + s * 0.04
			t[P_HDX] = 0.18 + 0.2 * dash
			t[P_HDZ] = lean * 0.1
			t[P_LLX] = s * 0.95 + 0.1 * dash
			t[P_LKL] = -(0.25 + 1.05 * maxf(0.0, c))
			t[P_LRX] = s2 * 0.95 + 0.1 * dash
			t[P_LKR] = -(0.25 + 1.05 * maxf(0.0, c2))
			if dash > 0.5:
				t[P_ALX] = -1.5
				t[P_ARX] = -1.5
				t[P_AEL] = 0.3
				t[P_AER] = 0.3
				t[P_ALZ] = 0.25
				t[P_ARZ] = -0.25
			else:
				t[P_ALX] = -s * 1.0 - 0.1
				t[P_ARX] = -s2 * 1.0 - 0.1
				t[P_AEL] = 1.15 + 0.25 * c
				t[P_AER] = 1.15 + 0.25 * c2
				t[P_ALZ] = 0.12
				t[P_ARZ] = -0.12
			t[P_TAIL] = 0.5 + 0.2 * s
		Anim.JUMP:
			var rising := vy > 0.0
			t[P_HIPY] = 0.02
			t[P_HRX] = -0.12 if rising else 0.05
			t[P_HRZ] = -lean * 0.15
			t[P_HDX] = 0.2
			if rising:
				t[P_ALX] = 2.7
				t[P_ARX] = 2.7
				t[P_ALZ] = 0.2
				t[P_ARZ] = -0.2
				t[P_AEL] = 0.25
				t[P_AER] = 0.25
				t[P_LLX] = 1.15
				t[P_LKL] = -1.5
				t[P_LRX] = -0.3
				t[P_LKR] = -1.1
			else:
				t[P_ALX] = 1.3
				t[P_ARX] = 1.3
				t[P_ALZ] = 1.0
				t[P_ARZ] = -1.0
				t[P_AEL] = 0.4
				t[P_AER] = 0.4
				t[P_LLX] = 0.55
				t[P_LKL] = -0.6
				t[P_LRX] = -0.15
				t[P_LKR] = -0.5
			t[P_TAIL] = 1.0 if rising else 0.2
		Anim.SLIDE:
			t[P_HIPY] = -0.40
			t[P_HRX] = 1.0
			t[P_HDX] = -0.75
			t[P_HRZ] = -lean * 0.12
			t[P_LLX] = 1.35
			t[P_LKL] = -0.1
			t[P_LRX] = 1.15
			t[P_LKR] = -0.2
			t[P_ALX] = -1.1
			t[P_ARX] = -1.3
			t[P_ALZ] = 0.5
			t[P_ARZ] = -0.5
			t[P_AEL] = 0.2
			t[P_AER] = 0.2
			t[P_TAIL] = 0.2
		Anim.STUMBLE:
			var w := sin(_time * 30.0)
			t[P_HIPY] = -0.12
			t[P_HRX] = -0.75
			t[P_HRZ] = w * 0.15
			t[P_HDX] = 0.45
			t[P_ALX] = 1.2 + w * 0.5
			t[P_ARX] = 1.2 - w * 0.5
			t[P_ALZ] = 0.6
			t[P_ARZ] = -0.6
			t[P_AEL] = 0.5
			t[P_AER] = 0.5
			t[P_LLX] = 0.5
			t[P_LKL] = -0.8
			t[P_LRX] = -0.2
			t[P_LKR] = -0.3
			t[P_TAIL] = 0.0
		Anim.FALL:
			var w2 := sin(_time * 22.0)
			t[P_HIPY] = 0.0
			t[P_HRX] = 0.3
			t[P_ALX] = 2.9 + w2 * 0.3
			t[P_ARX] = 2.9 - w2 * 0.3
			t[P_ALZ] = 0.5
			t[P_ARZ] = -0.5
			t[P_AEL] = 0.2
			t[P_AER] = 0.2
			t[P_LLX] = 0.7 + w2 * 0.5
			t[P_LKL] = -0.8
			t[P_LRX] = 0.7 - w2 * 0.5
			t[P_LKR] = -0.8
			t[P_TAIL] = 1.2
		Anim.CHEER:
			var bounce := absf(sin(_time * 7.0))
			t[P_HIPY] = bounce * 0.12
			t[P_HRX] = -0.05
			t[P_ALX] = 2.9
			t[P_ARX] = 2.9
			t[P_ALZ] = 0.45
			t[P_ARZ] = -0.45
			t[P_AEL] = 0.2
			t[P_AER] = 0.2
			t[P_LLX] = 0.1
			t[P_LRX] = 0.1
			t[P_LKL] = -0.2
			t[P_LKR] = -0.2
			t[P_HDX] = -0.1
			t[P_TAIL] = 0.8
		_:
			# IDLE: وقفة استعداد (قبضة قرب الصدر) مع تنفّس
			var br := sin(_time * 2.2)
			t[P_HIPY] = -0.03 + br * 0.012
			t[P_HRX] = -0.04
			t[P_HRY] = sin(_time * 0.8) * 0.05
			t[P_HDX] = 0.06 + br * 0.02
			t[P_HDZ] = sin(_time * 0.9) * 0.05
			t[P_ALX] = -0.1
			t[P_ALZ] = 0.22
			t[P_AEL] = 0.35
			t[P_ARX] = 0.55
			t[P_ARZ] = -0.2
			t[P_AER] = 2.0
			t[P_LLX] = -0.05
			t[P_LRX] = 0.12
			t[P_LKL] = -0.12
			t[P_LKR] = -0.22
			t[P_TAIL] = 0.3 + br * 0.1
	_target = t


func _apply_pose_instant() -> void:
	_compute_target(0.0)
	for i in range(P_COUNT):
		_pose[i] = _target[i]
	_apply_pose()


func _apply_pose() -> void:
	var p := _pose
	hips.position.y = 0.70 + p[P_HIPY]
	var hrx := p[P_HRX]
	var hry := p[P_HRY]
	var arx := p[P_ARX]
	var aer := p[P_AER]
	var arz := p[P_ARZ]
	var alx := p[P_ALX]
	# تراكب الضرب (يُطبَّق بعد التنعيم ليكون حادًّا)
	if punch_t >= 0.0:
		var w := _punch_curve(punch_t)   # x: وزن الذراع للأمام، y: التفاف الجذع
		arx = lerpf(arx, w.x, w.z)
		aer = lerpf(aer, w.y, w.z)
		arz = lerpf(arz, -0.05, w.z)
		hry = lerpf(hry, w.w, w.z * 0.8)
		alx = lerpf(alx, -0.9, w.z * 0.6)
	hips.rotation = Vector3(hrx, hry, p[P_HRZ])
	head.rotation = Vector3(p[P_HDX], 0.0, p[P_HDZ])
	arm_l.rotation = Vector3(alx, 0.0, p[P_ALZ])
	elbow_l.rotation = Vector3(p[P_AEL], 0.0, 0.0)
	arm_r.rotation = Vector3(arx, 0.0, arz)
	elbow_r.rotation = Vector3(aer, 0.0, 0.0)
	leg_l.rotation = Vector3(p[P_LLX], 0.0, 0.0)
	knee_l.rotation = Vector3(p[P_LKL], 0.0, 0.0)
	leg_r.rotation = Vector3(p[P_LRX], 0.0, 0.0)
	knee_r.rotation = Vector3(p[P_LKR], 0.0, 0.0)


## يعيد (زاوية الكتف، زاوية المرفق، وزن التراكب، التفاف الجذع)
func _punch_curve(t: float) -> Vector4:
	if t < 0.10:
		var u := t / 0.10
		return Vector4(lerpf(0.4, -1.3, u), lerpf(1.2, 1.7, u), smoothstep(0.0, 1.0, u), lerpf(0.0, -0.55, u))
	elif t < 0.22:
		var u2 := (t - 0.10) / 0.12
		return Vector4(lerpf(-1.3, 1.55, u2), lerpf(1.7, 0.05, u2), 1.0, lerpf(-0.55, 0.6, u2))
	elif t < 0.42:
		var u3 := (t - 0.22) / 0.20
		return Vector4(1.55, 0.05, 1.0 - smoothstep(0.0, 1.0, u3), lerpf(0.6, 0.0, u3))
	return Vector4(0, 0, 0, 0)


func _update_chains(delta: float) -> void:
	var curl := _pose[P_TAIL]
	for i in range(tail.size()):
		var n := tail[i]
		var ph := _time * (4.0 + run_speed * 0.15) - float(i) * 0.9
		n.rotation = Vector3(-0.28 - curl * 0.12 + sin(ph * 0.7) * 0.06, sin(ph) * (0.18 + 0.05 * float(i)) - lean * 0.15, 0.0)
	var flap := 0.12 + clampf(run_speed / 14.0, 0.0, 1.5) * 0.28
	for i in range(scarf.size()):
		var n2 := scarf[i]
		var ph2 := _time * 9.0 - float(i) * 1.1
		n2.rotation = Vector3(0.12 + sin(ph2) * flap * 0.4 + (0.35 if i == 0 else 0.0), sin(ph2 * 0.8 + 1.0) * flap, 0.0)
	if punch_t >= 0.0:
		punch_t += delta
		if punch_t > 0.45:
			punch_t = -1.0


func set_flash(on: bool) -> void:
	# وميض الحماية بعد التعثّر
	if invuln_flash == on:
		return
	invuln_flash = on


func _physics_process(_delta: float) -> void:
	if body and invuln_flash:
		body.visible = int(_time * 18.0) % 2 == 0
	elif body and not body.visible:
		body.visible = true


## يغيّر لون الفراء (دوران الصبغة) لتمييز المتسابقين؛ يبقى الأبيض والأسود كما هما.
func set_hue(radians: float) -> void:
	var cache := {}
	for mi in _meshes:
		var src: ShaderMaterial = mi.material_override as ShaderMaterial
		if src == null:
			continue
		if not cache.has(src):
			var m: ShaderMaterial = src.duplicate()
			m.set_shader_parameter("hue_shift", radians)
			cache[src] = m
		mi.material_override = cache[src]


## نسخة جامدة شفافة (للخدعة الوهمية): لقطة من أوضاع المفاصل الحالية تشارك نفس الشبكات.
func make_ghost(color := Color(0.45, 0.9, 1.0)) -> Node3D:
	var g := Node3D.new()
	var gm := Toon.ghost(color)
	for mi in _meshes:
		var c := MeshInstance3D.new()
		c.mesh = mi.mesh
		c.material_override = gm
		c.transform = mi.global_transform
		c.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		g.add_child(c)
	return g
