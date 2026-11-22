class_name Race
extends Node3D
## مشهد السباق: يجمع المسار والعدّاء وفوكسي والكاميرا والتأثيرات والواجهة.

signal exit_to_menu
signal restart_requested

enum Phase { LOADING, COUNTDOWN, RACING, FINISHED }

const FOLLOW_DIST := 5.6
const FOLLOW_HEIGHT := 2.75
const LOOK_AHEAD := 7.5
const FIXED_DT := 1.0 / 120.0

var data: TrackData
var runner: Runner
var logic: RaceLogic
var rivals: Array = []          # {foxy, idx, label}
var _final_standings: Array = []
var _final_rank := 1
var foxy: Foxy
var view: TrackView
var hud: Hud
var cam: Camera3D
var sun: DirectionalLight3D
var env: Environment
var phase: int = Phase.LOADING
var paused := false

var _cam_pos := Vector3.ZERO
var _cam_look := Vector3.ZERO
var _cam_fwd := Vector3(0, 0, -1)
var _shake := 0.0
var _acc := 0.0
var _countdown_t := 0.0
var _count_stage := 4
var _finish_t := 0.0
var _frame_times: Array[float] = []
var _perf_window := 0.0
var _perf_sum := 0.0
var _perf_n := 0
var _auto_cooldown := 8.0
var _dust: CPUParticles3D
var _debris: Array = []
var _sparks: Array[CPUParticles3D] = []
var _spark_i := 0
var _ghost_timer := 0.0
var _head_rig: Node3D
var _total_coins := 0
var _sky_node: WorldEnvironment


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_setup_environment()
	hud = Hud.new()
	add_child(hud)
	hud.pause_pressed.connect(_on_pause)
	hud.resume_pressed.connect(_on_resume)
	hud.restart_pressed.connect(func(): restart_requested.emit())
	hud.home_pressed.connect(func(): exit_to_menu.emit())
	hud.show_toast("جارٍ تجهيز المسار...")
	_load()


func _load() -> void:
	data = TrackData.new()
	_total_coins = data.coins.size()
	runner = Runner.new(data)
	logic = RaceLogic.new(runner, 3, randi())
	_connect_runner()
	logic.racer_hit.connect(_on_racer_hit)
	view = TrackView.new()
	add_child(view)
	var prof := Settings.profile()
	await view.build(data, float(prof.density), func(_p: float): await get_tree().process_frame)
	_build_player()
	_build_rivals()
	_build_fx()
	hud.controls.input = runner.input
	hud.controls.sensitivity = Settings.steer_sensitivity
	hud.set_coins(0)
	_reset_camera()
	view.update_visibility(runner.s, float(prof.view))
	phase = Phase.COUNTDOWN
	_countdown_t = 0.0
	_count_stage = 4
	Perf_reset()


func Perf_reset() -> void:
	_frame_times.clear()
	_perf_window = 0.0


# ------------------------------------------------------------------ بيئة
func _setup_environment() -> void:
	var prof := Settings.profile()
	var sky := Sky.new()
	var pm := ProceduralSkyMaterial.new()
	pm.sky_top_color = Color("3f86e8")
	pm.sky_horizon_color = Color("bfe0ff")
	pm.ground_horizon_color = Color("bfe0ff")
	pm.ground_bottom_color = Color("8fc6e8")
	pm.sun_angle_max = 25.0
	pm.sun_curve = 0.15
	sky.sky_material = pm
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("c4b4f0")
	env.ambient_light_energy = 0.34
	env.fog_enabled = bool(prof.fog)
	env.fog_light_color = Color("c4e0ff")
	env.fog_density = 0.0042
	env.fog_sky_affect = 0.35
	_sky_node = WorldEnvironment.new()
	_sky_node.environment = env
	add_child(_sky_node)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, 32, 0)
	sun.light_energy = 0.82
	sun.light_color = Color("fff0d6")
	sun.shadow_enabled = bool(prof.shadows)
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 55.0
	sun.shadow_bias = 0.06
	sun.shadow_normal_bias = 1.2
	add_child(sun)
	cam = Camera3D.new()
	cam.fov = 56.0
	cam.near = 0.2
	cam.far = float(prof.view) + 380.0
	add_child(cam)
	cam.make_current()
	Settings.apply_to_viewport(get_viewport(), sun)


