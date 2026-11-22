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
