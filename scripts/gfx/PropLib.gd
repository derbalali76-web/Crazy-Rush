class_name PropLib
extends RefCounted
## مكتبة الديكور المبني من نماذج Poly Haven (CC0) بعد التبسيط في Blender (tools/blender/bake_props.py).
## كل مجسم له 3 مستويات LOD (assets/art/props/<name>_lod{0,1,2}.glb) ومادة PBR تشاركها كل المستويات.

const DIR := "res://assets/art/props/"
const TEX := "res://assets/src/models/"
## اسم المجسم -> [مجلد النسيج, بادئة الملفات, خشونة، تبسيط اللون]
const MATS := {
	"rock": ["rock_moss_set_01", "rock_moss_set_01", 1.0],
	"fern": ["fern_02", "fern_02", 1.0],
	"anthurium": ["anthurium_botany_01", "anthurium_botany_01", 1.0],
	"calathea": ["calathea_orbifolia_01", "calathea_orbifolia_01", 1.0],
}

## مجسمات مبسّطة من CI بنسيج واحد: الاسم -> (diff, nor) في assets/art/props/tex
const TREE_PROPS := ["tree_stump_01", "tree_stump_02", "dead_tree_trunk", "dead_tree_trunk_02", "root_cluster_01", "single_root", "dead_quiver_trunk"]

## شجرتان مولَّدتان (tools/blender/build_trees.py): سطح 0 لحاء (Bark001) وسطح 1 أوراق (الكالاثيا).
static func apply_tree_materials(mi: MeshInstance3D, use_normal := true) -> void:
	var bark := StandardMaterial3D.new()
	bark.albedo_texture = load("res://assets/src/textures/Bark001/albedo.jpg")
	bark.uv1_triplanar = false
	bark.roughness = 0.95
	bark.albedo_color = Color(0.62, 0.50, 0.40)   # يغمّق لحاء Bark001 الفاتح ليبدو غابة استوائية
	if use_normal and ResourceLoader.exists("res://assets/src/textures/Bark001/normal.jpg"):
		bark.normal_enabled = true
		bark.normal_texture = load("res://assets/src/textures/Bark001/normal.jpg")
	mi.set_surface_override_material(0, bark)
	var lm := material("calathea", use_normal).duplicate() as StandardMaterial3D
	lm.albedo_color = Color(1.45, 1.55, 1.1)   # يفتّح الأوراق ويميلها للأخضر المصفر
	mi.set_surface_override_material(1, lm)


static var _mat_cache := {}
static var _mesh_cache := {}


static func material(kind: String, use_normal := true) -> StandardMaterial3D:
	var key := "%s_%s" % [kind, use_normal]
	if _mat_cache.has(key):
		return _mat_cache[key]
	if kind in TREE_PROPS:
		var tm := StandardMaterial3D.new()
		tm.albedo_texture = load(DIR + "tex/%s_diff.jpg" % kind)
		if use_normal and ResourceLoader.exists(DIR + "tex/%s_nor.jpg" % kind):
			tm.normal_enabled = true
			tm.normal_texture = load(DIR + "tex/%s_nor.jpg" % kind)
		tm.roughness = 0.9
		tm.cull_mode = BaseMaterial3D.CULL_DISABLED
		tm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		_mat_cache[key] = tm
		return tm
	var info: Array = MATS[kind]
	var base: String = TEX + info[0] + "/textures/" + info[1]
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(base + "_diff_1k.jpg")
	if use_normal:
		m.normal_enabled = true
		m.normal_texture = load(base + "_nor_gl_1k.jpg")
	var rough_path := base + "_rough_1k.jpg"
	if ResourceLoader.exists(rough_path):
		m.roughness_texture = load(rough_path)
	else:
		m.roughness = 0.85
	m.cull_mode = BaseMaterial3D.CULL_DISABLED if kind != "rock" else BaseMaterial3D.CULL_BACK
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_mat_cache[key] = m
	return m


## يعيد أول شبكة داخل ملف GLB (null إن لم توجد).
static func mesh(name: String, lod: int) -> Mesh:
	var path := "%s%s_lod%d.glb" % [DIR, name, lod]
	if _mesh_cache.has(path):
		return _mesh_cache[path]
	var ps: PackedScene = load(path)
	if ps == null:
		return null
	var root := ps.instantiate()
	var found: Mesh = null
	var stack: Array = [root]
	while not stack.is_empty() and found == null:
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			found = (n as MeshInstance3D).mesh
		for c in n.get_children():
			stack.append(c)
	root.free()
	_mesh_cache[path] = found
	return found


## شبكة شجرة بموادها مضمّنة في الأسطح (MultiMesh لا يدعم تجاوز مادة لكل سطح).
static func tree_mesh(name: String, lod: int, use_normal := true) -> Mesh:
	var key := "treemesh_%s_%d_%s" % [name, lod, use_normal]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var src := mesh(name, lod)
	if src == null:
		return null
	var m: Mesh = src.duplicate()
	var holder := MeshInstance3D.new()
	holder.mesh = m
	apply_tree_materials(holder, use_normal)
	for i in range(m.get_surface_count()):
		m.surface_set_material(i, holder.get_surface_override_material(i))
	holder.free()
	_mesh_cache[key] = m
	return m
