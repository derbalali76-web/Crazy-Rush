extends Node3D
## أداة تطوير: تلتقط صورًا حقيقية من المشاهد (تُشغَّل بـ xvfb). لا تدخل في اللعبة الفعلية.
## الاستخدام: godot --path . res://scenes/DevShot.tscn -- --mode=fox --anim=run --out=/tmp/a.png

var args := {}


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			var kv := a.substr(2).split("=", true, 1)
			args[kv[0]] = kv[1]
	Toon.premium_enabled = args.get("premium", "0") == "1"
	Toon.use_normal_maps = args.get("nrm", "1") == "1"
	TrackData.layout = int(args.get("layout", "0"))
	var mode: String = args.get("mode", "fox")
	var out: String = args.get("out", "/tmp/shot.png")
	var frames := int(args.get("frames", "20"))
	match mode:
		"fox":
			await _scene_fox()
		"sheet":
			await _scene_fox()
		"menu":
			add_child(Menu.new())
		"store":
			add_child(StoreScreen.new())
		"race":
			await _scene_race()
		"touch":
			await _touch_test()
		"measure":
			await _measure()
		"props":
			await _scene_props()
		"trees":
			await _scene_trees()
		"settings":
			add_child(SettingsPanel.new())
		"pause":
			var pr := Race.new()
			add_child(pr)
			while pr.phase == Race.Phase.LOADING:
				await get_tree().process_frame
			pr.hud.show_pause()
	for i in range(frames):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(out)
	print("saved ", out, " size=", img.get_size())
	get_tree().quit()


func _env(sky_top := Color("4a90e8"), sky_hor := Color("cfe6ff")) -> void:
	var sky := Sky.new()
	var pm := ProceduralSkyMaterial.new()
	pm.sky_top_color = sky_top
	pm.sky_horizon_color = sky_hor
	pm.ground_horizon_color = sky_hor
	pm.ground_bottom_color = Color("9fb6d8")
	sky.sky_material = pm
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("b8a8e8")
	e.ambient_light_energy = 0.30
	var we := WorldEnvironment.new()
	we.environment = e
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -35, 0)
	sun.light_energy = 0.8
	sun.light_color = Color("fff2dc")
	sun.shadow_enabled = true
	add_child(sun)


func _scene_fox() -> void:
	_env()
	Foxy.use_rig = args.get("classic", "0") != "1"
	if args.has("glb"):
		FoxyGLB.GLB_PATH = args["glb"]
	var fox := Foxy.create(true)
	add_child(fox)
	await get_tree().process_frame
	if args.has("clip") and fox is FoxyGLB:
		fox.gtree.active = false
		fox.gplayer.play(args["clip"])
		fox.gplayer.seek(float(args.get("t", "0.2")), true)
		fox.gplayer.pause()
	if args.get("plain", "0") == "1":
		var pm := StandardMaterial3D.new()
		pm.vertex_color_use_as_albedo = true
		pm.cull_mode = BaseMaterial3D.CULL_BACK
		for mi in fox._meshes:
			mi.material_override = pm
	var a: String = args.get("anim", "idle")
	match a:
		"run": fox.anim = Foxy.Anim.RUN; fox.run_speed = 13.0
		"jump": fox.anim = Foxy.Anim.JUMP; fox.vy = 5.0
		"fall": fox.anim = Foxy.Anim.JUMP; fox.vy = -5.0
		"slide": fox.anim = Foxy.Anim.SLIDE
		"stumble": fox.anim = Foxy.Anim.STUMBLE
		"cheer": fox.anim = Foxy.Anim.CHEER
		"dash": fox.anim = Foxy.Anim.DASH; fox.run_speed = 16.0
		_: fox.anim = Foxy.Anim.IDLE
	if a == "punch":
		fox.anim = Foxy.Anim.RUN
		fox.run_speed = 13.0
	fox.debug_pose(float(args.get("phase", "0.0")))
	if a == "punch":
		fox.punch_t = float(args.get("pt", "0.16"))
		fox._apply_pose()
	var cam := Camera3D.new()
	var view: String = args.get("view", "front")
	var yaw := 0.0
	match view:
		"back": yaw = 180.0
		"side": yaw = 90.0
		"q": yaw = 28.0
		"qback": yaw = 155.0
	var dist := float(args.get("dist", "4.2"))
	var h := float(args.get("h", "1.15"))
	cam.fov = float(args.get("fov", "40"))
	add_child(cam)
	var yr := deg_to_rad(yaw)
	cam.position = Vector3(sin(yr) * dist, h + 0.25, -cos(yr) * dist)
	cam.look_at(Vector3(0, h, 0), Vector3.UP)
	# أرضية
	var floor_mesh := MeshBuilder.new()
	floor_mesh.add_cylinder(3.0, 3.0, 0.1, Color("8e6bd8"), Transform3D(Basis(), Vector3(0, -0.1, 0)), 40)
	Toon.mesh_instance(floor_mesh.build(), Toon.solid(), self)


