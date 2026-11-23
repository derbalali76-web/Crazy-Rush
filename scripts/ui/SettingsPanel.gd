class_name SettingsPanel
extends Control
## شاشة الإعدادات بتخطيط المرجع البصري (إحداثيات مرجعية 1672×941 تُحجَّم لتناسب الشاشة).
## كل ما لم يُطوَّر بعد يظهر معطّلًا بوسم «غير متاح حاليًا».

signal closed

const W := 1672.0
const H := 941.0
const TAG_TEXT := "غير متاح حاليًا"
const C_ROW := Color("143a94")
const C_ROW_EDGE := Color("2f6fe0")
const C_BTN := Color("17358a")
const C_BTN_EDGE := Color("2f6fe0")

var _root: Control
var _q_buttons: Array[Button] = []
var _sens_label: Label
var _sfx_label: Label
var _vib_btn: Button
var _adv: Control
var _toggles: Dictionary = {}


## رسم أيقونات بسيطة بالأوليات (بدون صور).
class Icon extends Control:
	var kind := ""
	var col := Color.WHITE

	func _init(k: String, c := Color.WHITE, sz := 64.0) -> void:
		kind = k
		col = c
		custom_minimum_size = Vector2(sz, sz)
		size = Vector2(sz, sz)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var s := size.x
		var c := Vector2(s, s) * 0.5
		var lw := maxf(3.0, s * 0.07)
		match kind:
			"speaker":
				draw_colored_polygon(PackedVector2Array([Vector2(.12, .4) * s, Vector2(.32, .4) * s, Vector2(.55, .2) * s, Vector2(.55, .8) * s, Vector2(.32, .6) * s, Vector2(.12, .6) * s]), col)
				draw_arc(Vector2(.55, .5) * s, s * .18, -0.9, 0.9, 12, col, lw)
				draw_arc(Vector2(.55, .5) * s, s * .32, -0.9, 0.9, 12, col, lw)
			"note":
				draw_circle(Vector2(.3, .75) * s, s * .13, col)
				draw_line(Vector2(.42, .75) * s, Vector2(.42, .2) * s, col, lw)
				draw_line(Vector2(.42, .2) * s, Vector2(.8, .3) * s, col, lw * 1.6)
				draw_circle(Vector2(.68, .66) * s, s * .13, col)
				draw_line(Vector2(.8, .66) * s, Vector2(.8, .3) * s, col, lw)
			"monitor":
				draw_rect(Rect2(Vector2(.1, .15) * s, Vector2(.8, .52) * s), col, false, lw)
				draw_rect(Rect2(Vector2(.14, .19) * s, Vector2(.72, .44) * s), col.darkened(0.25))
				draw_line(Vector2(.5, .67) * s, Vector2(.5, .84) * s, col, lw)
				draw_line(Vector2(.3, .86) * s, Vector2(.7, .86) * s, col, lw)
			"globe":
				draw_arc(c, s * .38, 0, TAU, 32, col, lw)
				draw_arc(c, s * .17, 0, TAU, 24, col, lw * .7)
				draw_line(Vector2(.12, .5) * s, Vector2(.88, .5) * s, col, lw * .7)
				draw_line(Vector2(.5, .12) * s, Vector2(.5, .88) * s, col, lw * .7)
			"target":
				draw_arc(c, s * .36, 0, TAU, 32, col, lw)
				draw_arc(c, s * .16, 0, TAU, 24, col, lw)
				draw_line(Vector2(.5, .05) * s, Vector2(.5, .25) * s, col, lw)
				draw_line(Vector2(.5, .75) * s, Vector2(.5, .95) * s, col, lw)
				draw_line(Vector2(.05, .5) * s, Vector2(.25, .5) * s, col, lw)
				draw_line(Vector2(.75, .5) * s, Vector2(.95, .5) * s, col, lw)
			"phone":
				draw_rect(Rect2(Vector2(.3, .1) * s, Vector2(.4, .8) * s), col, false, lw)
				draw_line(Vector2(.42, .8) * s, Vector2(.58, .8) * s, col, lw)
				draw_line(Vector2(.15, .35) * s, Vector2(.15, .65) * s, col, lw)
				draw_line(Vector2(.85, .35) * s, Vector2(.85, .65) * s, col, lw)
			"gauge":
				draw_arc(Vector2(.5, .62) * s, s * .38, PI * 0.9, PI * 2.1, 24, col, lw)
				draw_line(Vector2(.5, .62) * s, Vector2(.7, .4) * s, col, lw * 1.3)
				draw_circle(Vector2(.5, .62) * s, s * .06, col)
			"gear":
				for i in range(8):
					var a := TAU * i / 8.0
					draw_line(c + Vector2(cos(a), sin(a)) * s * .26, c + Vector2(cos(a), sin(a)) * s * .44, col, s * .16)
				draw_circle(c, s * .32, col)
				draw_circle(c, s * .13, Color(0.2, 0.1, 0.0, 0.75))
			"user":
				draw_circle(Vector2(.5, .32) * s, s * .18, col)
				draw_circle(Vector2(.5, .86) * s, s * .34, col)
			"question":
				draw_arc(Vector2(.5, .34) * s, s * .2, PI, PI * 2.6, 20, col, lw * 1.4)
				draw_line(Vector2(.5, .54) * s, Vector2(.5, .64) * s, col, lw * 1.4)
				draw_circle(Vector2(.5, .8) * s, s * .07, col)
			"info":
				draw_arc(c, s * .4, 0, TAU, 32, col, lw)
				draw_circle(Vector2(.5, .28) * s, s * .06, col)
				draw_line(Vector2(.5, .42) * s, Vector2(.5, .74) * s, col, lw * 1.4)
			"x":
				draw_line(Vector2(.22, .22) * s, Vector2(.78, .78) * s, col, lw * 2.0)
				draw_line(Vector2(.78, .22) * s, Vector2(.22, .78) * s, col, lw * 2.0)
			"check":
				draw_circle(c, s * .5, Color("36c24a"))
				draw_arc(c, s * .5, 0, TAU, 24, Color.WHITE, lw * .8)
				draw_polyline(PackedVector2Array([Vector2(.25, .52) * s, Vector2(.43, .7) * s, Vector2(.76, .3) * s]), Color.WHITE, lw * 1.4)


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.05, 0.22, 0.86)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var vp := get_viewport_rect().size
	var s := minf(vp.x / W, vp.y / H)
	_root = Control.new()
	_root.size = Vector2(W, H)
	_root.scale = Vector2(s, s)
	_root.position = (vp - Vector2(W, H) * s) * 0.5
	add_child(_root)

	_build_header()
	_build_nav()
	_build_rows()
	_build_advanced()
	_refresh()


