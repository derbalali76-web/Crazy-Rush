extends SceneTree
## اختبارات بلا رسوميات: godot --headless -s tests/run_tests.gd

var fails := 0


func check(cond: bool, msg: String) -> void:
	if cond:
		print("PASS  ", msg)
	else:
		print("FAIL  ", msg)
		fails += 1


func _init() -> void:
	test_meshes()
	test_run_forward()
	test_jump()
	test_slide()
	test_full_race_survives()
	test_track_consistency()
	test_race8()
	test_direct_strike()
	test_grid_and_punch_fixes()
	await test_foxy_clips()
	await test_foxy_glb()
	print("RESULT fails=", fails)
	quit(1 if fails > 0 else 0)


func test_meshes() -> void:
	for key in ["board", "stringer", "post", "palm_a", "palm_b"]:
		var m := TrackProtos.get_mesh(key)
		check(m != null and m.get_surface_count() > 0, "mesh proto '%s' builds" % key)
	var f := Foxy.new()
	f.build(true)
	check(f.get_child_count() > 0, "Foxy builds")
	f.free()


func _new_runner() -> Runner:
	var r := Runner.new(TrackData.new())
	r.start_race()
	return r


func test_run_forward() -> void:
	var r := _new_runner()
	for i in range(240):
		r.step(1.0 / 120.0)
	check(r.s > TrackData.START_S + 15.0, "runner auto-runs forward (s=%.1f)" % r.s)
	r.input.steer = 1.0
	for i in range(120):
		r.step(1.0 / 120.0)
	check(r.x > 0.5, "steering right moves x (x=%.2f)" % r.x)
	check(absf(r.x) <= TrackData.HALF_W + 0.01, "x stays within track")


func test_jump() -> void:
	var r := _new_runner()
	for i in range(60):
		r.step(1.0 / 120.0)
	r.input.jump = true
	var peak := 0.0
	var landed := false
	for i in range(240):
		r.step(1.0 / 120.0)
		peak = maxf(peak, r.y)
		if i > 20 and r.state == Runner.State.RUN:
			landed = true
			break
	check(peak > 1.5, "jump rises (peak=%.2f)" % peak)
	check(landed, "jump lands back to RUN")


func test_slide() -> void:
	var r := _new_runner()
	for i in range(60):
		r.step(1.0 / 120.0)
	r.input.slide = true
	r.step(1.0 / 120.0)
	check(r.state == Runner.State.SLIDE, "slide enters SLIDE")
	for i in range(150):
		r.step(1.0 / 120.0)
	check(r.state != Runner.State.SLIDE, "slide ends")


func test_full_race_survives() -> void:
	var r := _new_runner()
	var t := 0
	while r.state != Runner.State.FINISHED and t < 120 * 400:
		r.input.steer = 0.0
		# روبوت بسيط يستجيب لكل نوع عائق وللحفر
		if not r.track.pit_at(r.s + 2.2, r.x).is_empty():
			r.input.jump = true
		for o in r.track.obstacles:
			var d: float = o.s0 - r.s
			if not o.alive or d < 0.0 or d > 3.0 or o.type == "hammer":
				continue
			if r.x < o.x0 - 0.5 or r.x > o.x1 + 0.5:
				continue
			match o.type:
				"log": if d < 2.2: r.input.jump = true
				"vine": if d < 2.4: r.input.slide = true
				"crate": if d < 1.6: r.input.punch = true
		r.step(1.0 / 120.0)
		t += 1
	check(r.state == Runner.State.FINISHED, "bot reaches finish line (t=%.1fs, s=%.0f, falls=%d, stumbles=%d)" % [r.time, r.s, r.falls, r.stumbles])


func test_track_consistency() -> void:
	var d := TrackData.new()
	var ok := true
	for i in range(0, 1000, 5):
		var s := float(i)
		if not d.center(s).is_finite() or not d.forward(s).is_finite():
			ok = false
	check(ok, "track frame finite along entire length")
	check(d.solid_at(0.0, 0.0), "start area is solid")


