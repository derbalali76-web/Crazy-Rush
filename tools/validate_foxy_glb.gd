extends SceneTree
## فاحص نموذج فوكسي الجديد قبل الدمج.
##   godot --headless --import            (مرة بعد وضع الملف في المشروع)
##   godot --headless -s tools/validate_foxy_glb.gd -- res://assets/characters/NEW.glb [res://assets/characters/foxy_map.json]
## يطبع تقريرًا: ERROR = لا يمكن دمجه كما هو، WARN = تنبيه، OK = سليم. رمز الخروج 1 عند وجود ERROR.

const REQUIRED_BONES := ["root", "hips", "head", "arm.L", "forearm.L", "arm.R", "forearm.R",
	"thigh.L", "shin.L", "thigh.R", "shin.R", "ear.L", "ear.R",
	"tail.1", "tail.2", "tail.3", "scarf.1", "scarf.2", "scarf.3"]
const CORE_BONES := ["hips", "head", "arm.L", "forearm.L", "arm.R", "forearm.R", "thigh.L", "shin.L", "thigh.R", "shin.R"]
const REQUIRED_CLIPS := ["idle", "run", "dash", "turn_l", "turn_r", "jump", "fall", "land", "slide",
	"stumble", "pit_fall", "victory", "punch", "punch_l"]
const MAX_TRIS_HERO := 12000
const MAX_TRIS_WARN := 8000