func _build_player() -> void:
	foxy = Foxy.new()
	foxy.build(true)
	add_child(foxy)
	_sync_foxy(0.0)


func _build_rivals() -> void:
	var prof := Settings.profile()
	var k := 0
	var font := UiKit.font()
	for i in range(RaceLogic.RACERS):
		if i == logic.player:
			continue
		var f := Foxy.new()
		f.build(bool(prof.outline))
		f.set_hue(float(RaceLogic.HUES[k]))
		add_child(f)
		var lb := Label3D.new()
		lb.text = RaceLogic.NAMES[k]
		lb.font = font
		lb.font_size = 56
		lb.pixel_size = 0.0042
		lb.outline_size = 14
		lb.outline_modulate = Color("1a1040")
		lb.modulate = Color.from_hsv(fposmod(0.08 + float(RaceLogic.HUES[k]) / TAU, 1.0), 0.55, 1.0)
		lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lb.no_depth_test = true
		lb.fixed_size = false
		lb.position = Vector3(0, 2.45, 0)
		f.add_child(lb)
		var rr := logic.runners[i]
		rr.punch_started.connect(func(): f.start_punch())
		rivals.append({"foxy": f, "idx": i, "label": lb, "color": lb.modulate})
		k += 1


func _build_fx() -> void:
	_dust = CPUParticles3D.new()
	_dust.amount = 18
	_dust.lifetime = 0.55
	_dust.local_coords = false
	_dust.emitting = false
	_dust.direction = Vector3(0, 1, 1)
	_dust.spread = 38.0
	_dust.initial_velocity_min = 0.8
	_dust.initial_velocity_max = 2.2
	_dust.gravity = Vector3(0, 1.0, 0)
	_dust.scale_amount_min = 0.5
	_dust.scale_amount_max = 1.2
	var sm := SphereMesh.new()
	sm.radius = 0.16
	sm.height = 0.32
	sm.radial_segments = 6
	sm.rings = 3
	var dm := StandardMaterial3D.new()
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.vertex_color_use_as_albedo = true
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.material = dm
	_dust.mesh = sm
	var g := Gradient.new()
	g.set_color(0, Color(1, 0.95, 0.85, 0.7))
	g.set_color(1, Color(1, 0.95, 0.85, 0.0))
	_dust.color_ramp = g
	add_child(_dust)
	for i in range(6):
		var p := CPUParticles3D.new()
		p.amount = 10
		p.lifetime = 0.5
		p.one_shot = true
		p.explosiveness = 1.0
		p.emitting = false
		p.local_coords = false
		p.direction = Vector3(0, 1, 0)
		p.spread = 180.0
		p.initial_velocity_min = 2.0
		p.initial_velocity_max = 4.5
		p.gravity = Vector3(0, -6, 0)
		var q := SphereMesh.new()
		q.radius = 0.09
		q.height = 0.18
		q.radial_segments = 5
		q.rings = 3
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color("ffe14a")
		q.material = m
		p.mesh = q
		add_child(p)
		_sparks.append(p)
	# حطام الصناديق
	var chunk_mb := MeshBuilder.new()
	chunk_mb.add_rbox(Vector3(0.3, 0.12, 0.3), 0.04, Color("d49a5a"), Transform3D.IDENTITY, 2)
	var chunk_mesh := chunk_mb.build()
	for i in range(28):
		var mi := MeshInstance3D.new()
		mi.mesh = chunk_mesh
		mi.material_override = Toon.solid(false)
		mi.visible = false
		add_child(mi)
		_debris.append({"node": mi, "v": Vector3.ZERO, "w": Vector3.ZERO, "t": 0.0})


