class_name SettingsPanel
extends Control
## لوحة الإعدادات: جودة الرسومات، حساسية التحكم، الاهتزاز، عداد الأداء، التخفيف التلقائي، الاستعادة.

signal closed

var _q_buttons: Array[Button] = []
var _sens_label: Label
var _toggles: Dictionary = {}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.12, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var vp := get_viewport_rect().size
	var pw := minf(vp.x - 80.0, 880.0)
	var ph := minf(vp.y - 40.0, 620.0)
	var p := UiKit.panel(Vector2(pw, ph))
	p.position = (vp - p.size) * 0.5
	add_child(p)

	var title := UiKit.label("الإعدادات", 40, Color("ffd23a"))
	title.size = Vector2(pw, 60)
	title.position = Vector2(0, 14)
	p.add_child(title)

	var y := 92.0
	# --- جودة الرسومات
	var ql := UiKit.label("جودة الرسومات", 28, Color.WHITE, 5, HORIZONTAL_ALIGNMENT_RIGHT)
	ql.size = Vector2(pw - 60, 40)
	ql.position = Vector2(0, y)
	p.add_child(ql)
	var names := ["منخفضة", "متوسطة", "عالية"]
	for i in range(3):
		var b := UiKit.button(names[i], UiKit.C_BLUE_TOP, UiKit.C_BLUE_BOT, Vector2(190, 58), 26)
		b.position = Vector2(60 + i * 205, y - 4)
		b.size = Vector2(190, 58)
		var qi := i
		b.pressed.connect(func(): _set_quality(qi))
		p.add_child(b)
		_q_buttons.append(b)
	y += 70
	var hint := UiKit.label("المنخفضة أخفّ على الهواتف المتوسطة (دقة أقل، بلا ظلال، ديكور أقل).", 20, Color("c9d6ff"), 3, HORIZONTAL_ALIGNMENT_RIGHT)
	hint.size = Vector2(pw - 60, 30)
	hint.position = Vector2(0, y)
	p.add_child(hint)
	y += 40

	# --- الحساسية
	var sl := UiKit.label("حساسية التوجيه", 28, Color.WHITE, 5, HORIZONTAL_ALIGNMENT_RIGHT)
	sl.size = Vector2(pw - 60, 40)
	sl.position = Vector2(0, y)
	p.add_child(sl)
	var slider := HSlider.new()
	slider.min_value = 0.5
	slider.max_value = 1.6
	slider.step = 0.05
	slider.value = Settings.steer_sensitivity
	slider.size = Vector2(430, 36)
	slider.position = Vector2(60, y + 6)
	_style_slider(slider)
	slider.value_changed.connect(func(v: float):
		Settings.steer_sensitivity = v
		_sens_label.text = "%d%%" % int(v * 100.0)
		Settings.save_settings())
	p.add_child(slider)
	_sens_label = UiKit.label("%d%%" % int(Settings.steer_sensitivity * 100.0), 26, Color("ffd23a"))
	_sens_label.size = Vector2(90, 40)
	_sens_label.position = Vector2(500, y)
	p.add_child(_sens_label)
	y += 56

	# --- مفاتيح
	_add_toggle(p, "اهتزاز اللمس", "vibration", y, pw)
	y += 50
	_add_toggle(p, "عرض عدّاد الأداء (FPS)", "show_fps", y, pw)
	y += 50
	_add_toggle(p, "تخفيف الرسومات تلقائيًا عند الثقل", "auto_quality", y, pw)
	y += 50
	_add_toggle(p, "حلبة الغابة التجريبية (بريميوم)", "premium_track", y, pw)
	y += 50
	_add_toggle(p, "حلبة التفرعات متعددة الارتفاعات (تجريبي)", "branch_track", y, pw)

	var reset := UiKit.button("استعادة الافتراضي", UiKit.C_BLUE_TOP, UiKit.C_BLUE_BOT, Vector2(300, 62), 26)
	reset.position = Vector2(40, ph - 88)
	reset.pressed.connect(func():
		Settings.reset_defaults()
		_refresh())
	p.add_child(reset)
	var close := UiKit.button("حفظ وإغلاق", UiKit.C_GREEN_TOP, UiKit.C_GREEN_BOT, Vector2(300, 62), 28)
	close.position = Vector2(pw - 340, ph - 88)
	close.pressed.connect(func():
		Settings.save_settings()
		closed.emit()
		queue_free())
	p.add_child(close)
	_refresh()