# ---------------------------------------------------------------- عناصر عامة
func _box(parent: Control, r: Rect2, fill: Color, edge: Color, radius := 28, bw := 4) -> Panel:
	var p := Panel.new()
	p.position = r.position
	p.size = r.size
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = edge
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(radius)
	sb.anti_aliasing = true
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
	return p


func _lbl(parent: Control, text: String, r: Rect2, size := 38, color := Color.WHITE, align := HORIZONTAL_ALIGNMENT_CENTER, outline := 6) -> Label:
	var l := UiKit.label(text, size, color, outline, align)
	l.position = r.position
	l.size = r.size
	parent.add_child(l)
	return l


func _icon(parent: Control, kind: String, center: Vector2, sz := 64.0, col := Color.WHITE) -> Icon:
	var ic := Icon.new(kind, col, sz)
	ic.position = center - Vector2(sz, sz) * 0.5
	parent.add_child(ic)
	return ic


func _btn(parent: Control, text: String, r: Rect2, top: Color, bottom: Color, fsize := 36, edge := Color("ffe27a")) -> Button:
	var b := Button.new()
	b.text = text
	b.position = r.position
	b.size = r.size
	b.add_theme_font_override("font", UiKit.font())
	b.add_theme_font_size_override("font_size", fsize)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color("fff2b0"))
	b.add_theme_color_override("font_outline_color", Color("1a1040"))
	b.add_theme_constant_override("outline_size", 6)
	b.focus_mode = Control.FOCUS_NONE
	_style_btn(b, top, bottom, edge)
	parent.add_child(b)
	return b


func _style_btn(b: Button, top: Color, bottom: Color, edge: Color) -> void:
	var mk := func(t: Color, bt: Color) -> StyleBoxFlat:
		var sb := StyleBoxFlat.new()
		sb.bg_color = t.lerp(bt, 0.5)
		sb.set_corner_radius_all(26)
		sb.border_color = edge
		sb.set_border_width_all(4)
		sb.shadow_color = Color(0, 0, 0, 0.4)
		sb.shadow_size = 6
		sb.shadow_offset = Vector2(0, 4)
		sb.anti_aliasing = true
		sb.content_margin_left = 26
		sb.content_margin_right = 26
		return sb
	b.add_theme_stylebox_override("normal", mk.call(top, bottom))
	b.add_theme_stylebox_override("hover", mk.call(top.lightened(0.1), bottom.lightened(0.1)))
	b.add_theme_stylebox_override("pressed", mk.call(top.darkened(0.12), bottom.darkened(0.12)))
	b.add_theme_stylebox_override("focus", mk.call(top, bottom))
	b.add_theme_stylebox_override("disabled", mk.call(top, bottom))