func test_race8() -> void:
	var pr := Runner.new(TrackData.new())
	var logic := RaceLogic.new(pr, 3, 99)
	check(logic.runners.size() == 8, "8 racers in the race")
	var hit_box := [0]
	logic.racer_hit.connect(func(_v, _a): hit_box[0] += 1)
	logic.start()
	# اللاعب نفسه يُدار بنفس الذكاء الآلي لاختبار السباق كاملًا
	var pai := RacerAI.new(0.9, 0.5, 7)
	var t := 0
	var done := 0
	while t < 120 * 300:
		pai.update(1.0 / 120.0, pr, logic.runners)
		logic.step(1.0 / 120.0)
		t += 1
		done = 0
		for r in logic.runners:
			if r.state == Runner.State.FINISHED:
				done += 1
		if done == 8:
			break
	check(done >= 7, "at least 7/8 racers finish within 300s (finished=%d, t=%.0fs)" % [done, float(t) / 120.0])
	var order := logic.standings()
	check(order.size() == 8 and order[0] != order[1], "standings produced; winner idx=%d" % order[0])
	var hits: int = hit_box[0]
	check(hits > 0, "rival punches land during the race (hits=%d)" % hits)
	var total_hit := 0
	for r in logic.runners:
		total_hit += r.times_hit
	check(total_hit == hits, "hit count consistent")
	# حماية: الضربة الثانية مباشرة لا تؤثر
	var a := Runner.new(TrackData.new())
	var v := Runner.new(TrackData.new())
	a.start_race()
	v.start_race()
	check(v.take_hit(), "first hit lands")
	check(not v.take_hit(), "victim is protected right after a hit")


func test_direct_strike() -> void:
	var pr := Runner.new(TrackData.new())
	var logic := RaceLogic.new(pr, 0, 5)
	logic.start()
	for r in logic.runners:
		r.s = 100.0
		r.x = -5.0 + 0.0
	logic.runners[0].x = 0.0
	logic.runners[1].x = 0.3
	logic.runners[1].s = 101.0
	for i in range(2, 8):
		logic.runners[i].x = 5.0
		logic.runners[i].s = 300.0 + 10.0 * i
	logic.runners[0].input.punch = true
	for i in range(60):
		logic.runners[0].step(1.0 / 120.0)
	check(logic.runners[1].times_hit == 1, "punch hits rival in front (times_hit=%d)" % logic.runners[1].times_hit)
	check(logic.runners[0].t_punch_cd > 1.5 or logic.runners[0].rival_hits == 1, "rival hit sets longer cooldown")
	check(logic.runners[1].is_invulnerable(), "victim gets short protection")


func test_foxy_clips() -> void:
	var f := Foxy.new()
	f.build(true)
	root.add_child(f)
	await process_frame
	check(f.player != null and f.player.get_animation_list().size() == 9, "9 baked clips in AnimationPlayer")
	check(f.tree != null and f.tree.tree_root is AnimationNodeStateMachine, "AnimationTree state machine exists")
	# جري: يجب أن تتحرك الساق وتنتقل الحالة إلى run
	f.anim = Foxy.Anim.RUN
	f.run_speed = 13.0
	var lo := 99.0
	var hi := -99.0
	for i in range(120):
		f._process(1.0 / 60.0)
		lo = minf(lo, f.leg_l.rotation.x)
		hi = maxf(hi, f.leg_l.rotation.x)
	check(f._cur_state == "run", "state machine reaches run")
	check(hi - lo > 1.2, "run clip swings the leg (range=%.2f)" % (hi - lo))
	# مطابقة الخطوة: ضعف السرعة -> ضعف عدد الدورات تقريبًا (لا انزلاق للقدمين)
	var cycles := []
	for sp in [9.0, 18.0]:
		f.run_speed = sp
		for i in range(30):
			f._process(1.0 / 60.0)
		var crossings := 0
		var prev: float = f.leg_l.rotation.x
		for i in range(240):
			f._process(1.0 / 60.0)
			var cur: float = f.leg_l.rotation.x
			if prev < 0.0 and cur >= 0.0:
				crossings += 1
			prev = cur
		cycles.append(crossings)
	check(cycles[1] >= cycles[0] * 1.7 and cycles[1] <= cycles[0] * 2.3, "stride rate scales with speed (%s)" % str(cycles))
	# قفز، هبوط، تعثّر، احتفال
	f.anim = Foxy.Anim.JUMP
	f.vy = 6.0
	for i in range(20):
		f._process(1.0 / 60.0)
	check(f._cur_state == "jump_up", "jump_up state")
	f.vy = -6.0
	f.height_above = 3.0
	for i in range(20):
		f._process(1.0 / 60.0)
	check(f._cur_state == "fall_air", "fall_air state")
	f.anim = Foxy.Anim.STUMBLE
	for i in range(20):
		f._process(1.0 / 60.0)
	check(f._cur_state == "stumble", "stumble state")
	f.anim = Foxy.Anim.CHEER
	for i in range(30):
		f._process(1.0 / 60.0)
	check(f._cur_state == "cheer" and f.arm_l.rotation.x > 2.0, "cheer raises arms")
	# هبوط: ثني الركبتين
	f.anim = Foxy.Anim.RUN
	for i in range(30):
		f._process(1.0 / 60.0)
	f.notify_land(true)
	var kmin := 0.0
	for i in range(10):
		f._process(1.0 / 60.0)
		kmin = minf(kmin, f.knee_l.rotation.x)
	check(kmin < -1.0, "landing bends the knees (%.2f)" % kmin)
	f.queue_free()


