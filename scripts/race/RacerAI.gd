class_name RacerAI
extends RefCounted
## متحكم المتسابق الآلي: يقرأ المسار ويولّد نفس مدخلات اللاعب (steer/jump/slide/punch/special).
## المهارة (0..1) تحدد احتمال الخطأ وسرعة الاستجابة ونزعة الهجوم.

var skill := 0.8
var aggression := 0.5
var lane_x := 0.0
var _tick := 0.0
var _rng := RandomNumberGenerator.new()
var _decided: Dictionary = {}     # معرّف العائق -> هل سيتصرف بشكل صحيح
var _lane_t := 0.0
var chasing := false


func _init(p_skill: float, p_aggr: float, seed_v: int) -> void:
	skill = p_skill
	aggression = p_aggr
	_rng.seed = seed_v
	lane_x = _rng.randf_range(-4.5, 4.5)


func update(dt: float, r: Runner, others: Array) -> void:
	if r.state == Runner.State.FINISHED or r.state == Runner.State.WAIT:
		r.input.steer = 0.0
		return
	if r.state == Runner.State.FALLING:
		for k in _decided.keys():
			if str(k).begins_with("pit"):
				_decided.erase(k)
	_tick -= dt
	_lane_t -= dt
	if _lane_t <= 0.0:
		_lane_t = _rng.randf_range(1.5, 3.5)
		lane_x = clampf(lane_x + _rng.randf_range(-2.5, 2.5), -4.8, 4.8)
	var steer_target := lane_x
	if _tick > 0.0:
		r.input.steer = clampf((steer_target - r.x) * 0.9, -1.0, 1.0)
		return
	_tick = lerpf(0.09, 0.03, skill)
	var track := r.track
	# حفر: اقفز قبل الحافة بمسافة تناسب السرعة (مع احتمال خطأ ضئيل)
	var lead := r.speed * 0.17 + 0.4
	var pit := track.pit_at(r.s + lead, r.x)
	if not pit.is_empty() and r.is_grounded():
		var key := "pit%d_%d" % [int(pit.s0), TrackData.col_of(r.x)]
		if _decide(key, 1.0 - (1.0 - skill) * 0.5):
			r.input.jump = true
	for o in track.obstacles:
		if not o.alive:
			continue
		var d: float = o.s0 - r.s
		if d < -0.2 or d > 12.0:
			continue
		if o.type == "hammer":
			# اختر جانبًا خاليًا من المطرقة عند الاقتراب
			if d < 9.0:
				var head := r.hammer_head(o, r.time + d / maxf(r.speed, 1.0))
				var hx: float = head.y
				if absf(hx - lane_x) < 1.9:
					lane_x = clampf(-signf(hx) * 3.0 if absf(hx) > 0.1 else 3.0, -4.8, 4.8)
			continue
		if r.x < o.x0 - 0.6 or r.x > o.x1 + 0.6:
			continue
		var key2 := "o_%s_%.1f_%.1f" % [o.type, o.s, o.x0]
		var ok := _decide(key2, skill)
		match o.type:
			"log":
				if ok and d < lead + 0.6 and r.is_grounded():
					r.input.jump = true
			"vine":
				if ok and d < lead + 0.8:
					r.input.slide = true
			"crate":
				if ok and d < 1.5:
					r.input.punch = true
				elif not ok and d < 3.0:
					pass
	# قتال: اضرب منافسًا أمامك مباشرة
	if r.punch_ready() and r.state != Runner.State.STUMBLE:
		for other in others:
			if other == r or other.t_invuln > 0.0:
				continue
			var ds: float = other.s - r.s
			if ds > -0.2 and ds < Runner.PUNCH_RANGE - 0.2 and absf(other.x - r.x) < 1.5:
				if _rng.randf() < aggression * (0.35 + 0.65 * skill):
					r.input.punch = true
					break
	chasing = false
	# هجوم: توجّه نحو أقرب منافس أمامك خلال 7 أمتار
	if aggression > 0.3:
		for other in others:
			if other == r:
				continue
			var ds2: float = other.s - r.s
			if ds2 > 0.6 and ds2 < 14.0 and other.state != Runner.State.FALLING:
				if ds2 < 9.0:
					lane_x = lerpf(lane_x, other.x, 0.8)
				chasing = true
				break
	# قدرة خاصة: عند الجاهزية في مقطع مستقيم
	if r.dash_ready() and r.state == Runner.State.RUN and _rng.randf() < 0.02:
		r.input.special = true
	r.input.steer = clampf((steer_target - r.x) * 0.9, -1.0, 1.0)


func _decide(key: String, p: float) -> bool:
	if not _decided.has(key):
		_decided[key] = _rng.randf() < p
	return _decided[key]
