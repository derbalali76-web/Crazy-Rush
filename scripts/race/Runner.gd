class_name Runner
extends RefCounted
## محاكاة العدّاء على مساحة المسار (s, x, y). منطق بحت بلا رسوم، قابل للاختبار آليًا.
## القيم الابتدائية من وثيقة التصميم (تُضبط بالاختبار): مدى الضرب 1.8م، تعثّر 0.6ث، حماية 1.5ث، عودة بعد السقوط 1.5ث.

signal jumped
signal landed(hard: bool)
signal slid
signal stumbled(kind: String)
signal punch_started
signal punch_hit(target: Dictionary)
signal punch_missed
signal coin_collected(index: int)
signal boosted
signal fell
signal respawned
signal finished(time: float)
signal dashed

enum State { WAIT, RUN, AIR, SLIDE, STUMBLE, FALLING, FINISHED }

# ---- معاملات التوازن
const BASE_SPEED := 13.0
const MAX_LAT := 8.0
const LAT_ACCEL := 46.0
const GRAVITY := 29.0
const JUMP_V := 10.8
const COYOTE := 0.10
const JUMP_BUFFER := 0.14
const SLIDE_TIME := 0.80
const STUMBLE_TIME := 0.60
const INVULN_TIME := 1.50
const FALL_RESPAWN := 1.50
const PUNCH_RANGE := 1.8
const PUNCH_WIDTH := 1.25
const PUNCH_HIT_AT := 0.12
const PUNCH_COOLDOWN := 0.50     # دورة التأرجح (الانتظار 2.5ث يخص ضرب المنافسين لاحقًا)
const DASH_TIME := 1.0
const DASH_COOLDOWN := 7.0
const BOOST_TIME := 1.8
const STAND_H := 1.55
const SLIDE_H := 0.70
const HALF_D := 0.38
const HALF_X := 0.36
const RAIL := TrackData.HALF_W - 0.45

var track: TrackData
var input := RunnerInput.new()

var state: int = State.WAIT
var s := TrackData.START_S
var x := 0.0
var y := 0.0
var vy := 0.0
var lat_v := 0.0
var speed := 0.0
var time := 0.0
var finish_time := 0.0
var coins_got := 0
var stumbles := 0
var falls := 0
var crates_broken := 0

var t_slide := 0.0
var t_stumble := 0.0
var t_invuln := 0.0
var t_fall := 0.0
var t_punch := -1.0
var t_punch_cd := 0.0
var t_dash := 0.0
var t_dash_cd := 0.0
var t_boost := 0.0
var t_coyote := 0.0
var t_jump_buf := 0.0
var _punch_resolved := true
var _queued_slide := false
var _grounded := true
var coin_alive: PackedByteArray = PackedByteArray()
var _respawn_s := 0.0


func _init(p_track: TrackData) -> void:
	track = p_track
	coin_alive.resize(track.coins.size())
	coin_alive.fill(1)


func start_race() -> void:
	state = State.RUN
	speed = BASE_SPEED * 0.55


func height() -> float:
	return SLIDE_H if state == State.SLIDE else STAND_H


func is_grounded() -> bool:
	return _grounded


func is_invulnerable() -> bool:
	return t_invuln > 0.0


func dash_ready() -> bool:
	return t_dash_cd <= 0.0 and state != State.FINISHED and state != State.FALLING


func punch_ready() -> bool:
	return t_punch_cd <= 0.0


# ------------------------------------------------------------------ الخطوة
func step(dt: float) -> void:
	if state == State.WAIT:
		input.clear_events()
		return
	if state == State.FINISHED:
		speed = move_toward(speed, 0.0, 9.0 * dt)
		s += speed * dt
		_physics_vertical(dt)
		input.clear_events()
		return
	time += dt
	_tick_timers(dt)

	if state == State.FALLING:
		vy -= GRAVITY * dt
		y += vy * dt
		s += speed * 0.25 * dt
		speed = move_toward(speed, 0.0, 6.0 * dt)
		if t_fall <= 0.0:
			_respawn()
		input.clear_events()
		return

	_handle_actions()
	_steer(dt)
	_speed_update(dt)
	s += speed * dt
	_physics_vertical(dt)
	_punch_update(dt)
	_check_pads()
	_check_coins()
	if state != State.FALLING and state != State.FINISHED:
		_check_obstacles()
	if s >= TrackData.FINISH_S and state != State.FINISHED:
		state = State.FINISHED
		finish_time = time
		y = maxf(y, 0.0)
		finished.emit(finish_time)
	input.clear_events()


