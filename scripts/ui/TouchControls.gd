class_name TouchControls
extends Control
## أدوات التحكم باللمس: نصف أيسر = سحب أفقي حر للتوجيه، نصف أيمن = أزرار + إيماءات (سحب لأعلى قفز، لأسفل انزلاق، لمسة ضرب).
## يدعم اللمس المتعدد (كل إصبع له معرّف مستقل) فلا تتداخل الإيماءات. وعلى الحاسوب: لوحة المفاتيح.

var input: RunnerInput
var punch_cd := 0.0          # 0..1 المتبقي
var special_cd := 0.0        # 0..1 المتبقي
var special_enabled := true
var sensitivity := 1.0
var enabled := true

const PAD_RADIUS := 92.0
const SWIPE_PX := 55.0

var _pad_touch := -1
var _pad_anchor := Vector2.ZERO
var _pad_pos := Vector2.ZERO
var _btn_touch: Dictionary = {}     # index -> اسم الزر
var _gest: Dictionary = {}          # index -> {start, t, done}
var _pressed: Dictionary = {}       # اسم الزر -> عدد اللمسات
var _kb_steer := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_PAUSABLE


func _btn_defs() -> Dictionary:
	var sz := size
	return {
		"jump": {"c": Vector2(sz.x - 132, sz.y - 128), "r": 80.0},
		"slide": {"c": Vector2(sz.x - 296, sz.y - 88), "r": 58.0},
		"punch": {"c": Vector2(sz.x - 262, sz.y - 222), "r": 64.0},
		"special": {"c": Vector2(sz.x - 118, sz.y - 292), "r": 56.0},
	}


func _default_pad_center() -> Vector2:
	return Vector2(176.0, size.y - 128.0)


# ------------------------------------------------------------------ إدخال
func _input(event: InputEvent) -> void:
	if not enabled or input == null:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_down(event.index, event.position)
		else:
			_up(event.index, event.position)
	elif event is InputEventScreenDrag:
		_move(event.index, event.position)
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE, KEY_UP, KEY_W:
				input.jump = true
			KEY_DOWN, KEY_S, KEY_CTRL:
				input.slide = true
			KEY_J, KEY_X, KEY_F:
				input.punch = true
			KEY_K, KEY_E, KEY_SHIFT:
				if special_cd <= 0.0 and special_enabled:
					input.special = true


func _down(idx: int, pos: Vector2) -> void:
	var defs := _btn_defs()
	for name in defs:
		var d: Dictionary = defs[name]
		if pos.distance_to(d.c) <= d.r * 1.2:
			_btn_touch[idx] = name
			_pressed[name] = int(_pressed.get(name, 0)) + 1
			match name:
				"jump": input.jump = true
				"slide": input.slide = true
				"punch": input.punch = true
				"special":
					if special_cd <= 0.0 and special_enabled:
						input.special = true
			return
	if pos.x < size.x * 0.5 and _pad_touch == -1:
		_pad_touch = idx
		var c := Vector2(clampf(pos.x, PAD_RADIUS + 20.0, size.x * 0.5 - 40.0), clampf(pos.y, size.y * 0.45, size.y - PAD_RADIUS - 10.0))
		_pad_anchor = c
		_pad_pos = pos
		_update_steer()
	elif pos.x >= size.x * 0.5:
		_gest[idx] = {"start": pos, "t": Time.get_ticks_msec(), "done": false}


func _move(idx: int, pos: Vector2) -> void:
	if idx == _pad_touch:
		_pad_pos = pos
		_update_steer()
	elif _gest.has(idx):
		var g: Dictionary = _gest[idx]
		if g.done:
			return
		var d: Vector2 = pos - g.start
		if d.y < -SWIPE_PX and absf(d.y) > absf(d.x) * 0.7:
			input.jump = true
			g.done = true
		elif d.y > SWIPE_PX and absf(d.y) > absf(d.x) * 0.7:
			input.slide = true
			g.done = true


