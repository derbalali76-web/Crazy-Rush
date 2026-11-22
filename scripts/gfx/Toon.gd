class_name Toon
extends RefCounted
## مصنع الخامات الكرتونية. الخامات مشتركة (Cache) لتقليل تغييرات الحالة على المعالج الرسومي.

static var _cache: Dictionary = {}


static func _shader(path: String) -> Shader:
	return load(path) as Shader


static func solid(outline := false, thickness := 0.018) -> ShaderMaterial:
	return _fetch("solid", outline, thickness)


static func double_sided(outline := false) -> ShaderMaterial:
	return _fetch("double", outline, 0.0)


static func foliage(wind := 0.12) -> ShaderMaterial:
	var key := "foliage_%.2f" % wind
	if _cache.has(key):
		return _cache[key]
	var m := ShaderMaterial.new()
	m.shader = _shader("res://shaders/toon_double.gdshader")
	m.set_shader_parameter("wind_amount", wind)
	m.set_shader_parameter("rim_amount", 0.12)
	_cache[key] = m
	return m


static func glossy(outline := false, thickness := 0.018) -> ShaderMaterial:
	var key := "glossy_%s" % outline
	if _cache.has(key):
		return _cache[key]
	var m := _make("res://shaders/toon.gdshader")
	m.set_shader_parameter("spec_amount", 0.9)
	if outline:
		m.next_pass = outline_material(thickness)
	_cache[key] = m
	return m


static func ghost(color := Color(0.45, 0.9, 1.0)) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(color.r, color.g, color.b, 0.45)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.no_depth_test = false
	return m


static func outline_material(thickness := 0.018) -> ShaderMaterial:
	var key := "outline_%.3f" % thickness
	if _cache.has(key):
		return _cache[key]
	var m := ShaderMaterial.new()
	m.shader = _shader("res://shaders/outline.gdshader")
	m.set_shader_parameter("thickness", thickness)
	_cache[key] = m
	return m


static func coin() -> ShaderMaterial:
	if _cache.has("coin"):
		return _cache["coin"]
	var m := ShaderMaterial.new()
	m.shader = _shader("res://shaders/coin.gdshader")
	_cache["coin"] = m
	return m


static func water() -> ShaderMaterial:
	if _cache.has("water"):
		return _cache["water"]
	var m := ShaderMaterial.new()
	m.shader = _shader("res://shaders/water.gdshader")
	_cache["water"] = m
	return m


static func waterfall() -> ShaderMaterial:
	if _cache.has("waterfall"):
		return _cache["waterfall"]
	var m := ShaderMaterial.new()
	m.shader = _shader("res://shaders/waterfall.gdshader")
	_cache["waterfall"] = m
	return m


static func _make(shader_path: String) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _shader(shader_path)
	return m


static func _fetch(kind: String, outline: bool, thickness: float) -> ShaderMaterial:
	var key := "%s_%s_%.3f" % [kind, outline, thickness]
	if _cache.has(key):
		return _cache[key]
	var m := _make("res://shaders/toon_double.gdshader" if kind == "double" else "res://shaders/toon.gdshader")
	if outline:
		m.next_pass = outline_material(thickness)
	_cache[key] = m
	return m


static func mesh_instance(mesh: Mesh, material: Material, parent: Node = null, pos := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	if parent:
		parent.add_child(mi)
	return mi