func _tick_timers(dt: float) -> void:
	t_invuln = maxf(t_invuln - dt, 0.0)
	t_punch_cd = maxf(t_punch_cd - dt, 0.0)
	t_dash_cd = maxf(t_dash_cd - dt, 0.0)
	t_dash = maxf(t_dash - dt, 0.0)
	t_boost = maxf(t_boost - dt, 0.0)
	t_coyote = maxf(t_coyote - dt, 0.0)
	t_jump_buf = maxf(t_jump_buf - dt, 0.0)
	t_fall = maxf(t_fall - dt, 0.0)
	if state == State.SLIDE:
		t_slide -= dt
		if t_slide <= 0.0:
			state = State.RUN if _grounded else State.AIR
	if state == State.STUMBLE:
		t_stumble -= dt
		if t_stumble <= 0.0:
			state = State.RUN if _grounded else State.AIR


func _handle_actions() -> void:
	if input.jump:
		t_jump_buf = JUMP_BUFFER
	if t_jump_buf > 0.0 and (_grounded or t_coyote > 0.0) and state != State.STUMBLE:
		vy = JUMP_V
		y = maxf(y, 0.001)
		_grounded = false
		t_coyote = 0.0
		t_jump_buf = 0.0
		state = State.AIR
		jumped.emit()
	if input.slide:
		if _grounded and state != State.STUMBLE:
			state = State.SLIDE
			t_slide = SLIDE_TIME
			slid.emit()
		elif not _grounded:
			vy = minf(vy, -17.0)
			_queued_slide = true
	if input.punch and t_punch_cd <= 0.0 and state != State.STUMBLE:
		t_punch = 0.0
		t_punch_cd = PUNCH_COOLDOWN
		_punch_resolved = false
		punch_started.emit()
	if input.special and dash_ready():
		t_dash = DASH_TIME
		t_dash_cd = DASH_COOLDOWN
		dashed.emit()


func _steer(dt: float) -> void:
	var lim := MAX_LAT * (0.5 if state == State.STUMBLE else 1.0)
	var target := clampf(input.steer, -1.0, 1.0) * lim
	lat_v = move_toward(lat_v, target, LAT_ACCEL * dt)
	x = clampf(x + lat_v * dt, -RAIL, RAIL)
	if absf(x) >= RAIL - 0.001 and signf(lat_v) == signf(x):
		lat_v = 0.0


func _speed_update(dt: float) -> void:
	var tgt := BASE_SPEED
	if t_dash > 0.0:
		tgt *= 1.38
	if t_boost > 0.0:
		tgt *= 1.30
	if state == State.STUMBLE:
		tgt *= 0.35
	elif state == State.SLIDE:
		tgt *= 1.04
	var rate := 14.0 if tgt > speed else 22.0
	speed = move_toward(speed, tgt, rate * dt)


func _physics_vertical(dt: float) -> void:
	var solid := track.solid_at(s, x)
	if _grounded and state != State.FINISHED:
		if solid:
			y = 0.0
			vy = 0.0
			_respawn_s = s
		else:
			# غادر حافة الألواح: مهلة قصيرة ثم سقوط
			_grounded = false
			t_coyote = COYOTE
			if state == State.RUN or state == State.SLIDE:
				state = State.AIR
	if not _grounded:
		vy -= GRAVITY * dt
		y += vy * dt
		if y <= 0.0 and y > -0.5 and solid and vy <= 0.0:
			var hard := vy < -12.0
			y = 0.0
			vy = 0.0
			_grounded = true
			if state == State.AIR:
				state = State.RUN
			landed.emit(hard)
			if _queued_slide:
				_queued_slide = false
				state = State.SLIDE
				t_slide = SLIDE_TIME
				slid.emit()
			elif t_jump_buf > 0.0:
				pass
		elif y < -2.2 and not solid:
			if state != State.FALLING and state != State.FINISHED:
				state = State.FALLING
				t_fall = FALL_RESPAWN
				falls += 1
				_find_respawn()
				fell.emit()


func _find_respawn() -> void:
	var p := track.pit_at(s, x)
	if not p.is_empty():
		_respawn_s = p.s0 - 3.0
	else:
		_respawn_s = maxf(_respawn_s - 2.0, TrackData.START_S)