func _up(idx: int, pos: Vector2) -> void:
	if idx == _pad_touch:
		_pad_touch = -1
		input.steer = 0.0
	if _btn_touch.has(idx):
		var n: String = _btn_touch[idx]
		_pressed[n] = maxi(int(_pressed.get(n, 1)) - 1, 0)
		_btn_touch.erase(idx)
	if _gest.has(idx):
		var g: Dictionary = _gest[idx]
		var moved: float = pos.distance_to(g.start)
		var dt: float = float(Time.get_ticks_msec() - int(g.t)) / 1000.0
		if not g.done and moved < 28.0 and dt < 0.30:
			input.punch = true
		_gest.erase(idx)


func _update_steer() -> void:
	var dx := (_pad_pos.x - _pad_anchor.x) / (PAD_RADIUS * 0.62) * sensitivity
	var v := clampf(dx, -1.0, 1.0)
	if absf(v) < 0.06:
		v = 0.0
	input.steer = signf(v) * pow(absf(v), 1.15)


func _process(delta: float) -> void:
	if not enabled or input == null:
		return
	# لوحة المفاتيح (للاختبار على الحاسوب)
	var k := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		k -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		k += 1.0
	if k != 0.0 or _kb_steer != 0.0:
		_kb_steer = move_toward(_kb_steer, k, 7.0 * delta)
		if _pad_touch == -1:
			input.steer = _kb_steer
	queue_redraw()


# ------------------------------------------------------------------ رسم
func _draw() -> void:
	if input == null:
		return
	_draw_pad()
	var defs := _btn_defs()
	for name in defs:
		_draw_button(name, defs[name])


func _draw_pad() -> void:
	var active := _pad_touch != -1
	var c := _pad_anchor if active else _default_pad_center()
	var a := 0.95 if active else 0.62
	draw_circle(c + Vector2(0, 5), PAD_RADIUS, Color(0, 0, 0, 0.25 * a))
	draw_circle(c, PAD_RADIUS, Color(0.55, 0.62, 0.85, 0.42 * a))
	draw_arc(c, PAD_RADIUS - 2.0, 0, TAU, 48, Color(1, 1, 1, 0.85 * a), 5.0, true)
	# أسهم اليمين واليسار
	for sgn in [-1.0, 1.0]:
		var tip := c + Vector2(sgn * (PAD_RADIUS - 18.0), 0)
		var pts := PackedVector2Array([tip, tip + Vector2(-sgn * 22.0, -16.0), tip + Vector2(-sgn * 22.0, 16.0)])
		draw_colored_polygon(pts, Color(1, 1, 1, 0.85 * a))
	var knob := c
	if active:
		var off := clampf(_pad_pos.x - _pad_anchor.x, -PAD_RADIUS * 0.62, PAD_RADIUS * 0.62)
		knob = c + Vector2(off, 0)
	else:
		knob = c + Vector2(input.steer * PAD_RADIUS * 0.62, 0)
	draw_circle(knob + Vector2(0, 4), 36.0, Color(0, 0, 0, 0.3 * a))
	draw_circle(knob, 36.0, Color(0.86, 0.88, 0.98, a))
	draw_circle(knob + Vector2(-6, -8), 24.0, Color(1, 1, 1, 0.8 * a))