var errors := 0
var warns := 0


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		print("usage: -- res://path/model.glb [res://path/map.json]")
		quit(2)
		return
	var path: String = args[0]
	var cmap := {}
	var bone_map := {}
	if args.size() > 1 and FileAccess.file_exists(args[1]):
		var d = JSON.parse_string(FileAccess.get_file_as_string(args[1]))
		if d is Dictionary:
			cmap = d.get("clips", {})
			bone_map = d.get("bones", {})
	if not ResourceLoader.exists(path):
		_err("file not found or not imported: %s (run --import first)" % path)
		_finish()
		return
	var ps: PackedScene = load(path)
	var m: Node3D = ps.instantiate()
	root.add_child(m)
	await process_frame
	var sk: Skeleton3D
	var ap: AnimationPlayer
	var meshes: Array[MeshInstance3D] = []
	for c in m.find_children("*", "", true, false):
		if c is Skeleton3D and sk == null:
			sk = c
		elif c is AnimationPlayer and ap == null:
			ap = c
		elif c is MeshInstance3D:
			meshes.append(c)
	# --- هيكل
	if sk == null:
		_err("no Skeleton3D: the model must be skinned (not rigid parts)")
	else:
		print("skeleton: %d bones" % sk.get_bone_count())
		var missing := []
		for b in REQUIRED_BONES:
			var actual := String(bone_map.get(b, b))
			if sk.find_bone(actual) < 0:
				missing.append("%s%s" % [b, "" if actual == b else " (mapped to %s)" % actual])
		if not missing.is_empty():
			var core_missing := missing.filter(func(x): return String(x).split(" ")[0] in CORE_BONES)
			if core_missing.is_empty():
				_warn("missing optional bones (secondary motion will be absent): %s" % ", ".join(missing))
			else:
				_err("missing core bones: %s  -> add a \"bones\" map or retarget (see spec §8)" % ", ".join(core_missing))
		else:
			_ok("all 19 required bone names present")
		if sk.get_bone_count() > 60:
			_warn("%d bones: mobile skinning cost rises; aim for <= 40" % sk.get_bone_count())
	# --- مقاطع
	if ap == null:
		_err("no AnimationPlayer: animations missing")
	else:
		var list: PackedStringArray = ap.get_animation_list()
		print("clips: ", ", ".join(list))
		var mc := []
		for c in REQUIRED_CLIPS:
			var actual := String(cmap.get(c, c))
			if not (actual in list):
				mc.append("%s%s" % [c, "" if actual == c else " (mapped to %s)" % actual])
		if mc.is_empty():
			_ok("all %d required clips present" % REQUIRED_CLIPS.size())
		else:
			_err("missing clips: %s  -> rename in DCC or add \"clips\" map" % ", ".join(mc))
		for c in ["run", "dash", "turn_l", "turn_r"]:
			var actual := String(cmap.get(c, c))
			if actual in list:
				var a := ap.get_animation(actual)
				if a.length < 0.15 or a.length > 1.2:
					_warn("clip %s length %.2fs: stride is time-scaled by speed/13, aim for one full stride cycle ~0.3-0.5 s" % [c, a.length])
		var ref_run := String(cmap.get("run", "run"))
		if ref_run in list:
			var ra := ap.get_animation(ref_run)
			var tracks := ra.get_track_count()
			print("run clip tracks: %d, length %.3f s" % [tracks, ra.length])
	# --- شبكات
	var tris := 0
	var surfaces := 0
	var any_uv := false
	var any_color := false
	var infl_over := 0
	var aabb := AABB()
	var first := true
	for mi in meshes:
		if mi.mesh == null:
			continue
		for s in range(mi.mesh.get_surface_count()):
			surfaces += 1
			var arr := mi.mesh.surface_get_arrays(s)
			var idx = arr[Mesh.ARRAY_INDEX]
			tris += (idx.size() if idx != null else arr[Mesh.ARRAY_VERTEX].size()) / 3
			any_uv = any_uv or arr[Mesh.ARRAY_TEX_UV] != null
			any_color = any_color or arr[Mesh.ARRAY_COLOR] != null
			if arr[Mesh.ARRAY_BONES] != null:
				var per: int = arr[Mesh.ARRAY_BONES].size() / arr[Mesh.ARRAY_VERTEX].size()
				if per > 4:
					infl_over += 1
			var mat := mi.mesh.surface_get_material(s)
			if mat is BaseMaterial3D:
				for tex_prop in ["albedo_texture", "normal_texture", "orm_texture", "metallic_texture", "roughness_texture", "emission_texture"]:
					var t = mat.get(tex_prop)
					if t is Texture2D:
						var sz: Vector2 = t.get_size()
						print("texture %s on %s: %dx%d" % [tex_prop, mi.name, sz.x, sz.y])
						if maxf(sz.x, sz.y) > 2048.0:
							_err("texture %s is %dx%d: max 2048 (prefer 1024) for Android" % [tex_prop, sz.x, sz.y])
						elif maxf(sz.x, sz.y) > 1024.0:
							_warn("texture %s is %dx%d: 1024 recommended for 8 racers on mid-range phones" % [tex_prop, sz.x, sz.y])
		var wb := mi.global_transform * mi.get_aabb()
		aabb = wb if first else aabb.merge(wb)
		first = false
	print("meshes: %d, surfaces: %d, triangles: %d" % [meshes.size(), surfaces, tris])
	if tris > MAX_TRIS_HERO:
		_err("%d triangles > %d: too heavy for 8 racers on Android (see spec §6)" % [tris, MAX_TRIS_HERO])
	elif tris > MAX_TRIS_WARN:
		_warn("%d triangles: acceptable for the player, heavy for 7 rivals; ship a LOD at <= 5000" % tris)
	else:
		_ok("%d triangles within budget" % tris)
	if surfaces > 4:
		_warn("%d surfaces/materials: each is a draw call x8 racers (+ outline pass); aim for <= 3" % surfaces)
	if infl_over > 0:
		_err("skin has more than 4 influences per vertex on %d surfaces: re-export with 4 max" % infl_over)
	if not any_uv and not FoxyGLB.keep_model_materials:
		print("note: no UVs (fine only while using vertex-color toon materials)")
	if any_uv and not any_color:
		print("note: textured model with no vertex colors: set \"keep_model_materials\": true in foxy_map.json")
	# --- مقياس واتجاه
	var h := aabb.size.y
	print("bounds (model units): size=%s  min.y=%.3f" % [aabb.size, aabb.position.y])
	if h < 1.0 or h > 4.0:
		_err("height %.2f: expected ~2.27 (ears included), feet at y=0. Wrong scale/unit (cm?)" % h)
	elif absf(h - 2.27) > 0.4:
		_warn("height %.2f differs from the reference 2.27: set scale at export; runtime applies x0.85" % h)
	else:
		_ok("height %.2f matches the reference (2.27)" % h)
	if absf(aabb.position.y) > 0.1:
		_err("feet are not at y=0 (min.y=%.2f): fix the origin so the soles sit on y=0" % aabb.position.y)
	if sk != null and sk.find_bone("hips") >= 0 and sk.find_bone("tail.1") >= 0 and sk.find_bone("head") >= 0:
		var tz := sk.get_bone_global_rest(sk.find_bone("tail.1")).origin.z
		var hz := sk.get_bone_global_rest(sk.find_bone("hips")).origin.z
		if tz > hz:
			_ok("facing: tail is behind hips on +Z, so the character faces -Z (correct for Godot)")
		else:
			_err("facing is inverted: the character must face -Z in Godot (+Y in Blender before export)")
	_finish()


func _ok(msg: String) -> void:
	print("OK    ", msg)


func _warn(msg: String) -> void:
	warns += 1
	print("WARN  ", msg)


func _err(msg: String) -> void:
	errors += 1
	print("ERROR ", msg)


func _finish() -> void:
	print("---- validation: %d error(s), %d warning(s)" % [errors, warns])
	quit(1 if errors > 0 else 0)
