extends SceneTree
## يستخرج مفاتيح الحركة من وضعيات Foxy الإجرائية إلى JSON ليقرأها سكربت Blender.
## godot --headless -s tools/dump_clips.gd
const NODES := ["hips", "head", "arm_l", "elbow_l", "arm_r", "elbow_r", "leg_l", "knee_l", "leg_r", "knee_r"]


func _init() -> void:
	var f := Foxy.new()
	f.build(false)
	var run_len := TAU / (Foxy.REF_SPEED * Foxy.STRIDE_RATE)
	# [anim, length, samples, vy, lean, loop, extra]
	var specs := {
		"idle": [Foxy.Anim.IDLE, 6.0, 30, 0.0, 0.0, true, ""],
		"run": [Foxy.Anim.RUN, run_len, 24, 0.0, 0.0, true, ""],
		"dash": [Foxy.Anim.DASH, run_len / 1.35, 24, 0.0, 0.0, true, ""],
		"turn_l": [Foxy.Anim.RUN, run_len, 24, 0.0, -1.0, true, ""],
		"turn_r": [Foxy.Anim.RUN, run_len, 24, 0.0, 1.0, true, ""],
		"jump": [Foxy.Anim.JUMP, 0.5, 4, 8.0, 0.0, true, ""],
		"fall": [Foxy.Anim.JUMP, 0.5, 4, -6.0, 0.0, true, ""],
		"land": [Foxy.Anim.RUN, 0.36, 12, 0.0, 0.0, false, "land"],
		"slide": [Foxy.Anim.SLIDE, 0.6, 4, 0.0, 0.0, true, ""],
		"stumble": [Foxy.Anim.STUMBLE, TAU / 30.0 * 2.0, 16, 0.0, 0.0, true, ""],
		"pit_fall": [Foxy.Anim.FALL, TAU / 22.0 * 2.0, 16, 0.0, 0.0, true, ""],
		"victory": [Foxy.Anim.CHEER, PI / 7.0, 16, 0.0, 0.0, true, ""],
		"punch": [Foxy.Anim.RUN, 0.45, 12, 0.0, 0.0, false, "punch"],
	}
	var out := {}
	for key in specs.keys():
		var sp: Array = specs[key]
		var frames := []
		for k in range(int(sp[2]) + 1):
			var u := float(k) / float(sp[2])
			f.anim = sp[0]
			f.run_speed = Foxy.REF_SPEED
			f.lean = sp[4]
			f._lean_s = sp[4]
			f.vy = sp[3]
			f.height_above = 9.0
			f._land_t = 0.0
			f.punch_t = -1.0
			f._time = u * float(sp[1])
			f._phase = TAU * u
			if sp[6] == "land":
				f._phase = 0.4
				f._land_t = 0.22 * (1.0 - u)
			if sp[6] == "punch":
				f._phase = 0.9
				f.punch_t = u * 0.44
			f._compute_target(0.0)
			for j in range(Foxy.P_COUNT):
				f._pose[j] = f._target[j]
			f._apply_pose()
			f._apply_overlays()
			var row := [f.hips.position.y]
			for nm in NODES:
				var n: Node3D = f.get(nm)
				row.append_array([n.rotation.x, n.rotation.y, n.rotation.z])
			frames.append(row)
		out[key] = {"length": sp[1], "loop": sp[5], "frames": frames}
	var fa := FileAccess.open("res://tools/blender/foxy_clips.json", FileAccess.WRITE)
	fa.store_string(JSON.stringify(out))
	fa.close()
	print("dumped ", out.size(), " clips")
	quit()