func _connect_runner() -> void:
	runner.jumped.connect(func(): _buzz(18))
	runner.landed.connect(func(hard: bool):
		if hard:
			_shake = maxf(_shake, 0.12)
		_puff())
	runner.stumbled.connect(func(kind: String):
		_shake = 0.35
		_buzz(60)
		hud.show_banner("أُصبتَ بضربة!" if kind == "hit" else "أوه! اصطدام", Color("ff9a8a")))
	runner.punch_started.connect(func():
		if foxy:
			foxy.start_punch())
	runner.punch_hit.connect(_on_punch_hit)
	runner.coin_collected.connect(func(i: int):
		view.hide_coin(i)
		hud.set_coins(runner.coins_got)
		_spark(data.world(data.coins[i].x, data.coins[i].y, data.coins[i].z)))
	runner.boosted.connect(func(): hud.show_banner("تسارع!", Color("ffe45a")))
	runner.fell.connect(func(): hud.show_banner("سقطت!", Color("ff9a8a")))
	runner.finished.connect(_on_finished)
	runner.dashed.connect(func(): _ghost_timer = 0.0)


func _buzz(ms: int) -> void:
	if Settings.vibration and OS.has_feature("mobile"):
		Input.vibrate_handheld(ms)


func _puff() -> void:
	if _dust:
		_dust.restart()


func _spark(pos: Vector3) -> void:
	var p := _sparks[_spark_i % _sparks.size()]
	_spark_i += 1
	p.global_position = pos
	p.restart()
	p.emitting = true


func _on_punch_hit(o: Dictionary) -> void:
	var positions := view.break_crate(o)
	for pos in positions:
		_spawn_debris(pos)
		_spark(pos)
	_shake = maxf(_shake, 0.2)
	_buzz(35)


func _spawn_debris(pos: Vector3) -> void:
	var made := 0
	for d in _debris:
		if d.t > 0.0:
			continue
		var n: MeshInstance3D = d.node
		n.visible = true
		n.global_position = pos + Vector3(randf_range(-0.3, 0.3), randf_range(-0.2, 0.3), randf_range(-0.3, 0.3))
		n.scale = Vector3.ONE
		d.v = Vector3(randf_range(-3.0, 3.0), randf_range(2.5, 5.5), randf_range(-4.0, 1.0))
		d.w = Vector3(randf_range(-9, 9), randf_range(-9, 9), randf_range(-9, 9))
		d.t = 1.1
		made += 1
		if made >= 9:
			break


func _on_racer_hit(victim: int, attacker: int) -> void:
	var vr := logic.runners[victim]
	var pos := data.world(vr.s, vr.x, vr.y + 1.0)
	_spark(pos)
	if attacker == logic.player:
		hud.show_banner("ضربة موفّقة!", Color("ffe45a"))
		_shake = maxf(_shake, 0.18)
		_buzz(30)
	elif victim == logic.player:
		_buzz(60)


func _on_finished(t: float) -> void:
	phase = Phase.FINISHED
	_finish_t = 0.0
	_final_standings = logic.standings()
	_final_rank = _final_standings.find(logic.player) + 1
	hud.show_banner("خط النهاية!", Color("ffe45a"))
	hud.controls.enabled = false
	runner.input.steer = 0.0
	Settings.total_coins += runner.coins_got
	var new_best := Settings.best_time <= 0.0 or t < Settings.best_time
	if new_best:
		Settings.best_time = t
	Settings.save_settings()
	set_meta("new_best", new_best)


# ------------------------------------------------------------------ دورة اللعب
func _physics_process(_delta: float) -> void:
	pass


