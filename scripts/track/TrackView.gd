class_name TrackView
extends Node3D
## المشهد المرئي للمسار: ألواح، حبال، ديكور، عقبات، عملات، عناصر بعيدة. يعتمد MultiMesh وتقسيم الأجزاء (Chunks).

const CHUNK := 60.0
const WATER_Y := -24.0

var data: TrackData
var density := 1.0
var chunks: Array[Node3D] = []
var _rng := RandomNumberGenerator.new()
var coin_mm: MultiMesh
var crate_nodes: Dictionary = {}     # id(obstacle) -> Array[Node3D]
var hammer_pivots: Array = []        # [{node, o}]
var far_nodes: Node3D
var water: MeshInstance3D
var _coin_xf: Array[Transform3D] = []


func build(p_data: TrackData, p_density: float, progress: Callable = Callable()) -> void:
	data = p_data
	density = p_density
	_rng.seed = 20261122
	var n_chunks := int(ceil(TrackData.LENGTH / CHUNK))
	for ci in range(n_chunks):
		var node := Node3D.new()
		node.name = "Chunk%d" % ci
		add_child(node)
		chunks.append(node)
		_build_chunk(ci, node)
		if progress.is_valid():
			await progress.call(float(ci + 1) / float(n_chunks + 2))
	_build_coins()
	_build_far()
	_build_water()
	if progress.is_valid():
		await progress.call(1.0)


# ------------------------------------------------------------------ أدوات
func _mmi(mesh: Mesh, xfs: Array, cols: Array, mat: Material, parent: Node3D, shadow := false) -> void:
	if xfs.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = not cols.is_empty()
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	for i in range(xfs.size()):
		mm.set_instance_transform(i, xfs[i])
		if mm.use_colors:
			mm.set_instance_color(i, cols[i])
	var inst := MultiMeshInstance3D.new()
	inst.multimesh = mm
	if mat != null:
		inst.material_override = mat
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(inst)


func _frame_xf(s: float, x: float, y: float = 0.0) -> Transform3D:
	var f := data.frame(s)
	f.origin = data.center(s) + data.right(s) * x + Vector3.UP * y
	return f


func _place(s: float, x: float, y: float, yaw := 0.0, scl := 1.0) -> Transform3D:
	# موضع على مسافة جانبية مع محاذاة اتجاه المسار (للديكور)
	var origin := data.center(s) + data.right(s) * x
	origin.y = data.center(s).y + y
	var b := Basis(Vector3.UP, yaw + atan2(-data.forward(s).x, -data.forward(s).z)) * Basis.from_scale(Vector3.ONE * scl)
	return Transform3D(b, origin)


func _in_canyon(s: float) -> bool:
	for c in data.canyon:
		if s >= c[0] - 20.0 and s <= c[1] + 20.0:
			return true
	return false