func _add_toggle(p: Control, text: String, key: String, y: float, pw: float) -> void:
	var l := UiKit.label(text, 26, Color.WHITE, 5, HORIZONTAL_ALIGNMENT_RIGHT)
	l.size = Vector2(pw - 60, 44)
	l.position = Vector2(0, y)
	p.add_child(l)
	var b := UiKit.button("", UiKit.C_GREEN_TOP, UiKit.C_GREEN_BOT, Vector2(150, 50), 24)
	b.size = Vector2(150, 50)
	b.position = Vector2(60, y - 2)
	b.pressed.connect(func():
		Settings.set(key, not Settings.get(key))
		Settings.save_settings()
		_refresh())
	p.add_child(b)
	_toggles[key] = b


func _set_quality(q: int) -> void:
	Settings.set_quality(q)
	Settings.save_settings()
	_refresh()


func _refresh() -> void:
	for i in range(_q_buttons.size()):
		var on := Settings.quality == i
		var b := _q_buttons[i]
		var top := UiKit.C_GOLD_TOP if on else UiKit.C_BLUE_TOP
		var bot := UiKit.C_GOLD_BOT if on else UiKit.C_BLUE_BOT
		b.add_theme_stylebox_override("normal", UiKit.style(top, bot))
		b.add_theme_stylebox_override("hover", UiKit.style(top.lightened(0.1), bot.lightened(0.1)))
		b.add_theme_stylebox_override("pressed", UiKit.style(top.darkened(0.1), bot.darkened(0.1)))
	for key in _toggles:
		var b2: Button = _toggles[key]
		var on2: bool = bool(Settings.get(key))
		b2.text = "مفعّل" if on2 else "متوقف"
		var t2 := UiKit.C_GREEN_TOP if on2 else Color("8a8fa8")
		var bt2 := UiKit.C_GREEN_BOT if on2 else Color("525775")
		b2.add_theme_stylebox_override("normal", UiKit.style(t2, bt2))
		b2.add_theme_stylebox_override("hover", UiKit.style(t2.lightened(0.1), bt2.lightened(0.1)))
		b2.add_theme_stylebox_override("pressed", UiKit.style(t2.darkened(0.1), bt2.darkened(0.1)))


static func _knob_texture() -> ImageTexture:
	var img := Image.create(44, 44, false, Image.FORMAT_RGBA8)
	for yy in range(44):
		for xx in range(44):
			var d := Vector2(xx - 21.5, yy - 21.5).length()
			if d < 21.0:
				var c := Color("ffd23a") if d < 15.0 else Color.WHITE
				if yy < 18 and d < 12.0:
					c = Color("fff0a0")
				img.set_pixel(xx, yy, c)
	return ImageTexture.create_from_image(img)


func _style_slider(s: HSlider) -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = Color("0b1245")
	track.set_corner_radius_all(10)
	track.content_margin_top = 9
	track.content_margin_bottom = 9
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("ffb21a")
	fill.set_corner_radius_all(10)
	fill.content_margin_top = 9
	fill.content_margin_bottom = 9
	s.add_theme_stylebox_override("slider", track)
	s.add_theme_stylebox_override("grabber_area", fill)
	s.add_theme_stylebox_override("grabber_area_highlight", fill)
	var tex := _knob_texture()
	s.add_theme_icon_override("grabber", tex)
	s.add_theme_icon_override("grabber_highlight", tex)
	s.add_theme_icon_override("grabber_disabled", tex)
