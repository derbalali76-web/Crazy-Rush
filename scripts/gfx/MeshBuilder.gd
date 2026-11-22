class_name MeshBuilder
extends RefCounted
## يبني مجسمات ثلاثية الأبعاد أصلية (إهليلجات، مخروطات، أنابيب، صناديق مدورة...)
## كل رأس يحمل لونه الخاص (Vertex Color) فيكفي خامة واحدة لكل مجسم.
## الألوان تُستخدم كما هي (المُصيِّر Compatibility لا يحوّل الفضاء اللوني).
## COLOR.a = 1 عادي؛ أقل من 1 يعني إضاءة ذاتية بمقدار (1 - a).

var _v := PackedVector3Array()
var _n := PackedVector3Array()
var _c := PackedColorArray()
var _i := PackedInt32Array()


func vertex_count() -> int:
	return _v.size()


func clear() -> void:
	_v.clear(); _n.clear(); _c.clear(); _i.clear()


func _push(p: Vector3, n: Vector3, c: Color, xf: Transform3D, nb: Basis) -> int:
	_v.append(xf * p)
	_n.append((nb * n).normalized())
	_c.append(c)
	return _v.size() - 1


## ربع (a,b,c,d) مرتب عكس عقارب الساعة عند النظر من الخارج.
func _quad(a: int, b: int, c: int, d: int) -> void:
	_i.append_array([a, c, b, a, d, c])


func _tri(a: int, b: int, c: int) -> void:
	_i.append_array([a, c, b])


static func _nbasis(xf: Transform3D) -> Basis:
	return xf.basis.inverse().transposed()


# ---------------------------------------------------------------- إهليلج
func add_ellipsoid(radii: Vector3, color: Color, xf := Transform3D.IDENTITY, seg := 14, rings := 9, color_top := Color(-1, 0, 0, 0)) -> void:
	var nb := _nbasis(xf)
	var base := _v.size()
	var grad := color_top.r >= 0.0
	for i in range(rings + 1):
		var th := PI * float(i) / float(rings)
		var y := cos(th)
		var rr := sin(th)
		for j in range(seg + 1):
			var ph := TAU * float(j) / float(seg)
			var dir := Vector3(rr * cos(ph), y, rr * sin(ph))
			var col := color
			if grad:
				col = color.lerp(color_top, clampf(dir.y * 0.5 + 0.5, 0.0, 1.0))
			_push(dir * radii, Vector3(dir.x / radii.x, dir.y / radii.y, dir.z / radii.z), col, xf, nb)
	for i in range(rings):
		for j in range(seg):
			var tl := base + i * (seg + 1) + (j + 1)
			var bl := base + (i + 1) * (seg + 1) + (j + 1)
			var br := base + (i + 1) * (seg + 1) + j
			var tr := base + i * (seg + 1) + j
			_quad(tl, bl, br, tr)  # المثلثات المنحلة عند القطبين غير ضارة


# ---------------------------------------------------------------- مخرطة (Lathe)
## profile: نقاط (نصف القطر، الارتفاع) مرتبة من الأعلى إلى الأسفل.
## تدعم تدرج لون بين color (أسفل) و color_top (أعلى).
func add_lathe(profile: Array, color: Color, xf := Transform3D.IDENTITY, seg := 12, color_top := Color(-1, 0, 0, 0), smooth := true) -> void:
	var nb := _nbasis(xf)
	var base := _v.size()
	var k := profile.size()
	var ymin := 1e9
	var ymax := -1e9
	for p in profile:
		ymin = minf(ymin, p.y)
		ymax = maxf(ymax, p.y)
	var grad := color_top.r >= 0.0
	for a in range(k):
		var p: Vector2 = profile[a]
		var pa: Vector2 = profile[maxi(a - 1, 0)]
		var pb: Vector2 = profile[mini(a + 1, k - 1)]
		var t := pb - pa
		var n2 := Vector2(-t.y, t.x).normalized()
		var col := color
		if grad:
			col = color.lerp(color_top, (p.y - ymin) / maxf(ymax - ymin, 0.0001))
		for j in range(seg + 1):
			var ph := TAU * float(j) / float(seg)
			var cx := cos(ph)
			var sz := sin(ph)
			_push(Vector3(p.x * cx, p.y, p.x * sz), Vector3(n2.x * cx, n2.y, n2.x * sz), col, xf, nb)
	for a in range(k - 1):
		for j in range(seg):
			var tl := base + a * (seg + 1) + (j + 1)
			var bl := base + (a + 1) * (seg + 1) + (j + 1)
			var br := base + (a + 1) * (seg + 1) + j
			var tr := base + a * (seg + 1) + j
			var r0: float = (profile[a] as Vector2).x
			var r1: float = (profile[a + 1] as Vector2).x
			if r0 < 0.00001:
				_tri(tl, bl, br)
			elif r1 < 0.00001:
				_tri(tl, br, tr)
			else:
				_quad(tl, bl, br, tr)