# ------------------------------------------------------------------ جزء المسار
func _build_chunk(ci: int, node: Node3D) -> void:
	var s0 := float(ci) * CHUNK
	var s1 := minf(s0 + CHUNK, TrackData.LENGTH + 20.0)
	var boards: Array = []
	var board_cols: Array = []
	var stringers: Array = []
	var posts: Array = []
	var pennants: Array = []
	var s := s0
	while s < s1:
		var sm := s + 0.5
		for col in range(3):
			if data.solid_at(sm, TrackData.COLX[col]):
				var f := _frame_xf(sm, TrackData.COLX[col], 0.0)
				boards.append(f)
				var v := 0.9 + 0.12 * float((int(s) * 7 + col * 3) % 5) / 4.0
				var tint := Color(v, v * 0.97, v * 0.93)
				if int(s) % 2 == 0:
					tint = tint.darkened(0.05)
				if Toon.premium_enabled:
					# خشب معتّق: بني رمادي بتفاوت بين الألواح (بدل الأصفر الساطع)
					var wv := 0.52 + 0.20 * float((int(s) * 13 + col * 7) % 9) / 8.0
					tint = Color(wv * 0.95, wv * 0.78, wv * 0.60)
				board_cols.append(tint)
		s += 1.0
	# العوارض السفلية
	s = s0 + 3.0
	while s < s1:
		for xx in [-4.8, 0.0, 4.8]:
			if data.solid_at(s, xx):
				stringers.append(_frame_xf(s, xx, 0.0))
		s += 6.0
	var lanterns: Array = []
	# الأعمدة والحبال
	s = s0
	while s < s1:
		for sd in [-1.0, 1.0]:
			if data.solid_at(s, sd * 4.0):
				posts.append(_frame_xf(s, sd * 6.25, 0.0))
				if int(round(s / 3.0)) % 5 == 0:
					pennants.append(_frame_xf(s, sd * 6.25, 1.4))
				if int(round(s / 3.0)) % 4 == 0 and density >= 0.5:
					lanterns.append(_frame_xf(s, sd * 6.25, 0.0))
		s += 3.0
	_mmi(TrackProtos.get_mesh("board"), boards, board_cols, Toon.textured(1, 0.34), node, false)
	_mmi(TrackProtos.get_mesh("stringer"), stringers, [], Toon.textured(1, 0.34), node, false)
	_mmi(TrackProtos.get_mesh("post"), posts, [], Toon.textured(1, 0.34), node, true)
	if not Toon.premium_enabled:
		_mmi(TrackProtos.get_mesh("pennant"), pennants, [], Toon.double_sided(false), node, false)
		_mmi(TrackProtos.get_mesh("lantern"), lanterns, [], Toon.solid(false), node, false)
	_build_ropes(s0, s1, node)
	_build_scenery(s0, s1, node, ci)
	if Toon.premium_enabled:
		_build_premium_props(s0, s1, node)
	_build_obstacles(s0, s1, node)


func _build_ropes(s0: float, s1: float, node: Node3D) -> void:
	var mb := MeshBuilder.new()
	for sd in [-1.0, 1.0]:
		for lvl in [1.05, 0.55]:
			var pts: Array = []
			var s := s0
			while s <= s1 + 0.01:
				var sag := 0.14 * (1.0 - pow(fmod(s, 3.0) / 1.5 - 1.0, 2.0))
				pts.append(data.center(s) + data.right(s) * (sd * 6.25) + Vector3.UP * (lvl - sag))
				s += 0.75
			mb.add_tube(pts, 0.05, TrackProtos.ROPE, 5, Transform3D.IDENTITY, false, false)
	# عارضتان خشبيتان تحدّان حافتي الجسر (تعطيان عمقًا وتفصيلًا)
	for sd in [-1.0, 1.0]:
		var edge: Array = []
		var s2 := s0
		while s2 <= s1 + 0.01:
			edge.append(data.center(s2) + data.right(s2) * (sd * 6.6) + Vector3.UP * -0.14)
			s2 += 3.0
		mb.add_tube(edge, 0.17, TrackProtos.WOOD_D, 6, Transform3D.IDENTITY, false, false)
	var mi := MeshInstance3D.new()
	mi.mesh = mb.build()
	mi.material_override = Toon.solid(false)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(mi)


