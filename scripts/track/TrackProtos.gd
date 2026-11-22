class_name TrackProtos
extends RefCounted
## مجسمات المسار والديكور (أصلية، تُبنى مرة واحدة وتُكرَّر بـ MultiMesh).

static var _cache: Dictionary = {}

const WOOD := Color("c98a4b")
const WOOD_D := Color("8a5428")
const WOOD_L := Color("e3a863")
const ROPE := Color("e8d3a0")
const LEAF_D := Color("1f8a3a")
const LEAF_L := Color("73d84a")
const STONE := Color("b99aa8")
const STONE_D := Color("8b6f93")
const GRASS := Color("5fd145")
const GRASS_D := Color("2f9d3a")
const PINK := Color("ff6fb5")
const PURPLE := Color("7a4fe0")
const GOLD := Color("ffc933")


static func get_mesh(key: String) -> ArrayMesh:
	if _cache.has(key):
		return _cache[key]
	var m: ArrayMesh = Callable(TrackProtos, "_make_" + key).call()
	_cache[key] = m
	return m


static func _xf(pos: Vector3, rot := Vector3.ZERO, scl := Vector3.ONE) -> Transform3D:
	return Transform3D(Basis.from_euler(rot) * Basis.from_scale(scl), pos)


# ------------------------------------------------------------------ الجسر
static func _make_board() -> ArrayMesh:
	var mb := MeshBuilder.new()
	mb.add_rbox(Vector3(3.94, 0.26, 0.90), 0.07, WOOD, _xf(Vector3(0, -0.13, 0)), 3, WOOD_L)
	# مسامير
	for sx in [-1.65, 1.65]:
		mb.add_ellipsoid(Vector3(0.07, 0.04, 0.07), WOOD_D, _xf(Vector3(sx, 0.005, 0.0)), 6, 4)
	return mb.build()


static func _make_stringer() -> ArrayMesh:
	var mb := MeshBuilder.new()
	mb.add_rbox(Vector3(0.45, 0.42, 6.2), 0.1, WOOD_D, _xf(Vector3(0, -0.48, 0)), 3)
	return mb.build()


static func _make_post() -> ArrayMesh:
	var mb := MeshBuilder.new()
	mb.add_cylinder(0.17, 0.13, 1.55, WOOD_D, _xf(Vector3(0, -0.2, 0)), 8, true, WOOD)
	mb.add_ellipsoid(Vector3(0.17, 0.15, 0.17), WOOD_L, _xf(Vector3(0, 1.38, 0)), 8, 6)
	# حلقة حبل
	mb.add_torus(0.15, 0.04, ROPE, _xf(Vector3(0, 1.1, 0)), 10, 5)
	return mb.build()


static func _make_pennant() -> ArrayMesh:
	var mb := MeshBuilder.new()
	mb.add_cylinder(0.04, 0.03, 2.1, WOOD_D, _xf(Vector3(0, 0, 0)), 6)
	var pts := [Vector3(0.0, 1.9, 0.0), Vector3(0.0, 1.9, 0.5), Vector3(0.0, 1.9, 1.0)]
	mb.add_triangle(Vector3(0, 2.05, 0), Vector3(0, 1.6, 0), Vector3(0, 1.82, 0.9), PINK)
	mb.add_triangle(Vector3(0, 2.05, 0), Vector3(0, 1.82, 0.9), Vector3(0, 1.6, 0), PINK.darkened(0.15))
	mb.add_ellipsoid(Vector3(0.07, 0.07, 0.07), GOLD, _xf(Vector3(0, 2.12, 0)), 6, 5)
	return mb.build()


