class_name SettingsPanel
extends Control
## شاشة الإعدادات: الصورة المرجعية كخلفية فنية + عناصر Godot حقيقية فوقها للقيم المتغيّرة.
## كل ما لم يُطوَّر بعد معتَّم بوسم «غير متاح حاليًا».

signal closed

const W := 1672.0
const H := 941.0
const TAG_TEXT := "غير متاح حاليًا"
const C_ROW := Color("143a94")
const C_ROW_EDGE := Color("2f6fe0")
const BG := preload("res://assets/ui/settings_ref.png")

var _root: Control
var _bg_img: Image
var _q_buttons: Array[Button] = []
var _sens_label: Label
var _sfx_label: Label
var _tog: Panel
var _tog_knob: Panel
var _tog_lbl: Label
var _adv: Control
var _toggles: Dictionary = {}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	var back := ColorRect.new()
	back.color = Color("0b1d55")
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(back)
	_bg_img = BG.get_image()

	var vp := get_viewport_rect().size
	var s := minf(vp.x / W, vp.y / H)
	_root = Control.new()
	_root.size = Vector2(W, H)
	_root.scale = Vector2(s, s)
	_root.position = (vp - Vector2(W, H) * s) * 0.5
	add_child(_root)

	var bg := TextureRect.new()
	bg.texture = BG
	bg.size = Vector2(W, H)
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bg)

	# زر الإغلاق (✕ مرسومة في الصورة)
	var x := Button.new()
	x.flat = true
	x.position = Vector2(1560, 18)
	x.size = Vector2(92, 92)
	x.focus_mode = Control.FOCUS_NONE
	x.pressed.connect(_close)
	_root.add_child(x)

	_build_controls()
	_build_nav()
	_build_advanced()
	_refresh()


func _close() -> void:
	Settings.save_settings()
	closed.emit()
	queue_free()


## يغطي منطقة من الصورة بخلفية الصف نفسها (شريط عمودي بكسل واحد يُمدَّد أفقيًا).
func _patch(r: Rect2) -> void:
	var img := Image.create(1, int(r.size.y), false, Image.FORMAT_RGBA8)
	for i in range(int(r.size.y)):
		img.set_pixel(0, i, _bg_img.get_pixel(950, int(r.position.y) + i))
	var tr := TextureRect.new()
	tr.texture = ImageTexture.create_from_image(img)
	tr.position = r.position
	tr.size = r.size
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(tr)


func _slider_row(cy: float, val: float, mn: float, mx: float, cb: Callable) -> Label:
	_patch(Rect2(958, cy - 32, 472, 64))
	_patch(Rect2(1440, cy - 28, 100, 56))
	var sl := HSlider.new()
	sl.min_value = mn
	sl.max_value = mx
	sl.step = 0.05
	sl.value = val
	sl.position = Vector2(975, cy - 30)
	sl.size = Vector2(430, 60)
	_style_slider(sl)
	sl.value_changed.connect(cb)
	_root.add_child(sl)
	var l := _lbl(_root, "", Rect2(1440, cy - 30, 100, 60), 44, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 5)
	return l


func _build_controls() -> void:
	_sfx_label = _slider_row(218, Settings.sfx_volume, 0.0, 1.0, func(v: float):
		Settings.sfx_volume = v
		_refresh()
		Settings.save_settings())
	_sens_label = _slider_row(578, Settings.steer_sensitivity, 0.5, 1.6, func(v: float):
		Settings.steer_sensitivity = v
		_refresh()
		Settings.save_settings())

	# الموسيقى (غير متاحة)
	_unavailable(_root, Rect2(958, 276, 582, 60), 26)

	# جودة الرسوم: أزرار حقيقية فوق منطقة الأزرار المرسومة
	_patch(Rect2(922, 352, 636, 90))
	var names := ["منخفضة", "متوسطة", "عالية"]
	var xs := [930, 1087, 1243]
	for i in range(3):
		var b := _btn(_root, names[i], Rect2(xs[i], 366, 142, 64), Color("0a3a9a"), Color("062a7a"), 32, Color("2f8cff"))
		var qi := i
		b.pressed.connect(func():
			Settings.set_quality(qi)
			Settings.save_settings()
			_refresh())
		_q_buttons.append(b)
	var hd := _btn(_root, "HD", Rect2(1397, 366, 146, 64), Color("3b4470"), Color("2a3258"), 34, Color("6b74a8"))
	hd.disabled = true
	_unavailable(_root, Rect2(1397, 366, 146, 64), 17)

	# اللغة (غير متاحة)
	_unavailable(_root, Rect2(1027, 462, 418, 62), 24)

	# الاهتزاز: مفتاح حقيقي
	_patch(Rect2(1105, 626, 240, 76))
	_tog = _box(_root, Rect2(1117, 635, 208, 58), Color("1fa83a"), Color("c8ffd0"), 29, 3)
	_tog_lbl = _lbl(_tog, "", Rect2(0, 0, 150, 58), 30, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 4)
	_tog_knob = _box(_tog, Rect2(150, 4, 50, 50), Color.WHITE, Color("d6dcef"), 25, 2)
	var tb := Button.new()
	tb.flat = true
	tb.position = _tog.position
	tb.size = _tog.size
	tb.focus_mode = Control.FOCUS_NONE
	tb.pressed.connect(func():
		Settings.vibration = not Settings.vibration
		Settings.save_settings()
		_refresh())
	_root.add_child(tb)

	# أداء اللعبة (غير متاح)
	_unavailable(_root, Rect2(910, 726, 628, 100), 30)


func _build_nav() -> void:
	var ys := [355.0, 462.0, 570.0]
	for y in ys:
		_unavailable(_root, Rect2(20, y, 250, 88), 16, 30.0)
	var adv := _btn(_root, "خيارات متقدمة", Rect2(18, 800, 255, 64), UiKit.C_PURPLE_TOP, UiKit.C_PURPLE_BOT, 28)
	adv.pressed.connect(func(): _adv.visible = true)
	var reset := _btn(_root, "استعادة الافتراضي", Rect2(18, 874, 255, 56), UiKit.C_BLUE_TOP, UiKit.C_BLUE_BOT, 24)
	reset.pressed.connect(func():
		Settings.reset_defaults()
		_refresh())


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
		var b := _q_buttons[i]
		if Settings.quality == i:
			_style_btn(b, UiKit.C_GOLD_TOP, UiKit.C_GOLD_BOT, Color("fff0a0"))
		else:
			_style_btn(b, Color("0a3a9a"), Color("062a7a"), Color("2f8cff"))
	var on := Settings.vibration
	_tog.add_theme_stylebox_override("panel", _tog_style(Color("1fa83a") if on else Color("525775"), Color("c8ffd0") if on else Color("aab0cc")))
	_tog_lbl.text = "مفعّل" if on else "متوقف"
	_tog_lbl.position.x = 0.0 if on else 58.0
	_tog_knob.position.x = 150.0 if on else 8.0
	for key in _toggles:
		_set_toggle(_toggles[key], bool(Settings.get(key)))
	_sens_label.text = "%d%%" % int(round(Settings.steer_sensitivity * 100.0))
	_sfx_label.text = "%d%%" % int(round(Settings.sfx_volume * 100.0))


func _tog_style(fill: Color, edge: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = edge
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(29)
	sb.anti_aliasing = true
	return sb


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
