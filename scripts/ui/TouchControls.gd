class_name TouchControls
extends Control
## أدوات التحكم: سحب أفقي في أي مكان من الشاشة = توجيه، سحب لأعلى = قفز، لأسفل = انزلاق. يظهر زرّان فقط: اللكمة والقدرة الخاصة.
## يدعم اللمس المتعدد (كل إصبع له معرّف مستقل) فلا تتداخل الإيماءات. وعلى الحاسوب: لوحة المفاتيح.

var input: RunnerInput
var punch_cd := 0.0          # 0..1 المتبقي
var special_cd := 0.0        # 0..1 المتبقي
var punch_total := 0.5       # مدة انتظار اللكمة الكاملة بالثواني (لعرض الثواني المتبقية)
var special_total := 7.0     # مدة انتظار القدرة الخاصة بالثواني
var special_enabled := true
var sensitivity := 1.0
var enabled := true

const PAD_RADIUS := 92.0   # نصف قطر منطقة التوجيه الافتراضية (بكسل) — غير مرسومة
const SWIPE_PX := 55.0

var _pad_touch := -1
var _pad_anchor := Vector2.ZERO
var _steer_y0 := 0.0
var _flick := 0.0
var _last_x := 0.0
var _pad_pos := Vector2.ZERO
var _btn_touch: Dictionary = {}     # index -> اسم الزر
var _gest: Dictionary = {}          # index -> {start, t, done}
var _pressed: Dictionary = {}       # اسم الزر -> عدد اللمسات
var _kb_steer := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_PAUSABLE


func _vp() -> Vector2:
	return get_viewport().get_visible_rect().size


func _btn_defs() -> Dictionary:
	var sz := _vp()
	return {
		"punch": {"c": Vector2(sz.x - 120, sz.y - 120), "r": 78.0},
		"special": {"c": Vector2(sz.x - 290, sz.y - 96), "r": 60.0},
	}


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
		if pos.distance_to(d.c) <= d.r * 1.25:
			_btn_touch[idx] = name
			_pressed[name] = int(_pressed.get(name, 0)) + 1
			match name:
				"punch": input.punch = true
				"special":
					if special_cd <= 0.0 and special_enabled:
						input.special = true
			return
	# أي مكان آخر على الشاشة: إصبع التوجيه (الأول فقط). حركة أفقية = توجيه، سحب لأعلى/أسفل = قفز/انزلاق.
	if _pad_touch == -1:
		_pad_touch = idx
		_last_x = pos.x
		_flick = 0.0
		_pad_anchor = pos
		_pad_pos = pos
		_steer_y0 = pos.y
		_update_steer()


func _move(idx: int, pos: Vector2) -> void:
	if idx != _pad_touch:
		return
	# ضربة سريعة (Flick) تعطي دفعة توجيه فورية إضافية تتلاشى سريعًا
	var vx := pos.x - _last_x
	_last_x = pos.x
	_flick = clampf(_flick * 0.6 + vx / 90.0, -0.45, 0.45)
	_pad_pos = pos
	# المرساة تلحق الإصبع كي يستجيب عكس الاتجاه فورًا
	var lim := _range()
	_pad_anchor.x = clampf(_pad_anchor.x, pos.x - lim, pos.x + lim)
	_update_steer()
	var dy := pos.y - _steer_y0
	if dy < -SWIPE_PX:
		input.jump = true
		_steer_y0 = pos.y
	elif dy > SWIPE_PX:
		input.slide = true
		_steer_y0 = pos.y
	else:
		# اسمح بإعادة الإيماءة عند تغيير الاتجاه العمودي
		if dy > 0.0 and pos.y < _steer_y0:
			_steer_y0 = pos.y
		elif dy < 0.0 and pos.y > _steer_y0:
			_steer_y0 = pos.y


func _up(idx: int, _pos: Vector2) -> void:
	if idx == _pad_touch:
		_pad_touch = -1
		input.steer = 0.0
	if _btn_touch.has(idx):
		var n: String = _btn_touch[idx]
		_pressed[n] = maxi(int(_pressed.get(n, 1)) - 1, 0)
		_btn_touch.erase(idx)