# ------------------------------------------------------------------ نباتات وصخور
static func _palm(variant: int) -> ArrayMesh:
	var mb := MeshBuilder.new()
	var h := 5.2 + float(variant) * 1.6
	var bend := 0.9 + float(variant) * 0.5
	var pts: Array = []
	var rad: Array = []
	for k in range(9):
		var t := float(k) / 8.0
		pts.append(Vector3(bend * t * t, t * h, 0.0))
		rad.append(lerpf(0.3, 0.17, t))
	mb.add_tube(pts, rad, Color("a8744a"), 7, Transform3D.IDENTITY, true, false, Color("c9965f"))
	# حلقات الجذع
	for k in range(1, 8):
		var t := float(k) / 8.0
		mb.add_torus(lerpf(0.31, 0.18, t), 0.035, WOOD_D, _xf(Vector3(bend * t * t, t * h, 0.0), Vector3(0, 0, -atan(2.0 * bend * t / h))), 9, 4)
	var top := Vector3(bend, h, 0.0)
	var fronds := 8
	for f in range(fronds):
		var a := TAU * float(f) / float(fronds) + float(variant) * 0.4
		var dir := Vector3(cos(a), 0.0, sin(a))
		var fpts: Array = []
		var wid: Array = []
		var length := 2.9 + 0.3 * float(f % 2)
		for u in range(7):
			var t := float(u) / 6.0
			var p := top + dir * (t * length) + Vector3(0.0, sin(t * PI * 0.55) * 0.95 - t * t * 1.5, 0.0)
			fpts.append(p)
			wid.append(sin(clampf(t * 1.05, 0.0, 1.0) * PI) * 1.05 + 0.08)
		mb.add_strip(fpts, wid, LEAF_D, Vector3.UP.cross(dir), Transform3D.IDENTITY, LEAF_L)
	# جوز الهند
	for c in range(3):
		var a2 := TAU * float(c) / 3.0
		mb.add_ellipsoid(Vector3(0.2, 0.2, 0.2), Color("7b4a24"), _xf(top + Vector3(cos(a2) * 0.22, -0.28, sin(a2) * 0.22)), 8, 6)
	return mb.build()


static func _make_palm_a() -> ArrayMesh:
	return _palm(0)


static func _make_palm_b() -> ArrayMesh:
	return _palm(1)


static func _make_bush() -> ArrayMesh:
	var mb := MeshBuilder.new()
	var cols := [GRASS_D, Color("3fb347"), Color("2a8f3c")]
	var spots := [Vector3(0, 0.55, 0), Vector3(0.65, 0.4, 0.2), Vector3(-0.6, 0.42, -0.1), Vector3(0.15, 0.4, -0.6), Vector3(-0.1, 0.38, 0.6)]
	var rs := [0.8, 0.6, 0.62, 0.55, 0.52]
	for k in range(spots.size()):
		var r: float = rs[k]
		mb.add_ellipsoid(Vector3(r, r * 0.85, r), cols[k % 3], _xf(spots[k]), 10, 7, GRASS)
	for k in range(4):
		var a := TAU * float(k) / 4.0 + 0.5
		mb.add_ellipsoid(Vector3(0.1, 0.1, 0.1), PINK if k % 2 == 0 else GOLD, _xf(Vector3(cos(a) * 0.55, 0.95 - float(k % 2) * 0.1, sin(a) * 0.55)), 6, 5)
	return mb.build()


static func _make_mushroom() -> ArrayMesh:
	var mb := MeshBuilder.new()
	mb.add_cylinder(0.2, 0.16, 0.7, Color("fff0d8"), Transform3D.IDENTITY, 8)
	var prof: Array = []
	for k in range(9):
		var a := (PI * 0.5) * float(k) / 8.0
		prof.append(Vector2(sin(a) * 0.62, 0.65 + cos(a) * 0.5))
	prof.append(Vector2(0.62, 0.63))
	prof.append(Vector2(0.0, 0.6))
	mb.add_lathe(prof, Color("e8353f"), Transform3D.IDENTITY, 12, Color("ff5a4a"))
	for k in range(6):
		var a2 := TAU * float(k) / 6.0
		var rr := 0.38 if k < 5 else 0.0
		var y := 0.65 + sqrt(maxf(0.25 - rr * rr * 0.65, 0.0)) * 0.9
		mb.add_ellipsoid(Vector3(0.1, 0.05, 0.1), Color.WHITE, _xf(Vector3(cos(a2) * rr, y if k < 5 else 1.15, sin(a2) * rr)), 6, 4)
	return mb.build()


