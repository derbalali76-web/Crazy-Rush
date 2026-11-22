class_name FoxyGLB
extends Foxy
## فوكسي بنموذج GLB حقيقي (Skeleton3D + جلد) مولَّد بـ tools/blender/build_foxy.py.
## نفس واجهة Foxy (anim, run_speed, lean, vy, notify_*, set_hue, make_ghost...) فيُستبدل بلا تغيير في منطق السباق.
## الحركة: AnimationTree (آلة حالات + BlendSpace1D للانعطاف + TimeScale للخطوة + OneShot للكمة).

static var GLB_PATH := "res://assets/characters/foxy.glb"
const LOOPED := ["idle", "run", "dash", "turn_l", "turn_r", "jump", "fall", "slide", "stumble", "pit_fall", "victory"]
const GSTATES := ["idle", "run", "dash", "jump", "fall", "land", "slide", "stumble", "pit_fall", "victory"]
const GXFADE := {"idle": 0.18, "run": 0.14, "dash": 0.08, "jump": 0.07, "fall": 0.12, "land": 0.05,
	"slide": 0.08, "stumble": 0.05, "pit_fall": 0.08, "victory": 0.15}

var model: Node3D
var skeleton: Skeleton3D
var gplayer: AnimationPlayer
var gtree: AnimationTree
var _gplayback: AnimationNodeStateMachinePlayback
var _gstate := ""


static func available() -> bool:
	return ResourceLoader.exists(GLB_PATH)


func build(outline := true) -> void:
	if body != null:
		return
	body = Node3D.new()
	body.name = "Body"
	add_child(body)
	var ps: PackedScene = load(GLB_PATH)
	model = ps.instantiate()
	body.add_child(model)
	for c in model.find_children("*", "", true, false):
		if c is Skeleton3D:
			skeleton = c
		elif c is AnimationPlayer:
			gplayer = c
		elif c is MeshInstance3D:
			var mi: MeshInstance3D = c
			var nm := String(mi.name)
			if nm.begins_with("Glossy"):
				mi.material_override = Toon.glossy(outline, 0.012)
			elif nm.begins_with("Scarf"):
				mi.material_override = Toon.double_sided(false)
			else:
				mi.material_override = Toon.solid(outline, 0.016)
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			mi.extra_cull_margin = 1.0
			_meshes.append(mi)
	scale = Vector3.ONE * SCALE_FACTOR
	for a in gplayer.get_animation_list():
		gplayer.get_animation(a).loop_mode = Animation.LOOP_LINEAR if a in LOOPED else Animation.LOOP_NONE
	_setup_gtree()


func _setup_gtree() -> void:
	var sm := AnimationNodeStateMachine.new()
	var i := 0
	for st in GSTATES:
		var node: AnimationRootNode
		if st == "run":
			var bt := AnimationNodeBlendTree.new()
			var bs := AnimationNodeBlendSpace1D.new()
			bs.min_space = -1.0
			bs.max_space = 1.0
			for pair in [["turn_l", -1.0], ["run", 0.0], ["turn_r", 1.0]]:
				var an := AnimationNodeAnimation.new()
				an.animation = pair[0]
				bs.add_blend_point(an, pair[1])
			var ts := AnimationNodeTimeScale.new()
			bt.add_node("turn", bs, Vector2(-300, 0))
			bt.add_node("ts", ts, Vector2(-150, 0))
			bt.connect_node("ts", 0, "turn")
			bt.connect_node("output", 0, "ts")
			node = bt
		elif st == "dash":
			var bt2 := AnimationNodeBlendTree.new()
			var an2 := AnimationNodeAnimation.new()
			an2.animation = "dash"
			var ts2 := AnimationNodeTimeScale.new()
			bt2.add_node("clip", an2, Vector2(-300, 0))
			bt2.add_node("ts", ts2, Vector2(-150, 0))
			bt2.connect_node("ts", 0, "clip")
			bt2.connect_node("output", 0, "ts")
			node = bt2
		else:
			var an3 := AnimationNodeAnimation.new()
			an3.animation = st
			node = an3
		sm.add_node(st, node, Vector2(150.0 * (i % 5), 120.0 * (i / 5)))
		i += 1
	for a in GSTATES:
		for b in GSTATES:
			if a != b:
				var tr := AnimationNodeStateMachineTransition.new()
				tr.xfade_time = GXFADE[b]
				tr.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_IMMEDIATE
				sm.add_transition(a, b, tr)
	# جذر: آلة الحالات + لكمة (OneShot مفلترة على الذراع اليمنى)
	var root := AnimationNodeBlendTree.new()
	var punch := AnimationNodeAnimation.new()
	punch.animation = "punch"
	var shot := AnimationNodeOneShot.new()
	shot.fadein_time = 0.04
	shot.fadeout_time = 0.1
	shot.filter_enabled = true
	var arm_tracks := 0
	var anim_ref := gplayer.get_animation("punch")
	for t in range(anim_ref.get_track_count()):
		var p: String = String(anim_ref.track_get_path(t))
		if p.contains("arm.R") or p.contains("forearm.R"):
			shot.set_filter_path(anim_ref.track_get_path(t), true)
			arm_tracks += 1
	root.add_node("sm", sm, Vector2(-500, 0))
	root.add_node("punch", punch, Vector2(-500, 200))
	root.add_node("shot", shot, Vector2(-250, 0))
	root.connect_node("shot", 0, "sm")
	root.connect_node("shot", 1, "punch")
	root.connect_node("output", 0, "shot")
	gtree = AnimationTree.new()
	gtree.name = "RigTree"
	add_child(gtree)
	gtree.anim_player = gtree.get_path_to(gplayer)
	gtree.tree_root = root
	gtree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	gtree.active = true


