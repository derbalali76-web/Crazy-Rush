class_name Hud
extends CanvasLayer
## واجهة السباق: شريط التقدم، الزمن، العملات، العدّ التنازلي، الإيقاف المؤقت، النتائج، عدّاد الأداء.

signal pause_pressed
signal resume_pressed
signal restart_pressed
signal home_pressed

class ProgressView extends Control:
	var value := 0.0
	var rivals: Array = []      # قيم 0..1 للمنافسين
	var rival_colors: Array = []
	func _draw() -> void:
		var w := size.x
		var h := 22.0
		var y := size.y * 0.5 - h * 0.5
		draw_rect(Rect2(0, y + 4, w, h), Color(0, 0, 0, 0.35), true)
		draw_rect(Rect2(0, y, w, h), Color("0e1a52"), true)
		draw_rect(Rect2(0, y, w, h), Color("5aa0ff"), false, 3.0)
		draw_rect(Rect2(3, y + 3, maxf((w - 6.0) * value, 0.0), h - 6), Color("ffc21a"), true)
		draw_rect(Rect2(3, y + 3, maxf((w - 6.0) * value, 0.0), (h - 6) * 0.45), Color("ffe680"), true)
		# علم النهاية
		var fx := w + 4.0
		draw_line(Vector2(fx, y - 12), Vector2(fx, y + h + 6), Color.WHITE, 4.0)
		for i in range(2):
			for j in range(2):
				var cc := Color.WHITE if (i + j) % 2 == 0 else Color.BLACK
				draw_rect(Rect2(fx + 2 + i * 9, y - 12 + j * 9, 9, 9), cc, true)
		for k in range(rivals.size()):
			var rx := 3.0 + (w - 6.0) * clampf(float(rivals[k]), 0.0, 1.0)
			var rc: Color = rival_colors[k] if k < rival_colors.size() else Color.WHITE
			draw_circle(Vector2(rx, y + h * 0.5), 8.0, Color.WHITE)
			draw_circle(Vector2(rx, y + h * 0.5), 6.0, rc)
		# علامة اللاعب (رأس ثعلب مبسّط)
		var px := 3.0 + (w - 6.0) * value
		var c := Vector2(px, y + h * 0.5)
		draw_colored_polygon(PackedVector2Array([c + Vector2(-17, -8), c + Vector2(-11, -28), c + Vector2(-3, -12)]), Color("ff7a18"))
		draw_colored_polygon(PackedVector2Array([c + Vector2(17, -8), c + Vector2(11, -28), c + Vector2(3, -12)]), Color("ff7a18"))
		draw_circle(c + Vector2(0, 2), 19.0, Color.WHITE)
		draw_circle(c + Vector2(0, 2), 16.0, Color("ff7a18"))
		draw_circle(c + Vector2(0, 8), 9.0, Color("fff0d8"))
		draw_circle(c + Vector2(-6, 0), 3.2, Color("14131a"))
		draw_circle(c + Vector2(6, 0), 3.2, Color("14131a"))

var root: Control
var progress_view: ProgressView
var time_label: Label
var coin_label: Label
var rank_label: Label
var coin_icon: Control
var countdown: Label
var toast: Label
var fps_label: Label
var banner: Label
var pause_btn: Button
var controls: TouchControls
var _toast_t := 0.0
var _banner_t := 0.0
var overlay: Control = null


func _init() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build()
	get_viewport().size_changed.connect(_layout)
	_layout()