static func _rock(variant: int) -> ArrayMesh:
	var mb := MeshBuilder.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 100 + variant
	for k in range(4):
		var r := rng.randf_range(0.5, 1.0) * (1.0 if k == 0 else 0.62)
		var off := Vector3(rng.randf_range(-0.6, 0.6), r * 0.45, rng.randf_range(-0.6, 0.6)) if k > 0 else Vector3(0, r * 0.5, 0)
		mb.add_ellipsoid(Vector3(r * rng.randf_range(0.9, 1.3), r * rng.randf_range(0.7, 1.0), r * rng.randf_range(0.9, 1.3)), STONE_D, _xf(off, Vector3(0, rng.randf() * TAU, 0)), 8, 6, STONE)
	return mb.build()


static func _make_rock_a() -> ArrayMesh:
	return _rock(0)


static func _make_rock_b() -> ArrayMesh:
	return _rock(1)


## كتلة أرض جانبية (عشب فوق وصخر تحت).
static func _make_hill() -> ArrayMesh:
	var mb := MeshBuilder.new()
	mb.add_ellipsoid(Vector3(11.0, 5.0, 11.0), Color("a9809a"), _xf(Vector3(0, -2.2, 0)), 14, 9, Color("62d447"))
	mb.add_ellipsoid(Vector3(6.0, 3.0, 6.0), Color("b58fa5"), _xf(Vector3(5.0, -1.6, 4.0)), 10, 7, Color("5acb42"))
	return mb.build()


static func _make_pillar() -> ArrayMesh:
	var mb := MeshBuilder.new()
	var h := 0.0
	var r := 5.0
	for k in range(5):
		mb.add_ellipsoid(Vector3(r, 3.2, r), STONE_D, _xf(Vector3(0, -16.0 + h, 0), Vector3(0, float(k) * 0.9, 0)), 10, 6, STONE)
		h += 4.6
		r *= 0.9
	mb.add_ellipsoid(Vector3(r * 1.1, 1.8, r * 1.1), GRASS_D, _xf(Vector3(0, -16.0 + h - 0.8, 0)), 10, 6, GRASS)
	return mb.build()


static func _make_flower() -> ArrayMesh:
	var mb := MeshBuilder.new()
	mb.add_cylinder(0.025, 0.02, 0.45, GRASS_D, Transform3D.IDENTITY, 5)
	for k in range(5):
		var a := TAU * float(k) / 5.0
		mb.add_ellipsoid(Vector3(0.09, 0.03, 0.09), PINK, _xf(Vector3(cos(a) * 0.1, 0.46, sin(a) * 0.1)), 6, 4)
	mb.add_ellipsoid(Vector3(0.06, 0.04, 0.06), GOLD, _xf(Vector3(0, 0.48, 0)), 6, 4)
	return mb.build()


# ------------------------------------------------------------------ عقبات
static func _make_log() -> ArrayMesh:
	var mb := MeshBuilder.new()
	var rot := Vector3(0, 0, PI * 0.5)
	mb.add_cylinder(0.5, 0.5, 1.0, Color("9a6232"), _xf(Vector3(1.0, 0.52, 0), rot), 14, true, Color("b87a42"))
	return mb.build()   # يُمدَّد بالتحجيم على X


static func _make_log_end() -> ArrayMesh:
	var mb := MeshBuilder.new()
	mb.add_cylinder(0.52, 0.52, 0.08, Color("e8c48a"), _xf(Vector3(0, 0.52, 0), Vector3(0, 0, PI * 0.5)), 14)
	mb.add_torus(0.3, 0.025, Color("b88a52"), _xf(Vector3(0.045, 0.52, 0), Vector3(0, 0, PI * 0.5)), 14, 4)
	mb.add_torus(0.15, 0.022, Color("b88a52"), _xf(Vector3(0.045, 0.52, 0), Vector3(0, 0, PI * 0.5)), 12, 4)
	return mb.build()