func _process(delta: float) -> void:
	if phase == Phase.LOADING or runner == null or foxy == null:
		return
	delta = minf(delta, 0.05)
	_track_perf(delta)
	match phase:
		Phase.COUNTDOWN:
			_update_countdown(delta)
		Phase.RACING:
			_run_sim(delta)
		Phase.FINISHED:
			_run_sim(delta)
			_finish_t += delta
			if _finish_t > 1.6 and hud.overlay == null:
				_show_result()
	_sync_foxy(delta)
	_update_camera(delta)
	_update_fx(delta)
	view.update_visibility(runner.s, float(Settings.profile().view))
	view.update_hammers(runner.time if phase != Phase.COUNTDOWN else 0.0)
	_update_hud()


func _run_sim(delta: float) -> void:
	_acc += delta
	var n := 0
	while _acc >= FIXED_DT and n < 12:
		logic.step(FIXED_DT)
		_acc -= FIXED_DT
		n += 1
	var cd_total := Runner.RIVAL_COOLDOWN if runner.t_punch_cd > Runner.PUNCH_COOLDOWN + 0.01 else Runner.PUNCH_COOLDOWN
	hud.controls.punch_cd = clampf(runner.t_punch_cd / cd_total, 0.0, 1.0)
	hud.controls.special_cd = runner.t_dash_cd / Runner.DASH_COOLDOWN


func _update_countdown(delta: float) -> void:
	_countdown_t += delta
	var stage := 3 - int(_countdown_t / 0.9)
	if stage != _count_stage:
		_count_stage = stage
		if stage >= 1:
			hud.show_countdown(str(stage))
		elif stage == 0:
			hud.show_countdown("انطلق!", Color("7dffb0"))
			phase = Phase.RACING
			logic.start()
			hud.controls.enabled = true


func _show_result() -> void:
	var r := {
		"time": runner.finish_time,
		"coins": runner.coins_got,
		"coins_total": _total_coins,
		"best": Settings.best_time,
		"new_best": get_meta("new_best", false),
		"stumbles": runner.stumbles,
		"falls": runner.falls,
		"crates": runner.crates_broken,
		"rank": _final_rank,
		"total": RaceLogic.RACERS,
		"rival_hits": runner.rival_hits,
		"times_hit": runner.times_hit,
		"standings": _standings_rows(),
	}
	r.merge(_perf_summary())
	hud.show_result(r)
	_buzz(25)


func _standings_rows() -> Array:
	var rows := []
	var k := 0
	var names := {}
	for i in range(RaceLogic.RACERS):
		if i == logic.player:
			names[i] = "أنت (فوكسي)"
		else:
			names[i] = RaceLogic.NAMES[k]
			k += 1
	for i in _final_standings:
		var r := logic.runners[i]
		var done: bool = r.state == Runner.State.FINISHED and (i == logic.player or r.finish_time <= runner.finish_time)
		var tt := Hud._fmt(r.finish_time) if done else "لم ينهِ"
		rows.append({"name": names[i], "player": i == logic.player, "time_text": tt})
	return rows


func _perf_summary() -> Dictionary:
	var avg := 60.0
	var p95 := 16.7
	if _frame_times.size() > 10:
		var sorted := _frame_times.duplicate()
		sorted.sort()
		var total := 0.0
		for f in _frame_times:
			total += f
		avg = float(_frame_times.size()) / total
		p95 = sorted[int(float(sorted.size()) * 0.95)] * 1000.0
	return {"avg_fps": avg, "p95_ms": p95, "quality": Settings.quality_name()}


func _track_perf(delta: float) -> void:
	if phase != Phase.RACING:
		return
	_frame_times.append(delta)
	if _frame_times.size() > 6000:
		_frame_times.pop_front()
	_perf_window += delta
	_perf_sum += delta
	_perf_n += 1
	_auto_cooldown -= delta
	if _perf_window >= 3.0:
		var fps := float(_perf_n) / _perf_sum
		if Settings.auto_quality and _auto_cooldown <= 0.0 and fps < 44.0 and Settings.quality > Settings.Quality.LOW:
			Settings.set_quality(Settings.quality - 1)
			Settings.apply_to_viewport(get_viewport(), sun)
			hud.show_toast("تم تخفيف الرسومات تلقائيًا إلى: %s (%.0f إطار/ث)" % [Settings.quality_name(), fps])
			_auto_cooldown = 6.0
		_perf_window = 0.0
		_perf_sum = 0.0
		_perf_n = 0
	if Settings.show_fps:
		var info := "FPS %d   %.1f ms\nمكالمات الرسم %d   مثلثات %dk\nالذاكرة %.0f MB   الجودة %s  دقة %.0f%%" % [
			Engine.get_frames_per_second(), delta * 1000.0,
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
			int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME) / 1000.0),
			float(Performance.get_monitor(Performance.MEMORY_STATIC)) / 1048576.0,
			Settings.quality_name(), float(Settings.profile().scale) * 100.0]
		hud.fps_label.text = info


