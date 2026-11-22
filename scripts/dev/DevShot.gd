extends Node3D
## أداة تطوير: تلتقط صورًا حقيقية من المشاهد (تُشغَّل بـ xvfb). لا تدخل في اللعبة الفعلية.
## الاستخدام: godot --path . res://scenes/DevShot.tscn -- --mode=fox --anim=run --out=/tmp/a.png

var args := {}


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			var kv := a.substr(2).split("=", true, 1)
			args[kv[0]] = kv[1]
	var mode: String = args.get("mode", "fox")
	var out: String = args.get("out", "/tmp/shot.png")
	var frames := int(args.get("frames", "20"))
	match mode:
		"fox":
			_scene_fox()
		"sheet":
			_scene_fox()
		"menu":
			add_child(Menu.new())
		"race":
			await _scene_race()
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
	var fox := Foxy.new()
	fox.build(true)
	add_child(fox)
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
	fox._phase = float(args.get("phase", "0.0"))
	fox._compute_target(0.0)
	fox._apply_pose_instant()
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
	r.runner.start_race()
	r.hud.controls.enabled = true
	var target_s := float(args.get("s", "30"))
	var act: String = args.get("act", "")
	var guard := 0
	while r.runner.s < target_s and guard < 20000:
		r.runner.step(1.0 / 120.0)
		guard += 1
	match act:
		"jump": r.runner.input.jump = true
		"slide": r.runner.input.slide = true
		"punch": r.runner.input.punch = true
	r.runner.input.steer = float(args.get("steer", "0"))
	print("race s=", r.runner.s, " state=", r.runner.state, " coins=", r.runner.coins_got)