# ------------------------------------------------------------------ الديكور الجانبي
func _build_scenery(s0: float, s1: float, node: Node3D, ci: int) -> void:
	var palms_a: Array = []
	var palms_b: Array = []
	var bushes: Array = []
	var mush: Array = []
	var rocks_a: Array = []
	var rocks_b: Array = []
	var flowers: Array = []
	var pillars: Array = []
	var trees_r: Array = []
	var trees_c: Array = []
	var tufts: Array = []
	var flowers_b: Array = []
	var boulders: Array = []
	var d := density
	var canyon_here := _in_canyon(0.5 * (s0 + s1))
	# شريط الأرض الجانبي
	if not canyon_here:
		_build_ground_strip(s0, s1, node)
	var s := s0
	while s < s1:
		for sd in [-1.0, 1.0]:
			if canyon_here:
				if _rng.randf() < 0.22 * d:
					var xx: float = sd * _rng.randf_range(15.0, 34.0)
					pillars.append(_place(s + _rng.randf_range(0, 6), xx, -9.5, _rng.randf() * TAU, _rng.randf_range(0.8, 1.35)))
					var top_y := -1.6
					if _rng.randf() < 0.8:
						(palms_a if _rng.randf() < 0.5 else palms_b).append(_place(s, xx + _rng.randf_range(-1.5, 1.5), top_y, _rng.randf() * TAU, _rng.randf_range(0.8, 1.2)))
				continue
			# أشجار النخيل
			if _rng.randf() < 0.30 * d and not Toon.premium_enabled:
				var xp: float = sd * _rng.randf_range(10.5, 26.0)
				(palms_a if _rng.randf() < 0.5 else palms_b).append(_place(s + _rng.randf_range(0, 5), xp, -1.0, _rng.randf() * TAU, _rng.randf_range(0.85, 1.35)))
			if _rng.randf() < 0.55 * d and not Toon.premium_enabled:
				bushes.append(_place(s + _rng.randf_range(0, 5), sd * _rng.randf_range(7.8, 16.0), -1.0, _rng.randf() * TAU, _rng.randf_range(0.7, 1.4)))
			if _rng.randf() < 0.14 * d:
				mush.append(_place(s + _rng.randf_range(0, 5), sd * _rng.randf_range(8.0, 13.0), -1.0, _rng.randf() * TAU, _rng.randf_range(0.8, 1.6)))
			if _rng.randf() < 0.14 * d and not Toon.premium_enabled:
				(rocks_a if _rng.randf() < 0.5 else rocks_b).append(_place(s + _rng.randf_range(0, 5), sd * _rng.randf_range(8.0, 20.0), -1.1, _rng.randf() * TAU, _rng.randf_range(0.8, 1.8)))
			if d >= 0.5:
				if _rng.randf() < 0.20 * d and not Toon.premium_enabled:
					trees_r.append(_place(s + _rng.randf_range(0, 5), sd * _rng.randf_range(11.0, 30.0), -1.0, _rng.randf() * TAU, _rng.randf_range(0.8, 1.5)))
				if _rng.randf() < 0.16 * d and not Toon.premium_enabled:
					trees_c.append(_place(s + _rng.randf_range(0, 5), sd * _rng.randf_range(13.0, 34.0), -1.0, _rng.randf() * TAU, _rng.randf_range(0.8, 1.6)))
				if _rng.randf() < 0.05 * d and not Toon.premium_enabled:
					boulders.append(_place(s + _rng.randf_range(0, 5), sd * _rng.randf_range(15.0, 30.0), -1.2, _rng.randf() * TAU, _rng.randf_range(0.7, 1.4)))
				for k in range(2):
					flowers_b.append(_place(s + _rng.randf_range(0, 5), sd * _rng.randf_range(7.8, 13.0), -1.0, _rng.randf() * TAU, _rng.randf_range(0.8, 1.3)))
			for k in range(0 if Toon.premium_enabled else int(5.0 * d) + 1):
				tufts.append(_place(s + _rng.randf_range(0, 6), sd * _rng.randf_range(7.6, 20.0), -1.0, _rng.randf() * TAU, _rng.randf_range(0.8, 1.6)))
			if _rng.randf() < 0.9 * d:
				for k in range(3):
					flowers.append(_place(s + _rng.randf_range(0, 5), sd * _rng.randf_range(7.8, 12.0), -1.0, _rng.randf() * TAU, _rng.randf_range(0.8, 1.3)))
		s += 6.0
	_mmi(TrackProtos.get_mesh("palm_a"), palms_a, [], Toon.textured(2, 0.35, 0.05), node, true)
	_mmi(TrackProtos.get_mesh("palm_b"), palms_b, [], Toon.textured(2, 0.35, 0.05), node, true)
	_mmi(TrackProtos.get_mesh("bush"), bushes, [], Toon.textured(2, 0.42), node, false)
	if not Toon.premium_enabled:
		_mmi(TrackProtos.get_mesh("mushroom"), mush, [], Toon.solid(false), node, true)
	_mmi(TrackProtos.get_mesh("rock_a"), rocks_a, [], Toon.textured(3, 0.55), node, true)
	_mmi(TrackProtos.get_mesh("rock_b"), rocks_b, [], Toon.textured(3, 0.55), node, true)
	_mmi(TrackProtos.get_mesh("flower"), flowers, [], Toon.solid(false), node, false)
	_mmi(TrackProtos.get_mesh("pillar"), pillars, [], Toon.solid(false), node, false)
	_mmi(TrackProtos.get_mesh("tree_round"), trees_r, [], Toon.textured(2, 0.42), node, true)
	_mmi(TrackProtos.get_mesh("tree_cone"), trees_c, [], Toon.textured(2, 0.42), node, true)
	_mmi(TrackProtos.get_mesh("tuft"), tufts, [], Toon.textured(2, 0.42), node, false)
	_mmi(TrackProtos.get_mesh("flower_b"), flowers_b, [], Toon.solid(false), node, false)
	_mmi(TrackProtos.get_mesh("boulder"), boulders, [], Toon.textured(3, 0.55), node, true)