## أسطوانة/مخروط مقطوع على المحور Y (القاعدة عند y=0 والقمة عند y=h).
func add_cylinder(r_bottom: float, r_top: float, h: float, color: Color, xf := Transform3D.IDENTITY, seg := 10, caps := true, color_top := Color(-1, 0, 0, 0)) -> void:
	var prof: Array = []
	if caps and r_top > 0.0001:
		prof.append(Vector2(0.0, h))
	prof.append(Vector2(r_top, h))
	prof.append(Vector2(r_bottom, 0.0))
	if caps and r_bottom > 0.0001:
		prof.append(Vector2(0.0, 0.0))
	# حواف الأغطية تحتاج رؤوسًا مستقلة كي لا تتداخل الأنصال
	add_lathe(prof, color, xf, seg, color_top)


## كبسولة رأسية مركزها الأصل (طولها الكلي = length).
func add_capsule(radius: float, length: float, color: Color, xf := Transform3D.IDENTITY, seg := 10, rings := 4, color_top := Color(-1, 0, 0, 0)) -> void:
	var half := maxf(length * 0.5 - radius, 0.0)
	var prof: Array = []
	for i in range(rings + 1):
		var a := (PI * 0.5) * float(i) / float(rings)
		prof.append(Vector2(sin(a) * radius, half + cos(a) * radius))
	for i in range(rings + 1):
		var a := (PI * 0.5) * float(i) / float(rings)
		prof.append(Vector2(cos(a) * radius, -half - sin(a) * radius))
	add_lathe(prof, color, xf, seg, color_top)


## حلقة (Torus) في المستوى XZ.
func add_torus(major: float, minor: float, color: Color, xf := Transform3D.IDENTITY, seg := 16, tube_seg := 8) -> void:
	var nb := _nbasis(xf)
	var base := _v.size()
	for i in range(seg + 1):
		var ph := TAU * float(i) / float(seg)
		var cx := cos(ph)
		var sz := sin(ph)
		for j in range(tube_seg + 1):
			var th := TAU * float(j) / float(tube_seg)
			var rr := major + cos(th) * minor
			var p := Vector3(rr * cx, sin(th) * minor, rr * sz)
			var n := Vector3(cos(th) * cx, sin(th), cos(th) * sz)
			_push(p, n, color, xf, nb)
	for i in range(seg):
		for j in range(tube_seg):
			var a := base + i * (tube_seg + 1) + j
			var b := base + (i + 1) * (tube_seg + 1) + j
			var c := base + (i + 1) * (tube_seg + 1) + j + 1
			var d := base + i * (tube_seg + 1) + j + 1
			_quad(a, d, c, b)


# ---------------------------------------------------------------- صندوق مدور الحواف
const _FACES := [
	[Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1)],
	[Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, -1)],
	[Vector3(0, 0, -1), Vector3(0, 1, 0), Vector3(1, 0, 0)],
	[Vector3(0, 0, 1), Vector3(0, 1, 0), Vector3(-1, 0, 0)],
	[Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(0, 1, 0)],
	[Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(0, -1, 0)],
]