## تعتيم عنصر + وسم «غير متاح حاليًا» (ويمنع اللمس عليه).
func _unavailable(parent: Control, r: Rect2, fsize := 24, tag_dy := 0.0) -> void:
	var cover := _box(parent, r, Color(0.03, 0.05, 0.2, 0.5), Color(0, 0, 0, 0), 26, 0)
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := minf(r.size.x - 12.0, fsize * 7.2)
	var th := fsize * 1.6
	var tag := _box(parent, Rect2(r.position + Vector2((r.size.x - tw) * 0.5, (r.size.y - th) * 0.5 + tag_dy), Vector2(tw, th)), Color(0.1, 0.12, 0.3, 0.92), Color("8a93c8"), 14, 2)
	var t := UiKit.label(TAG_TEXT, fsize, Color("dfe5ff"), 3)
	t.size = tag.size
	tag.add_child(t)


# ---------------------------------------------------------------- الرأس
func _build_header() -> void:
	_lbl(_root, "CRAZY RUSH", Rect2(40, 40, 520, 110), 78, Color("ffd23a"), HORIZONTAL_ALIGNMENT_LEFT, 12)
	_lbl(_root, "سباق فوكسي المجنون", Rect2(46, 140, 520, 50), 34, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 6)

	var pill := _box(_root, Rect2(735, 22, 625, 112), Color("f08a1c"), Color("ffd23a"), 50, 7)
	_lbl(pill, "الإعدادات", Rect2(0, 8, 625, 96), 70, Color("2a1050"), HORIZONTAL_ALIGNMENT_CENTER, 8)
	_icon(pill, "gear", Vector2(72, 56), 70, Color("ffd23a"))
	_icon(pill, "gear", Vector2(553, 56), 70, Color("ffd23a"))

	var x := _btn(_root, "", Rect2(1562, 20, 86, 86), UiKit.C_RED_TOP, UiKit.C_RED_BOT, 30, Color.WHITE)
	x.add_child(Icon.new("x", Color.WHITE, 86.0))
	x.pressed.connect(_close)


func _close() -> void:
	Settings.save_settings()
	closed.emit()
	queue_free()


# ---------------------------------------------------------------- الشريط الجانبي
func _build_nav() -> void:
	var items := [
		["الإعدادات", "gear", true, true],
		["الحساب", "user", false, false],
		["المساعدة", "question", false, false],
		["حول اللعبة", "info", false, false],
	]
	var y := 245.0
	for it in items:
		var active: bool = it[2]
		var top: Color = UiKit.C_GOLD_TOP if active else UiKit.C_BLUE_TOP
		var bot: Color = UiKit.C_GOLD_BOT if active else UiKit.C_BLUE_BOT
		var b := _btn(_root, it[0], Rect2(18, y, 255, 88), top, bot, 34)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_constant_override("h_separation", 0)
		var ic := Icon.new(it[1], Color.WHITE, 52.0)
		ic.position = Vector2(190, 18)
		b.add_child(ic)
		if not it[3]:
			_unavailable(_root, Rect2(18, y, 255, 88), 16, 30.0)
		y += 106.0
	# خيارات متقدمة (وظيفية) + استعادة الافتراضي
	var adv := _btn(_root, "خيارات متقدمة", Rect2(18, y + 4, 255, 80), UiKit.C_PURPLE_TOP, UiKit.C_PURPLE_BOT, 32)
	adv.pressed.connect(func(): _adv.visible = true)
	var reset := _btn(_root, "استعادة الافتراضي", Rect2(18, y + 100, 255, 80), UiKit.C_BLUE_TOP, UiKit.C_BLUE_BOT, 30)
	reset.pressed.connect(func():
		Settings.reset_defaults()
		_refresh())


# ---------------------------------------------------------------- الصفوف
func _row(y: float, h: float) -> Panel:
	return _box(_root, Rect2(588, y, 970, h), C_ROW, C_ROW_EDGE, 30, 3)


