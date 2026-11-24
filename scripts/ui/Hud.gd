class_name Hud
extends CanvasLayer
## واجهة السباق: شريط التقدم، الزمن، العملات، العدّ التنازلي، الإيقاف المؤقت، النتائج، عدّاد الأداء.

signal pause_pressed
signal resume_pressed
signal restart_pressed
signal home_pressed

class ProgressView extends Control:
	## شريط التقدم بتصميم المرجع: شريط فارغ + تعبئة خضراء + علامة اللاعب + علم النهاية.
	const BAR := preload("res://assets/ui/hud/bar_empty.png")
	const FILL := preload("res://assets/ui/hud/bar_fill.png")
	const MARK := preload("res://assets/ui/hud/marker.png")
	const FLAG := preload("res://assets/ui/hud/flag.png")
	const X0 := 16.0      # بداية المجرى داخل الصورة (بالنسبة لأصل الشريط)
	const X1 := 560.0     # نهايته
	var value := 0.0
	var rivals: Array = []
	var rival_colors: Array = []
	func _init() -> void:
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	func _draw() -> void:
		# الأصل (0,0) = (524,40) في المرجع
		draw_texture(BAR, Vector2.ZERO)
		var w := (X1 - X0) * clampf(value, 0.0, 1.0)
		if w > 1.0:
			draw_texture_rect(FILL, Rect2(X0, 11, w, 20), false)
		draw_texture(FLAG, Vector2(1092 - 524, 14 - 40))
		var px := X0 + w
		draw_texture(MARK, Vector2(px - 56.0, 15.0 - 51.0 + 21.0 - 10.0))


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


const REF_W := 1672.0
const REF_H := 941.0
const T_LOGO := preload("res://assets/ui/hud/logo.png")
const T_TIMER := preload("res://assets/ui/hud/timer.png")
const T_LAP := preload("res://assets/ui/hud/lap.png")
const T_PAUSE := preload("res://assets/ui/hud/pause.png")
const T_MEDAL := [preload("res://assets/ui/hud/medal1.png"), preload("res://assets/ui/hud/medal2.png"), preload("res://assets/ui/hud/medal3.png")]
const ROW0 := 162.0
const ROW_DY := 53.0

var left_root: Control
var right_root: Control
var center_root: Control
var rank_num: Label
var rank_tot: Label
var lap_label: Label
var _rows: Array = []          # لكل مركز: {bg, hi, medal, num, face, name}
var _order_key := ""
var _bold: FontVariation
var _ital: FontVariation


func _b(l: Label) -> Label:
	## خط أثقل لأرقام/أسماء الواجهة (قريب من خط المرجع)
	if _bold == null:
		_bold = FontVariation.new()
		_bold.base_font = UiKit.font()
		_bold.variation_embolden = 0.85
	l.add_theme_font_override("font", _bold)
	return l


func _num(l: Label) -> Label:
	## أرقام مائلة وثقيلة كما في المرجع
	if _ital == null:
		_ital = FontVariation.new()
		_ital.base_font = UiKit.font()
		_ital.variation_embolden = 1.1
		_ital.variation_transform = Transform2D(Vector2(1, 0), Vector2(-0.2, 1), Vector2.ZERO)
	l.add_theme_font_override("font", _ital)
	return l