func add_rbox(size: Vector3, radius: float, color: Color, xf := Transform3D.IDENTITY, n := 4, color_top := Color(-1, 0, 0, 0)) -> void:
	var nb := _nbasis(xf)
	var half := size * 0.5
	var r := minf(radius, minf(half.x, minf(half.y, half.z)) - 0.0001)
	var inner := half - Vector3(r, r, r)
	var grad := color_top.r >= 0.0
	for f in _FACES:
		var u: Vector3 = f[0]
		var v: Vector3 = f[1]
		var nrm: Vector3 = f[2]
		var base := _v.size()
		for jy in range(n + 1):
			var b := -1.0 + 2.0 * float(jy) / float(n)
			for ix in range(n + 1):
				var a := -1.0 + 2.0 * float(ix) / float(n)
				var cube := (nrm + u * a + v * b) * half
				var clamped := cube.clamp(-inner, inner)
				var dir := cube - clamped
				var nn := nrm
				if dir.length() > 0.0001:
					nn = dir.normalized()
				var p := clamped + nn * r
				var col := color
				if grad:
					col = color.lerp(color_top, clampf(p.y / maxf(half.y, 0.0001) * 0.5 + 0.5, 0.0, 1.0))
				_push(p, nn, col, xf, nb)
		for jy in range(n):
			for ix in range(n):
				var bl := base + jy * (n + 1) + ix
				var br := bl + 1
				var tl := bl + (n + 1)
				var tr := tl + 1
				_quad(bl, br, tr, tl)


# ---------------------------------------------------------------- أنبوب على مسار
## points: مسار؛ radii: نصف قطر لكل نقطة (أو مفرد).
func add_tube(points: Array, radii: Variant, color: Color, seg := 6, xf := Transform3D.IDENTITY, cap_start := true, cap_end := true, color_end := Color(-1, 0, 0, 0)) -> void:
	var nb := _nbasis(xf)
	var cnt := points.size()
	if cnt < 2:
		return
	var base := _v.size()
	var grad := color_end.r >= 0.0
	var up_ref := Vector3.UP
	for a in range(cnt):
		var p: Vector3 = points[a]
		var t: Vector3 = (points[mini(a + 1, cnt - 1)] as Vector3) - (points[maxi(a - 1, 0)] as Vector3)
		t = t.normalized()
		var ref := up_ref
		if absf(t.dot(ref)) > 0.95:
			ref = Vector3.RIGHT
		var side := t.cross(ref).normalized()
		var upv := side.cross(t).normalized()
		var rad: float = radii if (radii is float or radii is int) else float(radii[a])
		var col := color
		if grad:
			col = color.lerp(color_end, float(a) / float(cnt - 1))
		for j in range(seg + 1):
			var ph := TAU * float(j) / float(seg)
			var dir := side * cos(ph) + upv * sin(ph)
			_push(p + dir * rad, dir, col, xf, nb)
	for a in range(cnt - 1):
		for j in range(seg):
			var a0 := base + a * (seg + 1) + j
			var a1 := base + a * (seg + 1) + j + 1
			var b0 := base + (a + 1) * (seg + 1) + j
			var b1 := base + (a + 1) * (seg + 1) + j + 1
			# اتجاه اللف يعتمد على الإطار (side, up, t) وهو يمين اليد
			_quad(a0, b0, b1, a1)
	if cap_start:
		_cap(points, radii, color, seg, xf, nb, true)
	if cap_end:
		_cap(points, radii, color_end if grad else color, seg, xf, nb, false)


func _cap(points: Array, radii: Variant, color: Color, seg: int, xf: Transform3D, nb: Basis, start: bool) -> void:
	var cnt := points.size()
	var idx := 0 if start else cnt - 1
	var p: Vector3 = points[idx]
	var t: Vector3 = (points[mini(idx + 1, cnt - 1)] as Vector3) - (points[maxi(idx - 1, 0)] as Vector3)
	t = t.normalized()
	var ref := Vector3.UP
	if absf(t.dot(ref)) > 0.95:
		ref = Vector3.RIGHT
	var side := t.cross(ref).normalized()
	var upv := side.cross(t).normalized()
	var rad: float = radii if (radii is float or radii is int) else float(radii[idx])
	var n := -t if start else t
	var center := _push(p, n, color, xf, nb)
	var first := _v.size()
	for j in range(seg + 1):
		var ph := TAU * float(j) / float(seg)
		_push(p + (side * cos(ph) + upv * sin(ph)) * rad, n, color, xf, nb)
	for j in range(seg):
		if start:
			_tri(center, first + j + 1, first + j)
		else:
			_tri(center, first + j, first + j + 1)