## المسافة (بكسل) التي تعطي أقصى توجيه. السحب القصير = حركة خفيفة، والسحب الطويل = حركة قوية.
func _range() -> float:
	return 190.0 / clampf(sensitivity, 0.4, 1.8)


func _update_steer() -> void:
	var dx := (_pad_pos.x - _pad_anchor.x) / _range()
	var v := clampf(dx, -1.0, 1.0)
	if absf(v) < 0.02:
		v = 0.0
	input.steer = clampf(v + _flick, -1.0, 1.0)


func _process(delta: float) -> void:
	if not enabled or input == null:
		return
	if absf(_flick) > 0.001 and _pad_touch != -1:
		_flick = move_toward(_flick, 0.0, delta * 2.2)
		_update_steer()
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
	var defs := _btn_defs()
	for name in defs:
		_draw_button(name, defs[name])


func _draw_button(name: String, d: Dictionary) -> void:
	var c: Vector2 = d.c
	var r: float = d.r
	var down := int(_pressed.get(name, 0)) > 0
	if down:
		r *= 0.93
	var top := Color("4aa3ff")
	var bot := Color("1f4fd0")
	var glow := Color("7ab8ff")
	match name:
		"slide":
			top = Color("5a6aa8"); bot = Color("2a3470")
		"punch":
			top = Color("ff7a5c"); bot = Color("a3101c"); glow = Color("ffb08a")
		"special":
			top = Color("c58bff"); bot = Color("4a1fb8"); glow = Color("e2c4ff")
	var cd := 0.0
	var usable := true
	if name == "punch":
		cd = punch_cd
	elif name == "special":
		cd = special_cd
		usable = special_enabled
	var alpha := 1.0 if usable else 0.45
	var ready := usable and cd <= 0.0
	var tm := float(Time.get_ticks_msec()) / 1000.0
	# ظل سفلي ناعم
	draw_circle(c + Vector2(0, 9), r + 5.0, Color(0, 0, 0, 0.16))
	draw_circle(c + Vector2(0, 6), r + 3.0, Color(0, 0, 0, 0.30))
	# هالة نبض عندما يكون الزر جاهزًا
	if ready and not down:
		var pulse := 0.5 + 0.5 * sin(tm * 3.2)
		draw_arc(c, r + 7.0 + pulse * 3.0, 0.0, TAU, 48, Color(glow.r, glow.g, glow.b, 0.22 + 0.18 * pulse), 4.0, true)
	# حلقة معدنية خارجية: ذهبي/فضي متدرج
	draw_circle(c, r + 3.0, Color("2a1a3a", alpha))
	draw_circle(c, r + 1.0, Color("f4e7c0", alpha))
	draw_circle(c + Vector2(0, 2), r - 1.0, Color("a8803a", alpha))
	draw_circle(c, r - 3.5, Color("2b1650", alpha))
	# جسم الزر: تدرج لوني شعاعي بتراكب دوائر
	var steps := 12
	for i in range(steps):
		var k := float(i) / float(steps - 1)
		var col := bot.lerp(top, pow(k, 0.8))
		var rr := (r - 6.0) * (1.0 - 0.62 * k)
		draw_circle(c + Vector2(0, -r * 0.22 * k), rr, Color(col.r, col.g, col.b, alpha))
	# لمعة زجاجية علوية
	var hl := PackedVector2Array()
	for i in range(0, 25):
		var ang := PI + PI * float(i) / 24.0
		hl.append(c + Vector2(cos(ang) * (r - 14.0), sin(ang) * (r - 14.0) * 0.50 - r * 0.28))
	draw_colored_polygon(hl, Color(1, 1, 1, 0.30 * alpha))
	draw_arc(c, r - 8.0, PI * 1.12, PI * 1.88, 24, Color(1, 1, 1, 0.55 * alpha), 3.0, true)
	# ظل داخلي سفلي
	draw_arc(c, r - 8.0, PI * 0.15, PI * 0.85, 24, Color(0, 0, 0, 0.25 * alpha), 4.0, true)
	_draw_icon(name, c, r, alpha)
	if cd > 0.0:
		var pts := PackedVector2Array([c])
		var st := int(48.0 * cd) + 2
		for i in range(st + 1):
			var ang2 := -PI * 0.5 + TAU * (cd * float(i) / float(st))
			pts.append(c + Vector2(cos(ang2), sin(ang2)) * (r - 5.0))
		draw_colored_polygon(pts, Color(0.05, 0.02, 0.15, 0.62))
		var f := ThemeDB.fallback_font
		var secs := cd * (punch_total if name == "punch" else special_total)
		var txt := "%.1f" % secs
		var fs := int(r * 0.52)
		var tw := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string_outline(f, c + Vector2(-tw * 0.5, fs * 0.34), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 6, Color(0, 0, 0, 0.8))
		draw_string(f, c + Vector2(-tw * 0.5, fs * 0.34), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.95))


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
			var ol := Color(0.30, 0.04, 0.08, a)
			var skin := Color(1, 0.97, 0.94, a)
			var shade := Color(0.93, 0.80, 0.78, a)
			# كفّ القفاز: ظل ثم لون ثم خط خارجي
			draw_rect(Rect2(c + Vector2(-29, -11) * s2, Vector2(58, 44) * s2), ol, true)
			draw_rect(Rect2(c + Vector2(-26, -8) * s2, Vector2(52, 38) * s2), skin, true)
			draw_rect(Rect2(c + Vector2(-26, 16) * s2, Vector2(52, 14) * s2), shade, true)
			for i in range(4):
				var fx := -19.5 + 13.0 * float(i)
				draw_circle(c + Vector2(fx, -12) * s2, 10.4 * s2, ol)
				draw_circle(c + Vector2(fx, -12) * s2, 8.4 * s2, skin)
				draw_circle(c + Vector2(fx + 1.5, -8) * s2, 4.2 * s2, shade)
			draw_circle(c + Vector2(-27, 14) * s2, 11.0 * s2, ol)
			draw_circle(c + Vector2(-27, 14) * s2, 9.0 * s2, skin)
			for i in range(1, 4):
				draw_line(c + Vector2(-26 + 13.0 * float(i), -9) * s2, c + Vector2(-26 + 13.0 * float(i), 2) * s2, Color(0.55, 0.1, 0.15, a), 2.5)
			# حزام المعصم
			draw_rect(Rect2(c + Vector2(-30, 34) * s2, Vector2(60, 12) * s2), ol, true)
			draw_rect(Rect2(c + Vector2(-27, 36) * s2, Vector2(54, 8) * s2), Color(1.0, 0.82, 0.25, a), true)
			# خطوط سرعة
			for k2 in range(3):
				draw_line(c + Vector2(-44, -6 + 12.0 * float(k2)) * s2, c + Vector2(-34 - 4.0 * float(k2), -6 + 12.0 * float(k2)) * s2, Color(1, 1, 1, 0.55 * a), 3.0, true)
		"special":
			var s3 := u * 1.2
			var bolt := PackedVector2Array([
				c + Vector2(6, -44) * s3, c + Vector2(-26, 6) * s3, c + Vector2(-4, 6) * s3,
				c + Vector2(-12, 44) * s3, c + Vector2(28, -10) * s3, c + Vector2(4, -10) * s3])
			# توهج خارجي
			for g in range(3):
				var gp := PackedVector2Array()
				for v in bolt:
					gp.append(c + (v - c) * (1.28 - 0.08 * float(g)))
				draw_colored_polygon(gp, Color(1, 0.9, 0.4, (0.10 + 0.05 * float(g)) * a))
			var cb := bolt.duplicate()
			cb.append(bolt[0])
			draw_colored_polygon(bolt, Color("ffcf2e") if a > 0.9 else Color(1, 0.82, 0.25, a))
			# نصف علوي أفتح لإعطاء حجم
			var half := PackedVector2Array([c + Vector2(6, -44) * s3, c + Vector2(-26, 6) * s3, c + Vector2(-4, 6) * s3, c + Vector2(14, -22) * s3])
			draw_colored_polygon(half, Color(1.0, 0.97, 0.7, a))
			draw_polyline(cb, Color(0.30, 0.08, 0.45, a), 4.0, true)