func _build_rows() -> void:
	_box(_root, Rect2(570, 160, 1010, 705), Color("0f2f82"), Color("f3b21c"), 44, 8)

	# المؤثرات الصوتية
	var r1 := _row(180, 80)
	_icon(r1, "speaker", Vector2(60, 40), 62)
	_lbl(r1, "المؤثرات الصوتية", Rect2(112, 0, 280, 80), 36, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 4)
	_make_slider(r1, Vector2(375, 22), 0.0, 1.0, 0.05, Settings.sfx_volume, func(v: float):
		Settings.sfx_volume = v
		_sfx_label.text = "%d%%" % int(round(v * 100.0))
		Settings.save_settings())
	_sfx_label = _lbl(r1, "", Rect2(840, 0, 120, 80), 36, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 4)
	_sfx_label.text = "%d%%" % int(round(Settings.sfx_volume * 100.0))

	# الموسيقى (غير متاحة)
	var r2 := _row(268, 80)
	_icon(r2, "note", Vector2(60, 40), 62)
	_lbl(r2, "الموسيقى", Rect2(112, 0, 280, 80), 36, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 4)
	_make_slider(r2, Vector2(375, 22), 0.0, 1.0, 0.05, 0.6, Callable())
	_lbl(r2, "60%", Rect2(840, 0, 120, 80), 36, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 4)
	_unavailable(r2, Rect2(360, 6, 600, 68), 26)

	# جودة الرسوم
	var r3 := _row(356, 100)
	_icon(r3, "monitor", Vector2(60, 50), 62)
	_lbl(r3, "جودة الرسوم", Rect2(112, 0, 230, 100), 34, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 4)
	var names := ["منخفضة", "متوسطة", "عالية"]
	for i in range(3):
		var b := _btn(r3, names[i], Rect2(345 + i * 152, 18, 142, 64), UiKit.C_BLUE_TOP, UiKit.C_BLUE_BOT, 30)
		var qi := i
		b.pressed.connect(func():
			Settings.set_quality(qi)
			Settings.save_settings()
			_refresh())
		_q_buttons.append(b)
	var hd := _btn(r3, "HD", Rect2(801, 18, 150, 64), Color("5a6290"), Color("3b4470"), 34, Color("8a93c8"))
	_unavailable(r3, Rect2(801, 18, 150, 64), 17)
	hd.disabled = true

	# اللغة (غير متاحة)
	var r4 := _row(464, 80)
	_icon(r4, "globe", Vector2(60, 40), 62)
	_lbl(r4, "اللغة", Rect2(112, 0, 230, 80), 36, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 4)
	var lp := _box(r4, Rect2(440, 10, 420, 60), Color("102b78"), Color("2f6fe0"), 28, 3)
	_lbl(lp, "العربية", Rect2(0, 0, 420, 60), 34)
	_unavailable(r4, Rect2(440, 10, 420, 60), 22)

	# حساسية التحكم
	var r5 := _row(552, 80)
	_icon(r5, "target", Vector2(60, 40), 62)
	_lbl(r5, "حساسية التحكم", Rect2(112, 0, 280, 80), 36, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 4)
	_make_slider(r5, Vector2(375, 22), 0.5, 1.6, 0.05, Settings.steer_sensitivity, func(v: float):
		Settings.steer_sensitivity = v
		_sens_label.text = "%d%%" % int(round(v * 100.0))
		Settings.save_settings())
	_sens_label = _lbl(r5, "", Rect2(840, 0, 120, 80), 36, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 4)
	_sens_label.text = "%d%%" % int(round(Settings.steer_sensitivity * 100.0))

	# الاهتزاز
	var r6 := _row(640, 80)
	_icon(r6, "phone", Vector2(60, 40), 62)
	_lbl(r6, "الاهتزاز", Rect2(112, 0, 280, 80), 36, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 4)
	_vib_btn = _btn(r6, "", Rect2(530, 10, 210, 60), UiKit.C_GREEN_TOP, UiKit.C_GREEN_BOT, 32, Color("c8ffd0"))
	_vib_btn.pressed.connect(func():
		Settings.vibration = not Settings.vibration
		Settings.save_settings()
		_refresh())

	# أداء اللعبة (غير متاح)
	var r7 := _row(728, 124)
	_icon(r7, "gauge", Vector2(60, 62), 66)
	_lbl(r7, "أداء اللعبة", Rect2(112, 0, 230, 124), 36, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 4)
	var modes := ["توفير البطارية", "متوازن", "أداء عالي"]
	for i in range(3):
		var m := _btn(r7, modes[i], Rect2(335 + i * 214, 18, 202, 88), Color("5a6290") if i != 1 else Color("c9a020"), Color("3b4470") if i != 1 else Color("9a7410"), 32, Color("8a93c8"))
		m.disabled = true
	_unavailable(r7, Rect2(335, 18, 630, 88), 28)


func _make_slider(parent: Control, pos: Vector2, mn: float, mx: float, step: float, val: float, cb: Callable) -> HSlider:
	var s := HSlider.new()
	s.min_value = mn
	s.max_value = mx
	s.step = step
	s.value = val
	s.position = pos
	s.size = Vector2(450, 36)
	_style_slider(s)
	if cb.is_valid():
		s.value_changed.connect(cb)
	parent.add_child(s)
	return s