static func _make_crate() -> ArrayMesh:
	var mb := MeshBuilder.new()
	var w := 1.22
	mb.add_rbox(Vector3(w, w, w), 0.08, Color("d49a5a"), _xf(Vector3(0, w * 0.5, 0)), 3, Color("e8b878"))
	var bar := Color("8a5428")
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			mb.add_rbox(Vector3(0.14, w + 0.04, 0.14), 0.05, bar, _xf(Vector3(sx * w * 0.5, w * 0.5, sz * w * 0.5)), 2)
	for sy in [0.04, w - 0.04]:
		for sx in [-1.0, 1.0]:
			mb.add_rbox(Vector3(0.14, 0.14, w + 0.04), 0.05, bar, _xf(Vector3(sx * w * 0.5, sy, 0)), 2)
		for sz in [-1.0, 1.0]:
			mb.add_rbox(Vector3(w + 0.04, 0.14, 0.14), 0.05, bar, _xf(Vector3(0, sy, sz * w * 0.5)), 2)
	# علامة نجمة على الجهة الأمامية والخلفية
	mb.add_star(0.28, 0.13, 0.04, GOLD, _xf(Vector3(0, w * 0.5, -w * 0.5 - 0.02)))
	mb.add_star(0.28, 0.13, 0.04, GOLD, _xf(Vector3(0, w * 0.5, w * 0.5 + 0.02), Vector3(0, PI, 0)))
	return mb.build()


static func _make_vine_gate() -> ArrayMesh:
	var mb := MeshBuilder.new()
	# عارضة خشبية أفقية (تُمدَّد على X بالتحجيم) — الأعمدة تُضاف منفصلة
	mb.add_cylinder(0.36, 0.36, 1.0, Color("7a4a2a"), _xf(Vector3(1.0, 1.62, 0), Vector3(0, 0, PI * 0.5)), 10, true, Color("a06a3a"))
	return mb.build()


static func _make_vine_hang() -> ArrayMesh:
	var mb := MeshBuilder.new()
	for k in range(5):
		var x := -0.8 + float(k) * 0.4
		var len := 0.75 + float(k % 3) * 0.12
		var pts: Array = []
		for j in range(5):
			var t := float(j) / 4.0
			pts.append(Vector3(x + sin(t * 3.0 + float(k)) * 0.05, 1.5 - t * len, 0.0))
		mb.add_tube(pts, 0.035, LEAF_D, 5, Transform3D.IDENTITY, false, false)
		for j in range(3):
			var ly := 1.45 - float(j) * len * 0.3
			mb.add_ellipsoid(Vector3(0.14, 0.05, 0.1), LEAF_L if j % 2 == 0 else LEAF_D, _xf(Vector3(x + (0.1 if j % 2 == 0 else -0.1), ly, 0.0), Vector3(0, 0, 0.6 if j % 2 == 0 else -0.6)), 6, 4)
	return mb.build()


static func _make_gate_post() -> ArrayMesh:
	var mb := MeshBuilder.new()
	mb.add_cylinder(0.42, 0.34, 2.4, Color("7a4a2a"), Transform3D.IDENTITY, 10, true, Color("a06a3a"))
	mb.add_ellipsoid(Vector3(0.42, 0.28, 0.42), Color("b57a44"), _xf(Vector3(0, 2.4, 0)), 10, 6)
	return mb.build()


static func _make_hammer_head() -> ArrayMesh:
	var mb := MeshBuilder.new()
	# رأس المطرقة: أسطوانة أفقية بنفسجية بنجمة وردية على الوجهين
	var rot := Vector3(0, 0, PI * 0.5)
	mb.add_cylinder(0.78, 0.78, 1.7, PURPLE, _xf(Vector3(0.85, 0, 0), rot), 16, true, PURPLE.lightened(0.15))
	for sx in [-0.85, 0.85]:
		mb.add_torus(0.78, 0.13, GOLD, _xf(Vector3(sx, 0, 0), rot), 16, 6)
	mb.add_star(0.5, 0.22, 0.06, PINK, _xf(Vector3(0.93, 0, 0), Vector3(0, PI * 0.5, 0)))
	mb.add_star(0.5, 0.22, 0.06, PINK, _xf(Vector3(-0.93, 0, 0), Vector3(0, -PI * 0.5, 0)))
	return mb.build()


static func _make_hammer_arm() -> ArrayMesh:
	var mb := MeshBuilder.new()
	mb.add_cylinder(0.1, 0.1, 5.45, Color("5b5368"), _xf(Vector3(0, -5.45, 0)), 8, true, Color("8a809c"))
	mb.add_ellipsoid(Vector3(0.28, 0.28, 0.28), GOLD, _xf(Vector3.ZERO), 8, 6)
	return mb.build()