func _build() -> void:
	controls = TouchControls.new()
	root.add_child(controls)

	progress_view = ProgressView.new()
	progress_view.size = Vector2(520, 60)
	progress_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(progress_view)

	time_label = UiKit.label("00:00.00", 34, Color.WHITE, 7)
	time_label.size = Vector2(170, 54)
	root.add_child(time_label)

	coin_label = UiKit.label("0", 34, Color("ffd23a"), 7)
	coin_label.size = Vector2(90, 54)
	root.add_child(coin_label)
	coin_icon = Control.new()
	coin_icon.size = Vector2(44, 44)
	coin_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coin_icon.draw.connect(func():
		coin_icon.draw_circle(Vector2(22, 24), 21, Color(0, 0, 0, 0.35))
		coin_icon.draw_circle(Vector2(22, 22), 20, Color("c77a08"))
		coin_icon.draw_circle(Vector2(22, 22), 17, Color("ffd23a"))
		coin_icon.draw_circle(Vector2(22, 22), 12, Color("ffb21a"))
		var star := PackedVector2Array()
		for k in range(10):
			var rr := 8.0 if k % 2 == 0 else 3.6
			var a := -PI * 0.5 + TAU * float(k) / 10.0
			star.append(Vector2(22 + cos(a) * rr, 22 + sin(a) * rr))
		coin_icon.draw_colored_polygon(star, Color("fff3a0")))
	root.add_child(coin_icon)

	pause_btn = Button.new()
	pause_btn.size = Vector2(64, 64)
	pause_btn.focus_mode = Control.FOCUS_NONE
	var sb := UiKit.style(Color("4aa3ff"), Color("2456d8"), 32, Color.WHITE, 4)
	sb.content_margin_left = 0
	sb.content_margin_right = 0
	pause_btn.add_theme_stylebox_override("normal", sb)
	pause_btn.add_theme_stylebox_override("hover", sb)
	pause_btn.add_theme_stylebox_override("pressed", UiKit.style(Color("3a82e0"), Color("1a40b0"), 32, Color.WHITE, 4))
	pause_btn.pressed.connect(func(): pause_pressed.emit())
	root.add_child(pause_btn)
	var bars := Control.new()
	bars.size = pause_btn.size
	bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bars.draw.connect(func():
		bars.draw_rect(Rect2(20, 17, 9, 30), Color.WHITE, true)
		bars.draw_rect(Rect2(35, 17, 9, 30), Color.WHITE, true))
	pause_btn.add_child(bars)

	countdown = UiKit.label("", 180, Color("ffd23a"), 18)
	countdown.size = Vector2(900, 260)
	root.add_child(countdown)

	rank_label = UiKit.label("", 46, Color("ffe45a"), 9, HORIZONTAL_ALIGNMENT_LEFT)
	rank_label.size = Vector2(300, 64)
	root.add_child(rank_label)

	banner = UiKit.label("", 54, Color("7dffb0"), 10)
	banner.size = Vector2(800, 80)
	root.add_child(banner)

	toast = UiKit.label("", 28, Color.WHITE, 6)
	toast.size = Vector2(900, 50)
	toast.modulate.a = 0.0
	root.add_child(toast)

	fps_label = UiKit.label("", 17, Color("d8ffd0"), 4, HORIZONTAL_ALIGNMENT_LEFT)
	fps_label.size = Vector2(430, 120)
	fps_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	root.add_child(fps_label)


func _layout() -> void:
	var vp := get_viewport().get_visible_rect().size
	progress_view.position = Vector2((vp.x - 520.0) * 0.5, 14)
	pause_btn.position = Vector2(vp.x - 84, 16)
	time_label.position = Vector2(vp.x - 270, 20)
	coin_label.position = Vector2(vp.x - 365, 20)
	coin_icon.position = Vector2(vp.x - 410, 24)
	countdown.position = Vector2((vp.x - 900.0) * 0.5, vp.y * 0.5 - 200)
	banner.position = Vector2((vp.x - 800.0) * 0.5, vp.y * 0.30)
	toast.position = Vector2((vp.x - 900.0) * 0.5, vp.y * 0.18)
	rank_label.position = Vector2(20, 12)
	fps_label.position = Vector2(14, 84)


func set_rank(rank: int, total: int) -> void:
	rank_label.text = "المركز %d" % rank
	rank_label.add_theme_color_override("font_color", [Color("ffe45a"), Color("e8eef8"), Color("ffb77a")][rank - 1] if rank <= 3 else Color.WHITE)