## يشغّل السباق فعليًا: يبدأ مباشرة ويقفز الزمن إلى موضع s المطلوب بمحاكاة حقيقية.
func _scene_race() -> void:
	var r := Race.new()
	add_child(r)
	while r.phase == Race.Phase.LOADING:
		await get_tree().process_frame
	r._countdown_t = 99.0
	r.phase = Race.Phase.RACING
	r.logic.start()
	r.hud.controls.enabled = true
	var target_s := float(args.get("s", "30"))
	var act: String = args.get("act", "")
	var guard := 0
	var pai := RacerAI.new(1.0, float(args.get("aggr", "0.0")), 11)
	if args.has("route"):
		var rt: String = args.get("route", "HH")
		pai._routes = {"A": rt[0] == "H", "B": rt[1] == "H"}
	while r.runner.s < target_s and guard < 60000:
		pai.update(1.0 / 120.0, r.runner, r.logic.runners)
		r.logic.step(1.0 / 120.0)
		guard += 1
	r.autopilot = pai
	match act:
		"jump": r.runner.input.jump = true
		"slide": r.runner.input.slide = true
		"punch": r.runner.input.punch = true
	r.runner.input.steer = float(args.get("steer", "0"))
	if args.get("nofar","0") == "1":
		r.view.far_nodes.visible = false
	if args.get("nomtn","0") == "1":
		for n2 in r.view.far_nodes.get_children():
			if (n2 as MeshInstance3D).get_aabb().size.x > 100.0:
				n2.visible = false
	if args.get("dbg","0") == "1":
		for n in r.view.find_children("*", "MeshInstance3D", true, false):
			var mi := n as MeshInstance3D
			if mi.mesh != null and mi.get_aabb().size.x > 30.0 and mi.get_parent().name == "Far":
				print("BIG ", mi.name, " parent=", mi.get_parent().name, " size=", mi.get_aabb().size, " pos=", mi.global_position, " mat=", mi.material_override)
	if args.has("cs"):
		var cs := float(args.get("cs", "0"))
		r.set_process(false)
		var cc2: Vector3 = r.view.data.center(cs)
		var fw: Vector3 = r.view.data.forward(cs)
		var rt2: Vector3 = r.view.data.right(cs)
		r.cam.global_position = cc2 + rt2 * float(args.get("cx", "0")) + Vector3(0, float(args.get("cy", "5")), 0) - fw * float(args.get("cz", "20"))
		r.cam.look_at(cc2 + Vector3(0, float(args.get("cly", "4")), 0), Vector3.UP)
		r.cam.fov = float(args.get("cfov", "60"))
		await get_tree().process_frame
	if args.has("wf"):
		var best: MeshInstance3D = null
		var bd := 1e9
		var cc: Vector3 = r.view.data.center(float(args.get("wf", "0")))
		for n3 in r.view.far_nodes.get_children():
			var m3 := n3 as MeshInstance3D
			if m3 and m3.material_override is ShaderMaterial and (m3.material_override as ShaderMaterial).shader.resource_path.contains("waterfall"):
				var dd := m3.global_position.distance_to(cc)
				if dd < bd:
					bd = dd
					best = m3
		r.set_process(false)
		var tgt := best.global_position
		var dir := (cc - tgt)
		dir.y = 0
		dir = dir.normalized()
		r.cam.global_position = tgt + dir * float(args.get("wfd", "40")) + Vector3(0, float(args.get("wfh", "8")), 0)
		r.cam.look_at(tgt + Vector3(0, 4, 0), Vector3.UP)
		r.cam.fov = 60.0
		print("WF dist=", bd)
		await get_tree().process_frame
	print("race s=", r.runner.s, " state=", r.runner.state, " coins=", r.runner.coins_got)