# ---------------------------------------------------------------- شريط مزدوج الوجه (أوراق، رايات، وشاح)
## points: مسار الشريط؛ widths: العرض عند كل نقطة؛ side_ref: اتجاه مرجعي للعرض.
func add_strip(points: Array, widths: Array, color: Color, side_ref := Vector3.RIGHT, xf := Transform3D.IDENTITY, color_end := Color(-1, 0, 0, 0)) -> void:
	var nb := _nbasis(xf)
	var cnt := points.size()
	if cnt < 2:
		return
	var base := _v.size()
	var grad := color_end.r >= 0.0
	for a in range(cnt):
		var p: Vector3 = points[a]
		var t: Vector3 = ((points[mini(a + 1, cnt - 1)] as Vector3) - (points[maxi(a - 1, 0)] as Vector3)).normalized()
		var side := side_ref - t * side_ref.dot(t)
		if side.length() < 0.001:
			side = Vector3.UP.cross(t)
		side = side.normalized()
		var nrm := side.cross(t).normalized()
		var w: float = float(widths[a]) * 0.5
		var col := color
		if grad:
			col = color.lerp(color_end, float(a) / float(cnt - 1))
		_push(p - side * w, nrm, col, xf, nb)
		_push(p + side * w, nrm, col, xf, nb)
	for a in range(cnt - 1):
		var l0 := base + a * 2
		var r0 := l0 + 1
		var l1 := l0 + 2
		var r1 := l0 + 3
		_quad(l0, r0, r1, l1)


## مثلث مفرد بإحداثيات عالمية (مع ألوان) — للنجوم والرايات.
func add_triangle(a: Vector3, b: Vector3, c: Vector3, color: Color, xf := Transform3D.IDENTITY) -> void:
	# المثلث يُعطى عكس عقارب الساعة عند النظر من الجهة الأمامية (الخارجية)
	var nb := _nbasis(xf)
	var n := (b - a).cross(c - a).normalized()
	var ia := _push(a, n, color, xf, nb)
	var ib := _push(b, n, color, xf, nb)
	var ic := _push(c, n, color, xf, nb)
	_i.append_array([ia, ic, ib])


## نجمة مسطحة خماسية في المستوى XY تواجه +Z.
func add_star(outer: float, inner: float, thickness: float, color: Color, xf := Transform3D.IDENTITY) -> void:
	var pts: Array = []
	for k in range(10):
		var r := outer if k % 2 == 0 else inner
		var a := PI * 0.5 + TAU * float(k) / 10.0
		pts.append(Vector2(cos(a) * r, sin(a) * r))
	var front: Array = []
	var back: Array = []
	for p in pts:
		front.append(Vector3(p.x, p.y, thickness * 0.5))
		back.append(Vector3(p.x, p.y, -thickness * 0.5))
	for k in range(10):
		var k2 := (k + 1) % 10
		add_triangle(Vector3(0, 0, thickness * 0.5), front[k], front[k2], color, xf)
		add_triangle(Vector3(0, 0, -thickness * 0.5), back[k2], back[k], color, xf)
		add_triangle(front[k], back[k], back[k2], color, xf)
		add_triangle(front[k], back[k2], front[k2], color, xf)


# ---------------------------------------------------------------- إخراج
func append_builder(other: MeshBuilder, xf := Transform3D.IDENTITY) -> void:
	var base := _v.size()
	var nb := _nbasis(xf)
	for k in range(other._v.size()):
		_v.append(xf * other._v[k])
		_n.append((nb * other._n[k]).normalized())
		_c.append(other._c[k])
	for k in other._i:
		_i.append(base + k)


func build() -> ArrayMesh:
	var mesh := ArrayMesh.new()
	if _v.is_empty():
		return mesh
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = _v
	arrays[Mesh.ARRAY_NORMAL] = _n
	arrays[Mesh.ARRAY_COLOR] = _c
	arrays[Mesh.ARRAY_INDEX] = _i
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func triangle_count() -> int:
	return _i.size() / 3