func _draw_button(name: String, d: Dictionary) -> void:
	var c: Vector2 = d.c
	var r: float = d.r
	var down := int(_pressed.get(name, 0)) > 0
	if down:
		r *= 0.93
	var top := Color("4aa3ff")
	var bot := Color("1f4fd0")
	match name:
		"slide":
			top = Color("5a6aa8"); bot = Color("2a3470")
		"punch":
			top = Color("ff6a5c"); bot = Color("b3151f")
		"special":
			top = Color("b36bff"); bot = Color("5a2ac8")
	var cd := 0.0
	var usable := true
	if name == "punch":
		cd = punch_cd
	elif name == "special":
		cd = special_cd
		usable = special_enabled
	var alpha := 1.0 if usable else 0.45
	draw_circle(c + Vector2(0, 6), r + 3.0, Color(0, 0, 0, 0.35))
	draw_circle(c, r + 3.0, Color(1, 1, 1, alpha))
	draw_circle(c, r - 3.0, Color(bot.r, bot.g, bot.b, alpha))
	draw_circle(c + Vector2(0, -r * 0.08), r - 8.0, Color(top.r, top.g, top.b, alpha))
	# لمعة علوية
	var hl := PackedVector2Array()
	for i in range(0, 21):
		var a := PI + PI * float(i) / 20.0
		hl.append(c + Vector2(cos(a) * (r - 12.0), sin(a) * (r - 12.0) * 0.55 - r * 0.22))
	draw_colored_polygon(hl, Color(1, 1, 1, 0.22 * alpha))
	_draw_icon(name, c, r, alpha)
	if cd > 0.0:
		var pts := PackedVector2Array([c])
		var steps := int(48.0 * cd) + 2
		for i in range(steps + 1):
			var ang := -PI * 0.5 + TAU * (cd * float(i) / float(steps))
			pts.append(c + Vector2(cos(ang), sin(ang)) * (r - 4.0))
		draw_colored_polygon(pts, Color(0, 0, 0, 0.55))


func _draw_icon(name: String, c: Vector2, r: float, a: float) -> void:
	var w := Color(1, 1, 1, a)
	var o := Color(0.1, 0.1, 0.3, a)
	var u := r / 80.0
	match name:
		"jump":
			var pts := PackedVector2Array([
				c + Vector2(0, -44) * u, c + Vector2(38, -2) * u, c + Vector2(15, -2) * u, c + Vector2(15, 40) * u,
				c + Vector2(-15, 40) * u, c + Vector2(-15, -2) * u, c + Vector2(-38, -2) * u])
			draw_colored_polygon(pts, w)
			var closed := pts.duplicate()
			closed.append(pts[0])
			draw_polyline(closed, o, 4.0, true)
		"slide":
			var s := u * 1.35
			draw_circle(c + Vector2(-20, -26) * s, 11 * s, w)
			draw_line(c + Vector2(-16, -14) * s, c + Vector2(8, 12) * s, w, 11 * s, true)
			draw_line(c + Vector2(8, 12) * s, c + Vector2(32, 18) * s, w, 10 * s, true)
			draw_line(c + Vector2(-8, -6) * s, c + Vector2(16, -14) * s, w, 8 * s, true)
			draw_line(c + Vector2(-34, 30) * s, c + Vector2(34, 30) * s, Color(1, 1, 1, 0.55 * a), 5 * s, true)
		"punch":
			var s2 := u * 1.25
			draw_rect(Rect2(c + Vector2(-26, -8) * s2, Vector2(52, 38) * s2), w, true)
			for i in range(4):
				draw_circle(c + Vector2(-19.5 + 13.0 * float(i), -12) * s2, 8.2 * s2, w)
			draw_circle(c + Vector2(-26, 14) * s2, 9 * s2, w)
			for i in range(1, 4):
				draw_line(c + Vector2(-26 + 13.0 * float(i), -12) * s2, c + Vector2(-26 + 13.0 * float(i), 0) * s2, Color(0.55, 0.1, 0.15, a), 2.5)
			draw_rect(Rect2(c + Vector2(-28, 32) * s2, Vector2(56, 10) * s2), Color(0.95, 0.9, 0.9, a), true)
		"special":
			var s3 := u * 1.2
			var bolt := PackedVector2Array([
				c + Vector2(6, -44) * s3, c + Vector2(-26, 6) * s3, c + Vector2(-4, 6) * s3,
				c + Vector2(-12, 44) * s3, c + Vector2(28, -10) * s3, c + Vector2(4, -10) * s3])
			draw_colored_polygon(bolt, Color("ffe14a") if a > 0.9 else Color(1, 0.88, 0.3, a))
			var cb := bolt.duplicate()
			cb.append(bolt[0])
			draw_polyline(cb, Color(0.25, 0.1, 0.4, a), 3.5, true)