func _spr(parent: Control, tex: Texture2D, pos: Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex
	t.position = pos
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(t)
	return t


func _panel(parent: Control, r: Rect2, fill: Color, edge: Color, radius: int, bw := 0) -> Panel:
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


func _build() -> void:
	controls = TouchControls.new()
	root.add_child(controls)

	# ثلاث مجموعات مرجعية (يسار / وسط / يمين) تُقاس بارتفاع الشاشة وتلتصق بحوافها
	left_root = Control.new()
	left_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(left_root)
	center_root = Control.new()
	center_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center_root)
	right_root = Control.new()
	right_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(right_root)

	# --- يسار: الشعار + المركز + لوحة الترتيب
	_spr(left_root, T_LOGO, Vector2(236, 0))
	rank_num = _num(UiKit.label("1", 112, Color("ffc928"), 16, HORIZONTAL_ALIGNMENT_RIGHT))
	rank_num.add_theme_color_override("font_outline_color", Color("5a2400"))
	rank_num.position = Vector2(14, 0)
	rank_num.size = Vector2(100, 120)
	left_root.add_child(rank_num)
	rank_tot = _num(UiKit.label("/4", 62, Color.WHITE, 10, HORIZONTAL_ALIGNMENT_LEFT))
	rank_tot.add_theme_color_override("font_outline_color", Color("3a2a10"))
	rank_tot.position = Vector2(112, 22)
	rank_tot.size = Vector2(100, 80)
	left_root.add_child(rank_tot)
	for p in range(RaceLogic.RACERS):
		_make_row(p)

	# --- وسط: شريط التقدم
	progress_view = ProgressView.new()
	progress_view.size = Vector2(640, 110)
	progress_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_root.add_child(progress_view)

	# --- يمين: المؤقت + اللفة + الإيقاف (+ عدّاد العملات)
	_spr(right_root, T_TIMER, Vector2(1236, 6))
	time_label = _num(UiKit.label("00:00.00", 44, Color.WHITE, 9))
	time_label.position = Vector2(1308, 20)
	time_label.size = Vector2(206, 56)
	right_root.add_child(time_label)
	_spr(right_root, T_LAP, Vector2(1280, 80))
	lap_label = _num(UiKit.label("1/1", 40, Color.WHITE, 8))
	lap_label.position = Vector2(1392, 93)
	lap_label.size = Vector2(90, 50)
	right_root.add_child(lap_label)
	_spr(right_root, T_PAUSE, Vector2(1546, 2))

	pause_btn = Button.new()
	pause_btn.flat = true
	pause_btn.focus_mode = Control.FOCUS_NONE
	pause_btn.position = Vector2(1556, 12)
	pause_btn.size = Vector2(102, 96)
	pause_btn.pressed.connect(func(): pause_pressed.emit())
	right_root.add_child(pause_btn)

	# عدّاد العملات (غير موجود في المرجع لكنه ضروري للّعب): كبسولة بنفس الطراز تحت اللفة
	_panel(right_root, Rect2(1290, 156, 176, 46), Color(0.07, 0.1, 0.3, 0.92), Color("5aa0ff"), 23, 2)
	coin_icon = Control.new()
	coin_icon.size = Vector2(44, 44)
	coin_icon.position = Vector2(1290, 156)
	coin_icon.scale = Vector2(0.95, 0.95)
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
	right_root.add_child(coin_icon)
	coin_label = _num(UiKit.label("0", 32, Color("ffd23a"), 7))
	coin_label.position = Vector2(1336, 154)
	coin_label.size = Vector2(124, 50)
	right_root.add_child(coin_label)

	countdown = UiKit.label("", 180, Color("ffd23a"), 18)
	countdown.size = Vector2(900, 260)
	root.add_child(countdown)

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
	left_root.add_child(fps_label)
	fps_label.position = Vector2(14, 20 + ROW0 + ROW_DY * RaceLogic.RACERS)