func _respawn() -> void:
	s = maxf(_respawn_s, TrackData.START_S)
	# اختر عمودًا صلبًا على نفس المسافة
	if not track.solid_at(s, x):
		x = 0.0
	y = 0.0
	vy = 0.0
	lat_v = 0.0
	speed = BASE_SPEED * 0.6
	_grounded = true
	state = State.RUN
	t_invuln = INVULN_TIME
	respawned.emit()


# ------------------------------------------------------------------ الضرب
func _punch_update(dt: float) -> void:
	if t_punch < 0.0:
		return
	t_punch += dt
	if not _punch_resolved and t_punch >= PUNCH_HIT_AT:
		_punch_resolved = true
		var hit_any := false
		for o in track.obstacles:
			if not o.alive or o.type != "crate":
				continue
			var ds: float = o.s - s
			if ds > -0.2 and ds < PUNCH_RANGE and absf(o.x - x) < PUNCH_WIDTH:
				o.alive = false
				crates_broken += 1
				hit_any = true
				punch_hit.emit(o)
		if not hit_any:
			punch_missed.emit()
	if t_punch > 0.45:
		t_punch = -1.0


# ------------------------------------------------------------------ مسرّعات وعملات
func _check_pads() -> void:
	if not _grounded:
		return
	for p in track.pads:
		var near: bool = absf(p.s - s) < 1.6 and absf(p.x - x) < 1.8
		if near and not p.get("hit_now", false):
			t_boost = BOOST_TIME
			p["hit_now"] = true
			boosted.emit()
		elif not near and absf(p.s - s) > 3.0:
			p["hit_now"] = false


func _check_coins() -> void:
	var py0 := y
	var py1 := y + height()
	for i in range(track.coins.size()):
		if coin_alive[i] == 0:
			continue
		var c: Vector3 = track.coins[i]
		if absf(c.x - s) > 0.9:
			continue
		if absf(c.y - x) > 1.0:
			continue
		if c.z + 0.3 < py0 or c.z - 0.3 > py1:
			continue
		coin_alive[i] = 0
		coins_got += 1
		coin_collected.emit(i)


# ------------------------------------------------------------------ العقبات
func hammer_head(o: Dictionary, t: float) -> Vector3:
	var th: float = o.amp * sin(o.omega * t + o.phase)
	return Vector3(o.s, o.px + o.len * sin(th), o.pivot_y - o.len * cos(th))   # (s, x, y)


func _check_obstacles() -> void:
	if t_invuln > 0.0:
		return
	var h := height()
	var ps0 := s - HALF_D
	var ps1 := s + HALF_D
	var px0 := x - HALF_X
	var px1 := x + HALF_X
	var py0 := y
	var py1 := y + h
	for o in track.obstacles:
		if not o.alive:
			continue
		if o.type == "hammer":
			if absf(o.s - s) > 3.0:
				continue
			var head := hammer_head(o, time)
			# مسافة كرة-صندوق
			var cs := clampf(head.x, ps0, ps1)
			var cx := clampf(head.y, px0, px1)
			var cy := clampf(head.z, py0, py1)
			var d := Vector3(head.x - cs, head.y - cx, head.z - cy).length()
			if d < o.radius * 0.92:
				_stumble("hammer")
				return
			continue
		if ps1 < o.s0 or ps0 > o.s1:
			continue
		if px1 < o.x0 or px0 > o.x1:
			continue
		if py1 < o.y0 or py0 > o.y1:
			continue
		if o.type == "crate":
			o.alive = false
			crates_broken += 1
			punch_hit.emit(o)
		_stumble(o.type)
		return


func _stumble(kind: String) -> void:
	state = State.STUMBLE
	t_stumble = STUMBLE_TIME
	t_invuln = INVULN_TIME
	t_slide = 0.0
	stumbles += 1
	speed *= 0.5
	stumbled.emit(kind)


## يستعمل في الاختبارات: هل النقطة خالية من العقبات عند وقت معيّن؟
func hammer_clear(o: Dictionary, t: float, xx: float, yy: float, hh: float) -> bool:
	var head := hammer_head(o, t)
	var cx := clampf(head.y, xx - HALF_X, xx + HALF_X)
	var cy := clampf(head.z, yy, yy + hh)
	var d := Vector2(head.y - cx, head.z - cy).length()
	return d >= o.radius * 0.92 + 0.02