static func _make_pad() -> ArrayMesh:
	var mb := MeshBuilder.new()
	mb.add_rbox(Vector3(3.4, 0.14, 3.0), 0.05, Color("3e6fe0"), _xf(Vector3(0, 0.07, 0)), 3)
	for k in range(2):
		var z := 0.5 - float(k) * 0.95
		var c := Color("ffd23a")
		# شيفرون مبني من أربعة مثلثات سميكة قليلًا
		var y := 0.17
		mb.add_triangle(Vector3(0, y, z - 0.55), Vector3(-0.95, y, z + 0.1), Vector3(-0.95, y, z + 0.45), c)
		mb.add_triangle(Vector3(0, y, z - 0.55), Vector3(-0.95, y, z + 0.45), Vector3(0, y, z - 0.15), c)
		mb.add_triangle(Vector3(0, y, z - 0.55), Vector3(0.95, y, z + 0.45), Vector3(0.95, y, z + 0.1), c)
		mb.add_triangle(Vector3(0, y, z - 0.55), Vector3(0, y, z - 0.15), Vector3(0.95, y, z + 0.45), c)
	return mb.build()


static func _make_coin() -> ArrayMesh:
	var mb := MeshBuilder.new()
	var rot := Vector3(PI * 0.5, 0, 0)
	mb.add_cylinder(0.34, 0.34, 0.10, Color("e8a010"), _xf(Vector3(0, 0, -0.05), rot), 14)
	mb.add_torus(0.31, 0.045, Color("ffd84a"), _xf(Vector3(0, 0, 0.05), rot), 14, 5)
	mb.add_torus(0.31, 0.045, Color("ffd84a"), _xf(Vector3(0, 0, -0.05), rot), 14, 5)
	mb.add_cylinder(0.25, 0.25, 0.02, Color("ffc21c"), _xf(Vector3(0, 0, 0.05), rot), 12)
	mb.add_star(0.16, 0.07, 0.03, Color("fff3a0"), _xf(Vector3(0, 0, 0.075)))
	mb.add_star(0.16, 0.07, 0.03, Color("fff3a0"), _xf(Vector3(0, 0, -0.075), Vector3(0, PI, 0)))
	return mb.build()


static func _make_sign() -> ArrayMesh:
	var mb := MeshBuilder.new()
	mb.add_cylinder(0.07, 0.06, 2.0, WOOD_D, Transform3D.IDENTITY, 6)
	mb.add_triangle(Vector3(0, 2.75, 0), Vector3(-0.6, 1.85, 0), Vector3(0.6, 1.85, 0), Color("ffcf2e"))
	mb.add_triangle(Vector3(0, 2.75, 0), Vector3(0.6, 1.85, 0), Vector3(-0.6, 1.85, 0), Color("ffcf2e"))
	mb.add_triangle(Vector3(0, 2.5, 0.01), Vector3(-0.38, 1.97, 0.01), Vector3(0.38, 1.97, 0.01), Color("2a1f3a"))
	mb.add_ellipsoid(Vector3(0.05, 0.05, 0.02), Color("ffcf2e"), _xf(Vector3(0, 2.05, 0.02)), 6, 4)
	return mb.build()


# ------------------------------------------------------------------ بوابات (بداية/نهاية)
static func _make_arch() -> ArrayMesh:
	var mb := MeshBuilder.new()
	var span := TrackData.HALF_W + 1.2
	for sgn in [-1.0, 1.0]:
		for k in range(8):
			var c := PURPLE if k % 2 == 0 else Color("ff8fd0")
			mb.add_cylinder(0.62, 0.62, 0.9, c, _xf(Vector3(span * sgn, float(k) * 0.9, 0)), 12, k == 0 or k == 7)
		mb.add_ellipsoid(Vector3(0.78, 0.5, 0.78), GOLD, _xf(Vector3(span * sgn, 7.4, 0)), 12, 7)
	# لافتة مربعات شطرنجية
	var cols := 14
	var rows := 3
	var cw := (span * 2.0) / float(cols)
	for i in range(cols):
		for j in range(rows):
			var c2 := Color("fafafa") if (i + j) % 2 == 0 else Color("1a1a2a")
			mb.add_rbox(Vector3(cw, 0.55, 0.3), 0.05, c2, _xf(Vector3(-span + cw * (float(i) + 0.5), 6.3 + float(j) * 0.55, 0)), 2)
	mb.add_rbox(Vector3(span * 2.0 + 1.0, 0.35, 0.5), 0.12, GOLD, _xf(Vector3(0, 8.0, 0)), 3)
	return mb.build()