func _gstate_for_anim() -> String:
	if _land_t > 0.0 and (anim == Anim.RUN or anim == Anim.DASH or anim == Anim.IDLE):
		return "land"
	match anim:
		Anim.RUN: return "run"
		Anim.DASH: return "dash"
		Anim.JUMP: return "jump" if vy > 0.0 else "fall"
		Anim.SLIDE: return "slide"
		Anim.STUMBLE: return "stumble"
		Anim.FALL: return "pit_fall"
		Anim.CHEER: return "victory"
	return "idle"


func start_punch() -> void:
	punch_t = 0.0
	if gtree != null:
		gtree.set("parameters/shot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func _process(delta: float) -> void:
	if body == null or not animated:
		return
	_time += delta
	_lean_s = lerpf(_lean_s, lean, 1.0 - exp(-delta * 7.0))
	if punch_t >= 0.0:
		punch_t += delta
		if punch_t > 0.45:
			punch_t = -1.0
	if gtree != null and gtree.is_inside_tree():
		if _gplayback == null:
			_gplayback = gtree.get("parameters/sm/playback")
			if _gplayback != null:
				_gstate = _gstate_for_anim()
				_gplayback.start(_gstate, true)
		if _gplayback != null:
			var st := _gstate_for_anim()
			if st != _gstate:
				_gstate = st
				_gplayback.travel(st)
			var ts := clampf(maxf(run_speed, 6.0) / REF_SPEED, 0.45, 2.0)
			gtree.set("parameters/sm/run/ts/scale", ts)
			gtree.set("parameters/sm/dash/ts/scale", ts)
			gtree.set("parameters/sm/run/turn/blend_position", clampf(_lean_s * 1.25, -1.0, 1.0))
			gtree.advance(delta)
	_update_body_fx(delta)


## تمدد/انضغاط، ارتداد الاصطدام، ميل الجسم نحو المنعطف (على العقدة الأم للنموذج).
func _update_body_fx(delta: float) -> void:
	_squash = move_toward(_squash, 0.0, delta * (4.5 if _squash > 0.0 else 7.0))
	_land_t = maxf(_land_t - delta, 0.0)
	var q := _squash
	var sy := 1.0 - q * 0.17
	var sxz := 1.0 + q * 0.10
	if anim == Anim.JUMP and vy > 3.0:
		sy += 0.05
		sxz -= 0.03
	body.scale = Vector3(sxz, sy, sxz)
	if _hit_t >= 0.0:
		_hit_t += delta
		var u := _hit_t / 0.55
		if u >= 1.0:
			_hit_t = -1.0
			body.rotation = Vector3.ZERO
			body.position = Vector3.ZERO
		else:
			var env := sin(u * PI)
			body.rotation = Vector3(-env * 0.45 * _hit_power, sin(u * 18.0) * 0.14 * (1.0 - u) * _hit_power, sin(u * 12.0) * 0.12 * (1.0 - u))
			body.position = Vector3(0, env * 0.16 * _hit_power, env * 0.22 * _hit_power)
	else:
		body.rotation = Vector3(0.0, -_lean_s * 0.30, 0.0)
		body.position = Vector3.ZERO


## وضعية ثابتة لأدوات التطوير: يشغّل المقطع عند نسبة u من طوله.
func debug_pose(phase: float) -> void:
	if gtree == null or not gtree.is_inside_tree():
		return
	if phase < 0.0:
		gtree.active = false
		gplayer.stop()
		skeleton.reset_bone_poses()
		return
	var name_ := _gstate_for_anim()
	var clip := {"land": "land", "jump": "jump", "fall": "fall", "pit_fall": "pit_fall"}.get(name_, name_) as String
	gtree.active = false
	gplayer.play(clip)
	gplayer.seek(fposmod(phase / TAU, 1.0) * gplayer.get_animation(clip).length, true)
	gplayer.pause()


func make_ghost(color := Color(0.45, 0.9, 1.0)) -> Node3D:
	var g := Node3D.new()
	var ps: PackedScene = load(GLB_PATH)
	var m: Node3D = ps.instantiate()
	g.add_child(m)
	var gm := Toon.ghost(color)
	for c in m.find_children("*", "", true, false):
		if c is AnimationPlayer:
			c.queue_free()
		elif c is Skeleton3D:
			for b in range(c.get_bone_count()):
				c.set_bone_pose(b, skeleton.get_bone_pose(b))
		elif c is MeshInstance3D:
			c.material_override = gm
			c.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	g.global_transform = global_transform
	return g