func _update_hud() -> void:
	if phase != Phase.FINISHED:
		hud.set_rank(logic.rank_of(logic.player), RaceLogic.RACERS)
	else:
		hud.set_rank(_final_rank, RaceLogic.RACERS)
	var vals := []
	var cols := []
	for rv in rivals:
		var rr := logic.runners[rv.idx]
		vals.append((rr.s - TrackData.START_S) / (TrackData.FINISH_S - TrackData.START_S))
		cols.append(rv.color)
	hud.set_rivals(vals, cols)
	hud.set_time(runner.time if phase != Phase.FINISHED else runner.finish_time)
	hud.progress_view.value = clampf((runner.s - TrackData.START_S) / (TrackData.FINISH_S - TrackData.START_S), 0.0, 1.0)
	hud.progress_view.queue_redraw()


# ------------------------------------------------------------------ مزامنة فوكسي
func _sync_foxy(delta: float) -> void:
	_pose_foxy(foxy, runner)
	if runner.t_dash > 0.0:
		_ghost_timer -= delta
		if _ghost_timer <= 0.0:
			_ghost_timer = 0.11
			_spawn_ghost()
	for rv in rivals:
		var rr := logic.runners[rv.idx]
		var f: Foxy = rv.foxy
		var near := absf(rr.s - runner.s) < 75.0
		f.set_process(near)
		if not near:
			f.visible = false
		if near:
			_pose_foxy(f, rr)
			var d := f.global_position.distance_to(cam.global_position)
			# لا نرسم من يمر قرب الكاميرا مباشرة حتى لا يحجب الرؤية
			f.visible = d > 3.4
			rv.label.visible = d > 7.0 and d < 38.0


func _pose_foxy(f: Foxy, r: Runner) -> void:
	var fr := data.frame(r.s)
	var origin := data.center(r.s) + data.right(r.s) * r.x + Vector3.UP * r.y
	f.global_transform = Transform3D(fr.basis, origin)
	f.run_speed = r.speed
	f.lean = clampf(r.lat_v / Runner.MAX_LAT, -1.0, 1.0)
	f.vy = r.vy
	f.set_flash(r.is_invulnerable() and r.state != Runner.State.FALLING)
	match r.state:
		Runner.State.WAIT:
			f.anim = Foxy.Anim.IDLE
		Runner.State.RUN:
			f.anim = Foxy.Anim.DASH if r.t_dash > 0.0 else Foxy.Anim.RUN
		Runner.State.AIR:
			f.anim = Foxy.Anim.JUMP
		Runner.State.SLIDE:
			f.anim = Foxy.Anim.SLIDE
		Runner.State.STUMBLE:
			f.anim = Foxy.Anim.STUMBLE
		Runner.State.FALLING:
			f.anim = Foxy.Anim.FALL
		Runner.State.FINISHED:
			f.anim = Foxy.Anim.CHEER


func _spawn_ghost() -> void:
	var g := foxy.make_ghost()
	add_child(g)
	var tw := create_tween()
	tw.tween_method(func(a: float):
		for c in g.get_children():
			var m: StandardMaterial3D = (c as MeshInstance3D).material_override
			m.albedo_color.a = a, 0.5, 0.0, 0.8)
	tw.tween_callback(g.queue_free)