## ديكور «بريميوم»: صخور ونباتات حقيقية (PropLib) بمجموعات، مع LOD بالمسافة عبر visibility_range لكل شريحة 30 م.
## المسار وما حوله (إزاحة < 7.8 م) خالٍ دائمًا.
const LOD_RANGES := [[0.0, 45.0], [45.0, 95.0], [95.0, 400.0]]
const LOD_RANGES_TREE := [[0.0, 40.0], [40.0, 100.0], [100.0, 400.0]]


func _build_premium_props(s0: float, s1: float, node: Node3D) -> void:
	if _in_canyon(0.5 * (s0 + s1)):
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 9100 + int(s0)
	var slice_len := 30.0
	var kinds := ["rock1", "rock2", "rock3", "fern", "anthurium", "calathea", "tree_a", "tree_b", "tree_stump_01", "tree_stump_02", "dead_tree_trunk", "dead_tree_trunk_02", "root_cluster_01", "single_root"]
	var s_a := s0
	while s_a < s1:
		var buckets := {}
		for k in kinds:
			buckets[k] = []
		var n_rock := int(round(5.0 * density))
		for i in range(n_rock):
			var sd := -1.0 if rng.randf() < 0.5 else 1.0
			var k: String = "rock%d" % (1 + rng.randi() % 3)
			buckets[k].append(_place(s_a + rng.randf() * slice_len, sd * rng.randf_range(8.2, 22.0), -1.2, rng.randf() * TAU, rng.randf_range(0.9, 2.1)))
		var n_cl := int(round(7.0 * density))
		for c in range(n_cl):
			var sd2 := -1.0 if rng.randf() < 0.5 else 1.0
			var cs := s_a + rng.randf() * slice_len
			var cx := sd2 * rng.randf_range(8.2, 17.0)
			var kind: String = ["fern", "anthurium", "calathea"][rng.randi() % 3]
			for j in range(3 + rng.randi() % 3):
				var xx := cx + rng.randf_range(-1.6, 1.6)
				if absf(xx) < 7.6:
					continue
				buckets[kind].append(_place(cs + rng.randf_range(-1.8, 1.8), xx, -1.0, rng.randf() * TAU, rng.randf_range(1.6, 2.8)))
		# أشجار حقيقية (لحاء + أوراق) وبقايا خشب وجذور
		var n_tree := int(round(2.4 * density))
		for i in range(n_tree):
			var sdt := -1.0 if rng.randf() < 0.5 else 1.0
			var tk := "tree_a" if rng.randf() < 0.5 else "tree_b"
			buckets[tk].append(_place(s_a + rng.randf() * slice_len, sdt * rng.randf_range(10.5, 24.0), -1.0, rng.randf() * TAU, rng.randf_range(1.2, 2.0)))
		for i in range(int(round(2.0 * density))):
			var sdw := -1.0 if rng.randf() < 0.5 else 1.0
			var wk: String = ["tree_stump_01", "tree_stump_02", "dead_tree_trunk", "dead_tree_trunk_02", "root_cluster_01", "single_root"][rng.randi() % 6]
			buckets[wk].append(_place(s_a + rng.randf() * slice_len, sdw * rng.randf_range(8.4, 15.0), -1.0, rng.randf() * TAU, rng.randf_range(1.6, 2.6)))
		for k in kinds:
			var xfs: Array = buckets[k]
			if xfs.is_empty():
				continue
			var is_tree: bool = k.begins_with("tree_a") or k.begins_with("tree_b")
			var mat_kind: String = "rock" if k.begins_with("rock") else k
			var mat: Material = null if is_tree else PropLib.material(mat_kind, Toon.use_normal_maps)
			var ranges: Array = LOD_RANGES_TREE if is_tree else LOD_RANGES
			for lod in range(3):
				var m: Mesh = PropLib.tree_mesh(k, lod, Toon.use_normal_maps) if is_tree else PropLib.mesh(k, lod)
				if m == null:
					continue
				var before := node.get_child_count()
				_mmi(m, xfs, [], mat, node, lod == 0 and (mat_kind == "rock" or is_tree))
				var inst := node.get_child(node.get_child_count() - 1)
				if node.get_child_count() > before and inst is MultiMeshInstance3D:
					inst.visibility_range_begin = ranges[lod][0]
					inst.visibility_range_end = ranges[lod][1]
		s_a += slice_len