# ------------------------------------------------------------------ ديكور بعيد
static func _make_castle() -> ArrayMesh:
	var mb := MeshBuilder.new()
	# جزيرة عائمة
	mb.add_ellipsoid(Vector3(24.0, 9.0, 24.0), Color("9b7aa0"), _xf(Vector3(0, -6.0, 0)), 14, 8, Color("6bd44c"))
	mb.add_cylinder(0.0, 12.0, 10.0, Color("8e6a98"), _xf(Vector3(0, -20.0, 0), Vector3(PI, 0, 0)), 12, false)
	var wall := Color("ffd9e8")
	var roof := Color("c45cff")
	var towers := [Vector3(0, 0, 0), Vector3(-9, 0, 3), Vector3(9, 0, 3), Vector3(-5, 0, -6), Vector3(5, 0, -6), Vector3(0, 0, 8)]
	var heights := [24.0, 15.0, 15.0, 17.0, 17.0, 12.0]
	for k in range(towers.size()):
		var p: Vector3 = towers[k]
		var h: float = heights[k]
		var r := 3.2 if k == 0 else 2.2
		mb.add_cylinder(r, r, h, wall, _xf(p + Vector3(0, 0.5, 0)), 12, true, Color("fff2f7"))
		mb.add_cylinder(r * 1.45, 0.0, r * 2.4, roof, _xf(p + Vector3(0, h + 0.4, 0)), 12, true, Color("e08cff"))
		mb.add_ellipsoid(Vector3(0.6, 0.6, 0.6), GOLD, _xf(p + Vector3(0, h + r * 2.4 + 0.5, 0)), 6, 5)
	mb.add_rbox(Vector3(20.0, 8.0, 8.0), 0.8, wall, _xf(Vector3(0, 4.5, 1.0)), 3)
	return mb.build()


static func _make_cloud() -> ArrayMesh:
	var mb := MeshBuilder.new()
	var spots := [Vector3(0, 0, 0), Vector3(6, -0.6, 1), Vector3(-6, -0.7, -1), Vector3(11, -1.2, 0), Vector3(-11, -1.3, 1), Vector3(3, 1.5, 0), Vector3(-3, 1.2, 0.5)]
	var rs := [5.0, 4.2, 4.2, 3.2, 3.2, 3.6, 3.4]
	for k in range(spots.size()):
		var r: float = rs[k]
		mb.add_ellipsoid(Vector3(r, r * 0.62, r * 0.9), Color("e2e8ff"), _xf(spots[k]), 10, 7, Color("ffffff"))
	return mb.build()


static func _make_mountain() -> ArrayMesh:
	var mb := MeshBuilder.new()
	mb.add_ellipsoid(Vector3(60.0, 70.0, 60.0), Color("8a8fd4"), _xf(Vector3(0, -10.0, 0)), 12, 8, Color("b8c8f0"))
	mb.add_ellipsoid(Vector3(40.0, 50.0, 40.0), Color("7a82cc"), _xf(Vector3(50.0, -20.0, 20.0)), 10, 7, Color("a8b8e8"))
	return mb.build()


static func _make_waterfall() -> ArrayMesh:
	var mb := MeshBuilder.new()
	var pts: Array = []
	var wid: Array = []
	for k in range(7):
		var t := float(k) / 6.0
		pts.append(Vector3(0, -t * 34.0, sin(t * PI) * 2.0))
		wid.append(lerpf(7.0, 9.0, t))
	mb.add_strip(pts, wid, Color.WHITE, Vector3.RIGHT)
	return mb.build()


static func _make_cliff() -> ArrayMesh:
	var mb := MeshBuilder.new()
	mb.add_ellipsoid(Vector3(18.0, 24.0, 12.0), Color("a98aa0"), _xf(Vector3(0, -10.0, 0)), 12, 8, Color("7ad95a"))
	mb.add_ellipsoid(Vector3(11.0, 16.0, 9.0), Color("b494aa"), _xf(Vector3(10.0, -16.0, 4.0)), 10, 7, Color("6fd052"))
	return mb.build()