func test_foxy_glb() -> void:
	var f := Foxy.create(true)
	check(f is FoxyGLB, "Foxy.create returns the GLB-rigged Foxy")
	var g := f as FoxyGLB
	root.add_child(f)
	await process_frame
	check(g.skeleton != null and g.skeleton.get_bone_count() >= 19, "GLB skeleton has %d bones" % g.skeleton.get_bone_count())
	var names: Array = Array(g.gplayer.get_animation_list())
	var need := ["idle", "run", "dash", "jump", "fall", "land", "slide", "stumble", "pit_fall", "victory", "turn_l", "turn_r", "punch", "punch_l"]
	var missing := []
	for n in need:
		if not (n in names):
			missing.append(n)
	check(missing.is_empty(), "GLB has all required clips (missing=%s)" % str(missing))
	var thigh := g.skeleton.find_bone("thigh.L")
	f.anim = Foxy.Anim.RUN
	var cyc := []
	for sp in [9.0, 18.0]:
		f.run_speed = sp
		for i in range(30):
			f._process(1.0 / 60.0)
		var crossings := 0
		var prev := g.skeleton.get_bone_pose_rotation(thigh).get_euler().x
		var lo := 9.0
		var hi := -9.0
		for i in range(240):
			f._process(1.0 / 60.0)
			var cur := g.skeleton.get_bone_pose_rotation(thigh).get_euler().x
			lo = minf(lo, cur)
			hi = maxf(hi, cur)
			if prev < 0.0 and cur >= 0.0:
				crossings += 1
			prev = cur
		cyc.append(crossings)
		check(hi - lo > 0.8, "GLB run swings the thigh (range %.2f at speed %.0f)" % [hi - lo, sp])
	check(cyc[1] >= cyc[0] * 1.7 and cyc[1] <= cyc[0] * 2.3, "GLB stride rate scales with speed (%s)" % str(cyc))
	for pair in [[Foxy.Anim.JUMP, 6.0, "jump"], [Foxy.Anim.JUMP, -6.0, "fall"], [Foxy.Anim.STUMBLE, 0.0, "stumble"],
			[Foxy.Anim.FALL, 0.0, "pit_fall"], [Foxy.Anim.CHEER, 0.0, "victory"], [Foxy.Anim.SLIDE, 0.0, "slide"]]:
		f.anim = pair[0]
		f.vy = pair[1]
		for i in range(20):
			f._process(1.0 / 60.0)
		check(g._gstate == pair[2], "GLB state %s reached (got %s)" % [pair[2], g._gstate])
	f.anim = Foxy.Anim.RUN
	for i in range(30):
		f._process(1.0 / 60.0)
	f.notify_land(true)
	f._process(1.0 / 60.0)
	check(g._gstate == "land", "GLB landing clip triggers on notify_land")
	f.lean = 1.0
	for i in range(40):
		f._process(1.0 / 60.0)
	var bp: float = g.gtree.get("parameters/sm/run/turn/blend_position")
	check(bp > 0.9, "GLB turn blend follows steering lean (%.2f)" % bp)
	f.start_punch()
	for i in range(8):
		f._process(1.0 / 60.0)
	check(g.punch_t >= 0.0, "GLB punch fires")
	var troot := g.gtree.tree_root as AnimationNodeBlendTree
	var shot_r := troot.get_node("shot") as AnimationNodeOneShot
	var shot_l := troot.get_node("shot_l") as AnimationNodeOneShot
	var pa: Animation = g.gplayer.get_animation("punch")
	var nr := 0
	var nl := 0
	for t in range(pa.get_track_count()):
		var tp := String(pa.track_get_path(t))
		if shot_r.is_path_filtered(pa.track_get_path(t)):
			nr += 1
			check(tp.ends_with(".R"), "right filter only touches right-side bones (%s)" % tp)
		if shot_l.is_path_filtered(pa.track_get_path(t)):
			nl += 1
			check(tp.ends_with(".L"), "left filter only touches left-side bones (%s)" % tp)
	check(nr == 2 and nl == 2, "punch filters cover arm+forearm on each side (r=%d l=%d)" % [nr, nl])
	var ghost := f.make_ghost()
	check(ghost != null and ghost.find_children("*", "MeshInstance3D", true, false).size() == 3, "GLB ghost copy built")
	ghost.free()
	f.queue_free()