# ------------------------------------------------------------------ الكاميرا
func _reset_camera() -> void:
	var f := data.frame(runner.s)
	var base := data.world(runner.s, runner.x * 0.7, 0.0)
	var fw := data.forward(runner.s)
	_cam_fwd = fw
	_cam_pos = base - fw * FOLLOW_DIST + Vector3.UP * FOLLOW_HEIGHT
	_cam_look = base + fw * LOOK_AHEAD + Vector3.UP * 0.8
	cam.global_position = _cam_pos
	cam.look_at(_cam_look, Vector3.UP)


func _update_camera(delta: float) -> void:
	var s_use := runner.s
	var fw := data.forward(s_use)
	_cam_fwd = _cam_fwd.lerp(fw, 1.0 - exp(-delta * 6.0)).normalized()
	var y_follow := runner.y * 0.55
	if runner.state == Runner.State.FALLING:
		y_follow = maxf(runner.y, -1.0) * 0.2
	var base := data.world(s_use, runner.x * 0.72, y_follow)
	var extra_h := 0.0
	var extra_d := 0.0
	if phase == Phase.FINISHED:
		extra_d = -minf(_finish_t * 2.2, 3.4)
		extra_h = minf(_finish_t * 0.5, 0.9)
	var want_pos := base - _cam_fwd * (FOLLOW_DIST + extra_d) + Vector3.UP * (FOLLOW_HEIGHT + extra_h + (0.3 if runner.state == Runner.State.SLIDE else 0.0))
	var want_look := base + _cam_fwd * LOOK_AHEAD + Vector3.UP * (0.75 + runner.y * 0.25)
	_cam_pos = _cam_pos.lerp(want_pos, 1.0 - exp(-delta * 9.0))
	_cam_look = _cam_look.lerp(want_look, 1.0 - exp(-delta * 11.0))
	var shake_off := Vector3.ZERO
	if _shake > 0.0:
		_shake = maxf(_shake - delta * 1.2, 0.0)
		shake_off = Vector3(randf_range(-1, 1), randf_range(-1, 1), 0.0) * _shake * 0.35
	cam.global_position = _cam_pos + shake_off
	cam.look_at(_cam_look, Vector3.UP)
	cam.rotate_object_local(Vector3(0, 0, 1), -runner.lat_v / Runner.MAX_LAT * 0.035)
	var boost := 0.0
	if runner.t_dash > 0.0:
		boost = 9.0
	elif runner.t_boost > 0.0:
		boost = 5.0
	cam.fov = lerpf(cam.fov, 56.0 + boost + clampf(runner.speed - 13.0, 0.0, 8.0) * 0.4, 1.0 - exp(-delta * 5.0))
	# الشمس تتبع اللاعب كي تبقى الظلال حادة
	sun.global_position = foxy.global_position + Vector3(0, 30, 0)


func _update_fx(delta: float) -> void:
	_dust.global_position = foxy.global_position + Vector3(0, 0.1, 0)
	_dust.emitting = runner.state == Runner.State.RUN or runner.state == Runner.State.SLIDE
	_dust.amount = 26 if runner.state == Runner.State.SLIDE else 14
	for d in _debris:
		if d.t <= 0.0:
			continue
		d.t -= delta
		var n: MeshInstance3D = d.node
		d.v.y -= 14.0 * delta
		n.global_position += d.v * delta
		n.rotation += d.w * delta
		n.scale = Vector3.ONE * clampf(d.t * 1.5, 0.0, 1.0)
		if d.t <= 0.0:
			n.visible = false


# ------------------------------------------------------------------ إيقاف مؤقت
func _on_pause() -> void:
	if phase == Phase.LOADING or paused:
		return
	paused = true
	get_tree().paused = true
	hud.show_pause()


func _on_resume() -> void:
	paused = false
	get_tree().paused = false
	hud.hide_overlay()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		if phase == Phase.RACING and not paused:
			_on_pause()


func _exit_tree() -> void:
	get_tree().paused = false