func _build_ground_strip(s0: float, s1: float, node: Node3D) -> void:
	# شريط أرض على الجانبين: حافة صخرية قرب الجسر ثم عشب ثم تلال بعيدة
	var mb := MeshBuilder.new()
	var xs := [7.4, 9.0, 18.0, 32.0, 52.0]
	var ys := [-1.0, -1.0, -1.0, 0.4, 3.5]
	var cols := [Color("c79ab0"), Color("5fd445"), Color("4ec23f"), Color("3fae3b"), Color("6ac4a8")]
	if Toon.premium_enabled:
		# ألوان غابة طبيعية: حافة ترابية، أرض عشبية داكنة، تلال خضراء عميقة
		cols = [Color("6b5238"), Color("3f5a2a"), Color("38512a"), Color("2f4a28"), Color("2a4a30")]
	for sd in [-1.0, 1.0]:
		var rows := int((s1 - s0) / 4.0) + 1
		var prev: Array = []
		for r in range(rows + 1):
			var s := minf(s0 + float(r) * 4.0, s1)
			var cur: Array = []
			for k in range(xs.size()):
				cur.append(data.center(s) + data.right(s) * (sd * xs[k]) + Vector3(0, ys[k], 0))
			if r > 0:
				for k in range(xs.size() - 1):
					var c0: Color = cols[k]
					var c1: Color = cols[k + 1]
					var a: Vector3 = prev[k]
					var b: Vector3 = prev[k + 1]
					var c: Vector3 = cur[k + 1]
					var dd: Vector3 = cur[k]
					# ترتيب يضمن أن الوجه العلوي ظاهر لكلا الجانبين
					if sd > 0:
						mb.add_triangle(a, c, dd, c0.lerp(c1, 0.5))
						mb.add_triangle(a, b, c, c0.lerp(c1, 0.5))
					else:
						mb.add_triangle(a, dd, c, c0.lerp(c1, 0.5))
						mb.add_triangle(a, c, b, c0.lerp(c1, 0.5))
			prev = cur
		# جدار الحافة الصخرية نحو الأسفل
		prev = []
		for r in range(rows + 1):
			var s2 := minf(s0 + float(r) * 4.0, s1)
			var top: Vector3 = data.center(s2) + data.right(s2) * (sd * 7.4) + Vector3(0, -1.0, 0)
			var bot: Vector3 = data.center(s2) + data.right(s2) * (sd * 7.0) + Vector3(0, -9.0, 0)
			var cur2 := [top, bot]
			if r > 0:
				var a2: Vector3 = prev[0]
				var b2: Vector3 = prev[1]
				var c2: Vector3 = cur2[1]
				var d2: Vector3 = cur2[0]
				var cc := Color("9a7aa6") if not Toon.premium_enabled else Color("5a4632")
				if sd > 0:
					mb.add_triangle(a2, b2, c2, cc)
					mb.add_triangle(a2, c2, d2, cc)
					mb.add_triangle(a2, c2, b2, cc)
					mb.add_triangle(a2, d2, c2, cc)
				else:
					mb.add_triangle(a2, c2, b2, cc)
					mb.add_triangle(a2, d2, c2, cc)
					mb.add_triangle(a2, b2, c2, cc)
					mb.add_triangle(a2, c2, d2, cc)
			prev = cur2
	var mi := MeshInstance3D.new()
	mi.mesh = mb.build()
	mi.material_override = Toon.premium(4) if Toon.premium_enabled else Toon.textured(2, 0.40, 0.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(mi)


# ------------------------------------------------------------------ العقبات
func _mesh_node(proto: String, xf: Transform3D, parent: Node3D, mat: Material = null, shadow := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = TrackProtos.get_mesh(proto)
	mi.material_override = mat if mat else Toon.solid(false)
	mi.transform = xf
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


func _build_obstacles(s0: float, s1: float, node: Node3D) -> void:
	for o in data.obstacles:
		var so: float = o.s
		if so < s0 or so >= s1:
			continue
		match o.type:
			"log":
				var len: float = o.x1 - o.x0
				var f := _frame_xf(so, o.x0, 0.0)
				var fs := f
				fs.basis = f.basis * Basis.from_scale(Vector3(len, 1.0, 1.0))
				_mesh_node("log", fs, node)
				_mesh_node("log_end", f, node)
				var fe := _frame_xf(so, o.x1, 0.0)
				fe.basis = fe.basis * Basis(Vector3.UP, PI)
				_mesh_node("log_end", fe, node)
			"vine":
				var len2: float = o.x1 - o.x0
				var x0v: float = o.x0
				var x1v: float = o.x1
				var fb := _frame_xf(so, x0v, 0.0)
				fb.basis = fb.basis * Basis.from_scale(Vector3(len2, 1.0, 1.0))
				_mesh_node("vine_gate", fb, node)
				for xe in [x0v + (0.4 if x0v > -5.9 else -0.3), x1v - (0.4 if x1v < 5.9 else -0.3)]:
					_mesh_node("gate_post", _frame_xf(so, xe, 0.0), node)
				var xv := x0v + 0.9
				while xv < x1v - 0.5:
					_mesh_node("vine_hang", _frame_xf(so, xv, 0.0), node, Toon.double_sided(false), false)
					xv += 1.7
			"crate":
				var arr: Array = []
				for lv in range(int(o.levels)):
					arr.append(_mesh_node("crate", _frame_xf(so, o.x, 1.25 * float(lv)), node))
				crate_nodes[crate_key(o)] = arr
			"hammer":
				if o.px < 0.0:
					# بوابة التعليق تُبنى مرة واحدة لكل زوج
					_build_gantry(so, node)
				var pivot := Node3D.new()
				pivot.transform = _frame_xf(so, o.px, o.pivot_y)
				node.add_child(pivot)
				_mesh_node("hammer_arm", Transform3D.IDENTITY, pivot)
				_mesh_node("hammer_head", Transform3D(Basis(), Vector3(0, -o.len, 0)), pivot)
				hammer_pivots.append({"node": pivot, "o": o})
	# مسرّعات
	for p in data.pads:
		if p.s >= s0 and p.s < s1:
			_mesh_node("pad", _frame_xf(p.s, p.x, 0.03), node, null, false)
	# لافتات تحذير عند الحفر
	for sg in data.signs:
		if sg >= s0 and sg < s1:
			for sd in [-1.0, 1.0]:
				_mesh_node("sign", _frame_xf(sg, sd * 5.7, 0.0), node)
	# بوابتا البداية والنهاية
	if s0 <= 26.0 and s1 > 26.0:
		_arch(26.0, node, "START")
	if s0 <= TrackData.FINISH_S and s1 > TrackData.FINISH_S:
		_arch(TrackData.FINISH_S, node, "FINISH")


func _build_gantry(s: float, node: Node3D) -> void:
	var span := 7.0
	for sd in [-1.0, 1.0]:
		var f := _frame_xf(s, sd * span, 0.0)
		f.basis = f.basis * Basis.from_scale(Vector3(1.0, 3.0, 1.0))
		_mesh_node("gate_post", f, node)
	var fb := _frame_xf(s, -span, 5.0)
	fb.basis = fb.basis * Basis.from_scale(Vector3(span * 2.0, 0.95, 1.0))
	_mesh_node("vine_gate", fb, node)


func _arch(s: float, node: Node3D, label: String) -> void:
	_mesh_node("arch", _frame_xf(s, 0.0, 0.0), node)
	var lb := Label3D.new()
	lb.text = label
	lb.font_size = 160
	lb.pixel_size = 0.012
	lb.outline_size = 24
	lb.modulate = Color("ffd23a")
	lb.outline_modulate = Color("3a1a7a")
	lb.no_depth_test = false
	lb.double_sided = false
	lb.font = load("res://assets/fonts/Cairo.ttf")
	var f := _frame_xf(s, 0.0, 7.55)
	f.origin += data.forward(s) * -0.45
	lb.transform = f
	node.add_child(lb)


# ------------------------------------------------------------------ عملات
func _build_coins() -> void:
	coin_mm = MultiMesh.new()
	coin_mm.transform_format = MultiMesh.TRANSFORM_3D
	coin_mm.mesh = TrackProtos.get_mesh("coin")
	coin_mm.instance_count = data.coins.size()
	for i in range(data.coins.size()):
		var c: Vector3 = data.coins[i]
		var f := _frame_xf(c.x, c.y, c.z)
		_coin_xf.append(f)
		coin_mm.set_instance_transform(i, f)
	var inst := MultiMeshInstance3D.new()
	inst.multimesh = coin_mm
	inst.material_override = Toon.coin()
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	inst.custom_aabb = AABB(Vector3(-2000, -300, -2000), Vector3(4000, 800, 4000))
	add_child(inst)


func hide_coin(i: int) -> void:
	var t := Transform3D(Basis.from_scale(Vector3.ZERO), _coin_xf[i].origin)
	coin_mm.set_instance_transform(i, t)


func crate_key(o: Dictionary) -> int:
	return int(float(o.s) * 100.0 + float(o.x) * 7.0)


func break_crate(o: Dictionary) -> Array:
	var arr: Array = crate_nodes.get(crate_key(o), [])
	var positions: Array = []
	for n in arr:
		if is_instance_valid(n):
			positions.append(n.global_position + Vector3(0, 0.6, 0))
			n.queue_free()
	crate_nodes.erase(crate_key(o))
	return positions


# ------------------------------------------------------------------ عناصر بعيدة

## أقصر مسافة أفقية بين نقطة في العالم ومحور المسار (للتأكد أن العناصر البعيدة لا تقع فوق منعطفات الحلبة المتعرجة).
func _dist_to_track(w: Vector3) -> float:
	var best := 1e9
	for i in range(0, data.pos.size(), 4):
		var d := Vector2(data.pos[i].x - w.x, data.pos[i].z - w.z).length()
		if d < best:
			best = d
	return best


## يجرّب جانبي المسار ومسافتين إضافيتين حتى يجد موضعًا بعيدًا بما يكفي؛ يعيد null إن لم يجد. في التخطيط 0 يعيد الموضع الأصلي كما هو.
func _far_place(s: float, sd: float, lat: float, y: float, yaw: float, scl: float, clearance: float) -> Variant:
	var xf := _place(s, sd * lat, y, yaw, scl)
	if TrackData.layout == 0:
		return xf
	for mult in [1.0, -1.0, 1.5, -1.5, 2.0, -2.0]:
		xf = _place(s, sd * lat * mult, y, yaw, scl)
		if _dist_to_track(xf.origin) >= clearance:
			return xf
	return null

## مادة التلال البعيدة: في بريميوم تلال غابة خضراء داكنة يخففها الضباب بدل الجبال البيضاء الناعمة.
func _far_mat() -> Material:
	if not Toon.premium_enabled:
		return Toon.solid(false)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("1f4429")
	m.roughness = 1.0
	return m


func _cliff_mat() -> Material:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("4a4638")
	m.roughness = 1.0
	return m


func _build_far() -> void:
	far_nodes = Node3D.new()
	far_nodes.name = "Far"
	add_child(far_nodes)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var castle_s := [120.0, 330.0, 600.0, 860.0]
	for k in range(0 if Toon.premium_enabled else castle_s.size()):
		var sd := -1.0 if k % 2 == 0 else 1.0
		var s: float = castle_s[k]
		var xf: Variant = _far_place(s, sd, rng.randf_range(95.0, 125.0), rng.randf_range(34.0, 48.0), 0.0, 1.35, 70.0)
		if xf != null:
			_mesh_node("castle", xf, far_nodes, Toon.solid(false), false)
	for k in range(9):
		var s2 := float(k) * 125.0 + 30.0
		var sd2 := -1.0 if k % 2 == 0 else 1.0
		var m1: Variant = _far_place(s2, sd2, rng.randf_range(210.0, 280.0), -40.0, rng.randf() * TAU, rng.randf_range(1.2, 1.9), 170.0)
		if m1 != null:
			_mesh_node("mountain", m1, far_nodes, _far_mat(), false)
		var m2: Variant = _far_place(s2 + 60.0, -sd2, rng.randf_range(230.0, 300.0), -45.0, rng.randf() * TAU, rng.randf_range(1.2, 1.8), 170.0)
		if m2 != null:
			_mesh_node("mountain", m2, far_nodes, _far_mat(), false)
	for k in range(3 if Toon.premium_enabled else 16):
		var s3 := rng.randf_range(0.0, TrackData.LENGTH)
		var sd3 := -1.0 if k % 2 == 0 else 1.0
		_mesh_node("cloud", _place(s3, sd3 * rng.randf_range(30.0, 140.0), rng.randf_range(45.0, 90.0), rng.randf() * TAU, rng.randf_range(0.8, 1.8)), far_nodes, Toon.solid(false), false)
	# جروف وشلالات في منطقة الوادي
	for c in data.canyon:
		var s4: float = c[0] + 15.0
		while s4 < c[1]:
			for sd4 in [-1.0, 1.0]:
				var x4: float = sd4 * rng.randf_range(58.0, 80.0)
				var xf4 := _place(s4, x4, -2.0, rng.randf() * TAU, 1.5)
				_mesh_node("cliff", xf4, far_nodes, _cliff_mat() if Toon.premium_enabled else Toon.solid(false), false)
				var fall := _mesh_node("waterfall", Transform3D(Basis(Vector3.UP, atan2(-sd4, 0.0) + (PI * 0.5 if sd4 > 0 else -PI * 0.5)), xf4.origin + Vector3(-sd4 * 17.0, 13.0, 0)), far_nodes, Toon.waterfall(), false)
				fall.look_at_from_position(xf4.origin + data.right(s4) * (-sd4 * 17.0) + Vector3(0, 12.0, 0), data.center(s4) + Vector3(0, 12.0, 0), Vector3.UP)
			s4 += 70.0


func _build_water() -> void:
	water = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(900, 900)
	water.mesh = pm
	water.material_override = Toon.water()
	water.position = Vector3(0, WATER_Y, 0)
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(water)


# ------------------------------------------------------------------ تحديث كل إطار
func update_visibility(s: float, view_dist: float) -> void:
	var ci := int(s / CHUNK)
	var ahead := int(ceil(view_dist / CHUNK))
	for i in range(chunks.size()):
		chunks[i].visible = i >= ci - 1 and i <= ci + ahead
	if water:
		var c := data.center(s)
		water.position = Vector3(c.x, WATER_Y, c.z)


func update_hammers(t: float) -> void:
	for h in hammer_pivots:
		var o: Dictionary = h.o
		var th: float = o.amp * sin(o.omega * t + o.phase)
		(h.node as Node3D).rotation.z = th
