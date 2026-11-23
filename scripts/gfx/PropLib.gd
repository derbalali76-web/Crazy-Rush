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

static var _mat_cache := {}
static var _mesh_cache := {}


static func material(kind: String, use_normal := true) -> StandardMaterial3D:
	var key := "%s_%s" % [kind, use_normal]
	if _mat_cache.has(key):
		return _mat_cache[key]
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