func set_rivals(values: Array, colors: Array) -> void:
	progress_view.rivals = values
	progress_view.rival_colors = colors


func set_time(t: float) -> void:
	var m := int(t / 60.0)
	var s := fmod(t, 60.0)
	time_label.text = "%02d:%05.2f" % [m, s]


func set_coins(n: int) -> void:
	coin_label.text = "%d" % n


func show_countdown(text: String, color := Color("ffd23a")) -> void:
	countdown.text = text
	countdown.add_theme_color_override("font_color", color)
	countdown.scale = Vector2.ONE * 1.5
	countdown.pivot_offset = countdown.size * 0.5
	countdown.modulate.a = 1.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(countdown, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(countdown, "modulate:a", 0.0, 0.5).set_delay(0.5)


func show_banner(text: String, color := Color("7dffb0")) -> void:
	banner.text = text
	banner.add_theme_color_override("font_color", color)
	_banner_t = 0.9


func show_toast(text: String) -> void:
	toast.text = text
	_toast_t = 2.6


func _process(delta: float) -> void:
	if _toast_t > 0.0:
		_toast_t -= delta
		toast.modulate.a = clampf(_toast_t * 2.0, 0.0, 1.0)
	if _banner_t > 0.0:
		_banner_t -= delta
		banner.modulate.a = clampf(_banner_t * 3.0, 0.0, 1.0)
	elif banner.text != "":
		banner.text = ""
	fps_label.visible = Settings.show_fps


# ------------------------------------------------------------------ نوافذ
func _clear_overlay() -> void:
	if overlay and is_instance_valid(overlay):
		overlay.queue_free()
	overlay = null


func _make_overlay(title: String, w := 620.0, h := 470.0) -> Control:
	_clear_overlay()
	var vp := get_viewport().get_visible_rect().size
	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.15, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var p := UiKit.panel(Vector2(w, h))
	p.position = (vp - p.size) * 0.5
	overlay.add_child(p)
	var t := UiKit.label(title, 44, Color("ffd23a"))
	t.size = Vector2(w, 70)
	t.position = Vector2(0, 16)
	p.add_child(t)
	root.add_child(overlay)
	overlay.set_meta("panel", p)
	return overlay


func show_pause() -> void:
	# نافذة الإيقاف المؤقت بتصميم المرجع (صورة اللوحة + أزرار حقيقية شفافة فوقها)
	_clear_overlay()
	var vp := get_viewport().get_visible_rect().size
	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.15, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var tex: Texture2D = load("res://assets/ui/pause_panel.png")
	var ts := tex.get_size()
	var sc := minf((vp.y * 0.94) / ts.y, (vp.x * 0.9) / ts.x)
	var panel := Control.new()
	panel.size = ts
	panel.scale = Vector2(sc, sc)
	panel.position = (vp - ts * sc) * 0.5
	overlay.add_child(panel)
	var img := TextureRect.new()
	img.texture = tex
	img.size = ts
	img.stretch_mode = TextureRect.STRETCH_SCALE
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	img.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_child(img)
	var items := [
		[Rect2(400, 248, 575, 114), func(): resume_pressed.emit()],
		[Rect2(400, 378, 575, 112), func(): restart_pressed.emit()],
		[Rect2(400, 510, 575, 112), func(): _open_settings()],
		[Rect2(400, 640, 575, 112), func(): home_pressed.emit()],
	]
	for it in items:
		var r: Rect2 = it[0]
		var hl := Panel.new()
		hl.position = r.position
		hl.size = r.size
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(1, 1, 1, 0.22)
		sb.set_corner_radius_all(56)
		hl.add_theme_stylebox_override("panel", sb)
		hl.visible = false
		hl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(hl)
		var b := Button.new()
		b.flat = true
		b.position = r.position
		b.size = r.size
		b.focus_mode = Control.FOCUS_NONE
		b.button_down.connect(func(): hl.visible = true)
		b.button_up.connect(func(): hl.visible = false)
		b.pressed.connect(it[1])
		panel.add_child(b)
	root.add_child(overlay)


func _open_settings() -> void:
	var sp := SettingsPanel.new()
	root.add_child(sp)


func hide_overlay() -> void:
	_clear_overlay()


func show_result(r: Dictionary) -> void:
	var o := _make_overlay("نتيجة السباق", 1020.0, 640.0)
	var p: Panel = o.get_meta("panel")
	var rank: int = int(r.get("rank", 1))
	var lines := [
		"المركز %d من %d" % [rank, int(r.get("total", 8))],
		"الزمن:  %s%s" % [_fmt(r.time), "   (رقم قياسي جديد!)" if r.get("new_best", false) else ""],
		"العملات:  %d / %d" % [r.coins, r.coins_total],
		"أفضل زمن:  %s" % _fmt(r.best),
		"ضربات للمنافسين: %d    أُصبتَ: %d" % [int(r.get("rival_hits", 0)), int(r.get("times_hit", 0))],
		"تعثّر: %d    سقوط: %d    صناديق: %d" % [r.stumbles, r.falls, r.crates],
	]
	var y := 96.0
	for i in range(lines.size()):
		var col := Color("fff2b0") if i < 2 else Color.WHITE
		var l := UiKit.label(lines[i], 40 if i == 0 else (32 if i == 1 else 25), col, 6)
		l.size = Vector2(480, 46)
		l.position = Vector2(20, y)
		p.add_child(l)
		y += 62.0 if i < 2 else 48.0
	# جدول الترتيب
	var st: Array = r.get("standings", [])
	var ty := 96.0
	for k in range(st.size()):
		var e: Dictionary = st[k]
		var row := Panel.new()
		row.size = Vector2(470, 40)
		row.position = Vector2(520, ty)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("ffd23a") if e.player else Color(1, 1, 1, 0.12)
		sb.set_corner_radius_all(10)
		row.add_theme_stylebox_override("panel", sb)
		p.add_child(row)
		var tc := Color("1b2a6b") if e.player else Color.WHITE
		var n := UiKit.label("%d.  %s" % [k + 1, e.name], 24, tc, 0, HORIZONTAL_ALIGNMENT_RIGHT)
		n.size = Vector2(250, 40)
		n.position = Vector2(200, 0)
		row.add_child(n)
		var tm := UiKit.label(e.time_text, 22, tc, 0, HORIZONTAL_ALIGNMENT_LEFT)
		tm.size = Vector2(190, 40)
		tm.position = Vector2(16, 0)
		row.add_child(tm)
		ty += 46.0
	var perf := UiKit.label("الأداء:  متوسط %.0f إطار/ث  •  أبطأ 5%%: %.0f مللي ث  •  الجودة: %s" % [r.avg_fps, r.p95_ms, r.quality], 19, Color("c9ffd6"), 4)
	perf.size = Vector2(p.size.x - 40, 36)
	perf.position = Vector2(20, p.size.y - 150)
	p.add_child(perf)
	var b1 := UiKit.button("إعادة", UiKit.C_GOLD_TOP, UiKit.C_GOLD_BOT, Vector2(300, 74), 32)
	b1.size = Vector2(300, 74)
	b1.position = Vector2(p.size.x * 0.5 + 20, p.size.y - 100)
	b1.pressed.connect(func(): restart_pressed.emit())
	p.add_child(b1)
	var b2 := UiKit.button("الرئيسية", UiKit.C_PURPLE_TOP, UiKit.C_PURPLE_BOT, Vector2(300, 74), 32)
	b2.size = Vector2(300, 74)
	b2.position = Vector2(p.size.x * 0.5 - 320, p.size.y - 100)
	b2.pressed.connect(func(): home_pressed.emit())
	p.add_child(b2)


static func _fmt(t: float) -> String:
	return "%02d:%05.2f" % [int(t / 60.0), fmod(t, 60.0)]