func test_grid_and_punch_fixes() -> void:
	var pr := Runner.new(TrackData.new())
	var logic := RaceLogic.new(pr, 3, 7)
	# --- شبكة بصفّين: لا تداخل
	var mind := 99.0
	var rows := {}
	for i in range(8):
		var a: Runner = logic.runners[i]
		rows[snappedf(a.s, 0.01)] = rows.get(snappedf(a.s, 0.01), 0) + 1
		for j in range(i + 1, 8):
			var b: Runner = logic.runners[j]
			mind = minf(mind, Vector2(a.x - b.x, a.s - b.s).length())
	check(mind >= 2.19, "start grid: min distance between racers %.2f m (>= 2.2)" % mind)
	check(rows.size() == 2, "start grid has exactly two rows (%s)" % str(rows))
	var maxs := 0.0
	var mins := 99.0
	for r in logic.runners:
		maxs = maxf(maxs, r.s)
		mins = minf(mins, r.s)
	check(absf((maxs - mins) - RaceLogic.ROW_GAP) < 0.001, "row stagger equals ROW_GAP (%.2f m) to the same finish line" % (maxs - mins))
	var same_row_min := 99.0
	for i in range(8):
		for j in range(i + 1, 8):
			if absf(logic.runners[i].s - logic.runners[j].s) < 0.01:
				same_row_min = minf(same_row_min, absf(logic.runners[i].x - logic.runners[j].x))
	check(same_row_min >= 2.99, "same-row lateral spacing %.2f m (>= 3.0)" % same_row_min)
	# --- اللكمة: لحظة الإصابة عند وصول القبضة + دفع جانبي + ضربة جانبية
	check(Runner.PUNCH_HIT_AT >= 0.18 and Runner.PUNCH_HIT_AT <= 0.24, "punch resolves when the fist arrives (%.2f s)" % Runner.PUNCH_HIT_AT)
	var pr2 := Runner.new(TrackData.new())
	var lg := RaceLogic.new(pr2, 0, 5)
	lg.start()
	for r in lg.runners:
		r.s = 100.0
		r.x = -5.0
	for i in range(2, 8):
		lg.runners[i].x = 5.0
		lg.runners[i].s = 300.0 + 10.0 * i
	lg.runners[0].x = 0.0
	lg.runners[1].x = 1.7          # جانبي (على اليمين) وأمام قليلًا
	lg.runners[1].s = 100.8
	check(lg.punch_side(0) > 0.0, "punch aims right toward the rival on the right")
	lg.runners[1].x = -1.7
	check(lg.punch_side(0) < 0.0, "punch aims left toward the rival on the left")
	var x0: float = lg.runners[1].x
	lg.runners[0].input.punch = true
	var hit_time := -1.0
	for i in range(80):
		lg.runners[0].step(1.0 / 120.0)
		lg.runners[1].step(1.0 / 120.0)
		if hit_time < 0.0 and lg.runners[1].times_hit == 1:
			hit_time = float(i) / 120.0
	check(lg.runners[1].times_hit == 1, "side punch connects with a rival 1.7 m to the side")
	check(hit_time >= 0.18 and hit_time <= 0.26, "hit registered at fist arrival (%.2f s)" % hit_time)
	var moved: float = lg.runners[1].x - x0
	check(moved < -0.3 and moved > -1.6, "victim shoved sideways away from attacker (%.2f m)" % moved)
	# --- ذراع الجري أوضح: مدى حركة الكتف والمرفق في المقطع
	var f := Foxy.new()
	f.build(false)
	var zs := []
	f.anim = Foxy.Anim.RUN
	f.run_speed = 13.0
	f.lean = 0.0
	f._lean_s = 0.0
	for k in range(24):
		f._phase = TAU * float(k) / 24.0
		f._compute_target(0.0)
		zs.append(absf(f._target[Foxy.P_ALZ]))
	var zmin: float = zs.min()
	check(zmin >= 0.35, "run arms stay abducted away from torso (min z %.2f rad)" % zmin)
	f.free()