func _touch_test() -> void:
	var r := Race.new()
	add_child(r)
	while r.phase == Race.Phase.LOADING:
		await get_tree().process_frame
	r._countdown_t = 99.0
	r.phase = Race.Phase.RACING
	r.runner.start_race()
	r.hud.controls.enabled = true
	await get_tree().process_frame
	print("controls size=", r.hud.controls.size, " input_set=", r.hud.controls.input != null)
	var t := InputEventScreenTouch.new()
	t.index = 0
	t.position = Vector2(700, 300)
	t.pressed = true
	Input.parse_input_event(t)
	await get_tree().process_frame
	var d := InputEventScreenDrag.new()
	d.index = 0
	d.position = Vector2(760, 300)
	Input.parse_input_event(d)
	await get_tree().process_frame
	print("steer after drag right=", r.runner.input.steer)
	for i in range(30):
		await get_tree().process_frame
	print("x=", r.runner.x, " steer=", r.runner.input.steer)
	var d2 := InputEventScreenDrag.new()
	d2.index = 0
	d2.position = Vector2(760, 230)
	Input.parse_input_event(d2)
	var peak := 0.0
	for i in range(40):
		await get_tree().process_frame
		peak = maxf(peak, r.runner.y)
	print("swipe up -> peak y=", peak)
	var up := InputEventScreenTouch.new()
	up.index = 0
	up.position = Vector2(760, 230)
	up.pressed = false
	Input.parse_input_event(up)
	await get_tree().process_frame
	print("steer after release=", r.runner.input.steer)
	var pb := InputEventScreenTouch.new()
	pb.index = 1
	pb.position = Vector2(1280 - 120, 720 - 120)
	pb.pressed = true
	Input.parse_input_event(pb)
	print("punch flag=", r.runner.input.punch, " state=", r.runner.state)
	for i in range(3):
		await get_tree().process_frame
	print("punch cd=", r.runner.t_punch_cd, " flag=", r.runner.input.punch)


