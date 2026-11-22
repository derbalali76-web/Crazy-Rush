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