func _make_row(p: int) -> void:
	var yc := ROW0 + ROW_DY * float(p)
	var row := {}
	row.bg = _panel(left_root, Rect2(60, yc - 22, 176, 44), Color(0.08, 0.07, 0.18, 0.55), Color(0.5, 0.55, 0.8, 0.25), 20, 1)
	row.hi = _panel(left_root, Rect2(11, yc - 25, 261, 50), Color("2a8cff"), Color.WHITE, 24, 3)
	row.hi.visible = false
	var shadow := row.hi.get_theme_stylebox("panel") as StyleBoxFlat
	shadow.shadow_color = Color(0.2, 0.6, 1.0, 0.55)
	shadow.shadow_size = 8
	row.medal = _spr(left_root, T_MEDAL[p] if p < 3 else T_MEDAL[0], Vector2(8, yc - 30))
	row.medal.visible = p < 3
	# ميدالية عامة للمراكز ≥ 4 (دائرة رمادية برقم)
	var circ := Control.new()
	circ.position = Vector2(10, yc - 27)
	circ.size = Vector2(54, 54)
	circ.mouse_filter = Control.MOUSE_FILTER_IGNORE
	circ.draw.connect(func():
		circ.draw_circle(Vector2(27, 29), 26, Color(0, 0, 0, 0.35))
		circ.draw_circle(Vector2(27, 27), 25, Color("e8edf5"))
		circ.draw_circle(Vector2(27, 27), 22, Color("6b7388"))
		circ.draw_circle(Vector2(27, 25), 18, Color("858da3")))
	circ.visible = p >= 3
	left_root.add_child(circ)
	row.circ = circ
	row.num = _b(UiKit.label(str(p + 1), 34, Color.WHITE, 7))
	row.num.position = Vector2(10, yc - 27)
	row.num.size = Vector2(54, 54)
	row.num.visible = p >= 3
	left_root.add_child(row.num)
	var face := TextureRect.new()
	face.texture = load("res://assets/ui/hud/face_fox.png")
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	face.position = Vector2(68, yc - 29)
	face.size = Vector2(58, 58)
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_root.add_child(face)
	row.face = face
	row.name = _b(UiKit.label("", 30, Color.WHITE, 6))
	row.name.position = Vector2(128, yc - 24)
	row.name.size = Vector2(106, 48)
	left_root.add_child(row.name)
	_rows.append(row)


## order: قائمة {name, player, color} مرتَّبة من الأول إلى الأخير
func set_standings(order: Array) -> void:
	var key := ""
	for o in order:
		key += "%s|%s;" % [o.name, o.player]
	if key == _order_key:
		return
	_order_key = key
	for p in range(_rows.size()):
		var row: Dictionary = _rows[p]
		var vis := p < order.size()
		for k in ["bg", "face", "name"]:
			row[k].visible = vis
		if not vis:
			row.hi.visible = false
			row.medal.visible = false
			row.circ.visible = false
			row.num.visible = false
			continue
		var o: Dictionary = order[p]
		var me: bool = o.player
		row.name.text = o.name
		var fid: String = Characters.id_from_short(o.name)
		row.face.texture = load("res://assets/ui/hud/face_fox.png") if fid == "fox" else Characters.icon(fid)
		row.face.size = Vector2(66, 66) if me else Vector2(58, 58)
		row.face.position = Vector2(62 if me else 66, ROW0 + ROW_DY * float(p) - (36 if me else 29))
		row.hi.visible = me
		row.bg.visible = not me
		row.face.modulate = Color.WHITE if me else Color(1, 1, 1, 0.95)
		# رقم المركز: ميدالية للثلاثة الأولى (إلا اللاعب فيُعرض رقمه على الأزرق)، ودائرة رمادية لغيرهم
		var medal_ok := p < 3 and not me
		row.medal.visible = medal_ok
		row.circ.visible = p >= 3 and not me
		row.num.visible = (p >= 3) or me
		row.num.add_theme_font_size_override("font_size", 38 if me else 34)


func _layout() -> void:
	var vp := get_viewport().get_visible_rect().size
	var s := vp.y / REF_H
	left_root.scale = Vector2(s, s)
	left_root.position = Vector2.ZERO
	right_root.scale = Vector2(s, s)
	right_root.position = Vector2(vp.x - REF_W * s, 0)
	center_root.scale = Vector2(s, s)
	center_root.position = Vector2((vp.x - REF_W * s) * 0.5 + 524.0 * s, 40.0 * s)
	countdown.position = Vector2((vp.x - 900.0) * 0.5, vp.y * 0.5 - 200)
	banner.position = Vector2((vp.x - 800.0) * 0.5, vp.y * 0.30)
	toast.position = Vector2((vp.x - 900.0) * 0.5, vp.y * 0.18)


func set_rank(rank: int, total: int) -> void:
	rank_num.text = str(rank)
	rank_tot.text = "/%d" % total