## قياس كلفة المشهد (مضلعات/نداءات رسم) على البرمجيات؛ لا يمثل FPS الهاتف. الاستخدام: --mode=measure --q=0|1|2
func _measure() -> void:
	Settings.quality = int(args.get("q", "1"))
	var r := Race.new()
	add_child(r)
	while r.phase == Race.Phase.LOADING:
		await get_tree().process_frame
	r._countdown_t = 99.0
	r.phase = Race.Phase.RACING
	r.logic.start()
	var pai := RacerAI.new(1.0, 0.0, 11)
	for s_target in [float(args.get("m1", "20")), float(args.get("m2", "120")), float(args.get("m3", "260"))]:
		var guard := 0
		while r.runner.s < s_target and guard < 60000:
			pai.update(1.0 / 120.0, r.runner, r.logic.runners)
			r.logic.step(1.0 / 120.0)
			guard += 1
		r.autopilot = pai
		for i in 6:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		if args.get("brk", "0") == "1":
			var cam_p: Vector3 = r.cam.global_position
			var agg := {}
			for n in r.view.find_children("*", "MultiMeshInstance3D", true, false):
				var mmi := n as MultiMeshInstance3D
				var mm := mmi.multimesh
				if mm == null or mm.mesh == null or not mmi.is_visible_in_tree():
					continue
				var tri := 0
				for si in range(mm.mesh.get_surface_count()):
					var arr := mm.mesh.surface_get_arrays(si)
					var idx = arr[Mesh.ARRAY_INDEX]
					tri += (idx.size() / 3) if idx != null else (arr[Mesh.ARRAY_VERTEX].size() / 3)
				var vis := 0
				for i in range(mm.instance_count):
					var d := mm.get_instance_transform(i).origin.distance_to(cam_p)
					if d >= mmi.visibility_range_begin and (mmi.visibility_range_end <= 0.0 or d < mmi.visibility_range_end) and d < 160.0:
						vis += 1
				var key := "%s tri=%d" % [mm.mesh.resource_path.get_file() if mm.mesh.resource_path != "" else mm.mesh.get_class(), tri]
				agg[key] = agg.get(key, 0) + vis * tri
			var ks := agg.keys()
			ks.sort_custom(func(a, b): return agg[a] > agg[b])
			for k in ks.slice(0, 12):
				print("  BRK ", k, " => ", agg[k])
		print("MEASURE q=%d s=%.0f prims=%d draws=%d objs=%d" % [Settings.quality, r.runner.s,
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)])


## عرض مقرّب لمجسمات الديكور المبنية (للتحقق البصري): صخور بـ LOD0/1/2 وسراخس ونباتات.
func _scene_props() -> void:
	_env()
	var cam := Camera3D.new()
	add_child(cam)
	cam.position = Vector3(0.0, 1.6, 5.2)
	cam.look_at(Vector3(0.0, 0.6, 0.0))
	cam.current = true
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(30, 14)
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color("5a7a45")
	var fl := MeshInstance3D.new()
	fl.mesh = floor_mesh
	fl.material_override = fm
	add_child(fl)
	var xs := -4.2
	for lod in range(3):
		var m := PropLib.mesh("rock%d" % (lod + 1), lod)
		var mi := MeshInstance3D.new()
		mi.mesh = m
		mi.material_override = PropLib.material("rock", true)
		mi.position = Vector3(xs + lod * 1.4, 0.0, 0.0)
		mi.scale = Vector3.ONE * 0.8
		add_child(mi)
	var k := 0
	for kind in ["fern", "anthurium", "calathea"]:
		for lod in range(3):
			var m2 := PropLib.mesh(kind, lod)
			var mi2 := MeshInstance3D.new()
			mi2.mesh = m2
			mi2.material_override = PropLib.material(kind, true)
			mi2.position = Vector3(-0.2 + lod * 1.0 + k * 3.2 - 1.0, 0.0, 1.6)
			mi2.scale = Vector3.ONE * 1.4
			add_child(mi2)
		k += 1


func _scene_trees() -> void:
	_env()
	var cam := Camera3D.new()
	add_child(cam)
	cam.position = Vector3(0.0, 3.0, 12.0)
	cam.look_at(Vector3(0.0, 1.5, 0.0))
	cam.current = true
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(60, 30)
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color("5a7a45")
	var fl := MeshInstance3D.new()
	fl.mesh = floor_mesh
	fl.material_override = fm
	add_child(fl)
	var i := 0
	for kind in PropLib.TREE_PROPS:
		var mi := MeshInstance3D.new()
		mi.mesh = PropLib.mesh(kind, 0)
		mi.material_override = PropLib.material(kind, true)
		mi.position = Vector3(-10.0 + float(i) * 2.9, 0.0, 0.0)
		add_child(mi)
		print("TREE ", kind, " aabb=", mi.get_aabb().size)
		i += 1
	for k in range(2):
		var tn := "tree_%s" % ["a", "b"][k]
		var ti := MeshInstance3D.new()
		ti.mesh = PropLib.mesh(tn, 0)
		PropLib.apply_tree_materials(ti, true)
		ti.position = Vector3(-4.0 + k * 7.0, 0.0, -4.0)
		add_child(ti)