# ---------------------------------------------------------------- خيارات متقدمة
func _build_advanced() -> void:
	_adv = Control.new()
	_adv.visible = false
	_adv.size = Vector2(W, H)
	_root.add_child(_adv)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.03, 0.15, 0.7)
	shade.size = Vector2(W, H)
	_adv.add_child(shade)
	_box(_adv, Rect2(430, 150, 810, 640), Color("0f2f82"), Color("f3b21c"), 44, 8)
	_lbl(_adv, "خيارات متقدمة", Rect2(430, 165, 810, 80), 56, Color("ffd23a"))
	var items := [
		["عرض عدّاد الأداء (FPS)", "show_fps"],
		["تخفيف الرسومات تلقائيًا عند الثقل", "auto_quality"],
		["حلبة الغابة التجريبية (بريميوم)", "premium_track"],
		["حلبة التفرعات متعددة الارتفاعات (تجريبي)", "branch_track"],
	]
	var y := 270.0
	for it in items:
		_box(_adv, Rect2(460, y, 750, 84), C_ROW, C_ROW_EDGE, 28, 3)
		_lbl(_adv, it[0], Rect2(700, y, 490, 84), 30, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT, 4)
		var key: String = it[1]
		var t := _btn(_adv, "", Rect2(480, y + 14, 190, 56), UiKit.C_GREEN_TOP, UiKit.C_GREEN_BOT, 28, Color("c8ffd0"))
		t.pressed.connect(func():
			Settings.set(key, not Settings.get(key))
			Settings.save_settings()
			_refresh())
		_toggles[key] = t
		y += 100.0
	var back := _btn(_adv, "رجوع", Rect2(660, 690, 350, 80), UiKit.C_GREEN_TOP, UiKit.C_GREEN_BOT, 40, Color.WHITE)
	back.pressed.connect(func(): _adv.visible = false)


# ---------------------------------------------------------------- تحديث الحالة
func _refresh() -> void:
	for i in range(_q_buttons.size()):
		var on := Settings.quality == i
		var b := _q_buttons[i]
		if on:
			_style_btn(b, UiKit.C_GOLD_TOP, UiKit.C_GOLD_BOT, Color("fff0a0"))
		else:
			_style_btn(b, C_BTN, C_BTN, C_BTN_EDGE)
		for ch in b.get_children():
			if ch is Icon:
				ch.queue_free()
		if on:
			var ck := Icon.new("check", Color.WHITE, 40.0)
			ck.position = Vector2(b.size.x - 30, -14)
			b.add_child(ck)
	_set_toggle(_vib_btn, Settings.vibration)
	for key in _toggles:
		_set_toggle(_toggles[key], bool(Settings.get(key)))
	_sens_label.text = "%d%%" % int(round(Settings.steer_sensitivity * 100.0))
	_sfx_label.text = "%d%%" % int(round(Settings.sfx_volume * 100.0))


func _set_toggle(b: Button, on: bool) -> void:
	b.text = "مفعّل" if on else "متوقف"
	if on:
		_style_btn(b, UiKit.C_GREEN_TOP, UiKit.C_GREEN_BOT, Color("c8ffd0"))
	else:
		_style_btn(b, Color("8a8fa8"), Color("525775"), Color("c0c6e0"))


static func _knob_texture() -> ImageTexture:
	var n := 60
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c := (n - 1) * 0.5
	for yy in range(n):
		for xx in range(n):
			var d := Vector2(xx - c, yy - c).length()
			if d < 29.0:
				var col := Color("ffc21a") if d < 22.0 else Color.WHITE
				if yy < 24 and d < 17.0:
					col = Color("fff0a0")
				img.set_pixel(xx, yy, col)
	return ImageTexture.create_from_image(img)


func _style_slider(s: HSlider) -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = Color("0b1245")
	track.set_corner_radius_all(14)
	track.content_margin_top = 14
	track.content_margin_bottom = 14
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("ffb21a")
	fill.set_corner_radius_all(14)
	fill.content_margin_top = 14
	fill.content_margin_bottom = 14
	s.add_theme_stylebox_override("slider", track)
	s.add_theme_stylebox_override("grabber_area", fill)
	s.add_theme_stylebox_override("grabber_area_highlight", fill)
	var tex := _knob_texture()
	s.add_theme_icon_override("grabber", tex)
	s.add_theme_icon_override("grabber_highlight", tex)
	s.add_theme_icon_override("grabber_disabled", tex)