func set_rivals(values: Array, colors: Array) -> void:
	progress_view.rivals = values
	progress_view.rival_colors = colors


func set_time(t: float) -> void:
	var m := int(t / 60.0)
	var s := fmod(t, 60.0)
	time_label.text = "%02d:%05.2f" % [m, s]


func set_coins(n: int) -> void:
	coin_label.text = "%d" % n


const FX := {
	"3": "res://assets/ui/fx/cd_3.png", "2": "res://assets/ui/fx/cd_2.png", "1": "res://assets/ui/fx/cd_1.png",
	"انطلق!": "res://assets/ui/fx/cd_go.png", "خط النهاية!": "res://assets/ui/fx/finish.png",
}
var _fx: TextureRect


func _show_fx(key: String, height: float, hold: float) -> void:
	if _fx and is_instance_valid(_fx):
		_fx.queue_free()
	var vp := get_viewport().get_visible_rect().size
	var tex: Texture2D = Loc.tex(FX[key]) if key == "انطلق!" else load(FX[key])
	var sc := height / tex.get_size().y
	var t := TextureRect.new()
	t.texture = tex
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.size = tex.get_size() * sc
	t.position = (vp - t.size) * 0.5 + Vector2(0, -vp.y * 0.05)
	t.pivot_offset = t.size * 0.5
	t.scale = Vector2.ONE * 1.4
	root.add_child(t)
	_fx = t
	var tw := create_tween().set_parallel(true)
	tw.tween_property(t, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var fade := create_tween()
	fade.tween_interval(hold)
	fade.tween_property(t, "modulate:a", 0.0, 0.35)
	fade.tween_callback(t.queue_free)


func show_countdown(text: String, color := Color("ffd23a")) -> void:
	if FX.has(text):
		_show_fx(text, get_viewport().get_visible_rect().size.y * 0.6, 0.55)
		return
	countdown.text = text
	countdown.add_theme_color_override("font_color", color)
	countdown.scale = Vector2.ONE * 1.5
	countdown.pivot_offset = countdown.size * 0.5
	countdown.modulate.a = 1.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(countdown, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(countdown, "modulate:a", 0.0, 0.5).set_delay(0.5)


func show_banner(text: String, color := Color("7dffb0")) -> void:
	if text == "خط النهاية!":
		_show_fx(text, get_viewport().get_visible_rect().size.y * 0.42, 1.6)
		return
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
		[Rect2(370, 216, 532, 102), func(): resume_pressed.emit(), "متابعة"],
		[Rect2(370, 331, 532, 102), func(): restart_pressed.emit(), "إعادة السباق"],
		[Rect2(370, 447, 532, 102), func(): _open_settings(), "الإعدادات"],
		[Rect2(370, 561, 532, 102), func(): home_pressed.emit(), "الرئيسية"],
	]
	var title := UiKit.label(Loc.t("متوقف مؤقتًا"), 52, Color.WHITE, 8)
	title.position = Vector2(300, 84)
	title.size = Vector2(380, 90)
	panel.add_child(title)
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
		var lb := UiKit.label(Loc.t(it[2]), 46, Color.WHITE, 8)
		lb.position = Vector2(r.position.x + 140, r.position.y)
		lb.size = Vector2(300, r.size.y)
		panel.add_child(lb)
	root.add_child(overlay)


func _open_settings() -> void:
	var sp := SettingsPanel.new()
	root.add_child(sp)


func hide_overlay() -> void:
	_clear_overlay()


func show_result(r: Dictionary) -> void:
	_clear_overlay()
	var scr := ResultsScreen.new()
	scr.data = r
	scr.process_mode = Node.PROCESS_MODE_ALWAYS
	scr.restart_pressed.connect(func(): restart_pressed.emit())
	scr.home_pressed.connect(func(): home_pressed.emit())
	overlay = scr
	root.add_child(scr)


static func _fmt(t: float) -> String:
	return "%02d:%05.2f" % [int(t / 60.0), fmod(t, 60.0)]
