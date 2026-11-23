class_name ResultsScreen
extends Control
## شاشة نتائج السباق (تصميم المرجع): الخلفية الفنية صورة، والجدول والأرقام والأزرار حقيقية.
## الشخصيات في الجدول تأتي من سجلّ Characters (entry.character، وإلا فوكسي مؤقتًا).

signal restart_pressed
signal home_pressed

const W := 1672.0
const H := 941.0
const TAG_TEXT := "غير متاح حاليًا"
const BG := preload("res://assets/ui/results_ref.png")
const ORD := ["الأول", "الثاني", "الثالث", "الرابع", "الخامس", "السادس", "السابع", "الثامن"]

var data: Dictionary = {}
var _root: Control
var _bg_img: Image


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bg_img = BG.get_image()
	var vp := get_viewport_rect().size
	set_deferred("size", vp)
	custom_minimum_size = vp
	var small := _bg_img.duplicate() as Image
	small.resize(40, 22, Image.INTERPOLATE_BILINEAR)
	var blur := TextureRect.new()
	blur.texture = ImageTexture.create_from_image(small)
	blur.size = vp
	blur.stretch_mode = TextureRect.STRETCH_SCALE
	blur.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	blur.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	blur.modulate = Color(0.75, 0.8, 0.95)
	blur.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(blur)
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
	_build()


# ---------------------------------------------------------------- أدوات
func _box(r: Rect2, fill: Color, edge: Color, radius := 24, bw := 2, parent: Control = null) -> Panel:
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
	(parent if parent else _root).add_child(p)
	return p


func _lbl(text: String, r: Rect2, size := 36, color := Color.WHITE, align := HORIZONTAL_ALIGNMENT_CENTER, outline := 5, parent: Control = null) -> Label:
	var l := UiKit.label(text, size, color, outline, align)
	l.position = r.position
	l.size = r.size
	l.clip_text = true
	(parent if parent else _root).add_child(l)
	return l


func _hit(r: Rect2, cb: Callable) -> void:
	var b := Button.new()
	b.flat = true
	b.position = r.position
	b.size = r.size
	b.focus_mode = Control.FOCUS_NONE
	var hl := _box(r, Color(1, 1, 1, 0.2), Color(0, 0, 0, 0), 60, 0)
	hl.visible = false
	b.button_down.connect(func(): hl.visible = true)
	b.button_up.connect(func(): hl.visible = false)
	b.pressed.connect(cb)
	_root.add_child(b)


func _patch(r: Rect2, sample_x: int) -> void:
	var img := Image.create(1, int(r.size.y), false, Image.FORMAT_RGBA8)
	for i in range(int(r.size.y)):
		img.set_pixel(0, i, _bg_img.get_pixel(sample_x, int(r.position.y) + i))
	var tr := TextureRect.new()
	tr.texture = ImageTexture.create_from_image(img)
	tr.position = r.position
	tr.size = r.size
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(tr)


func _patch2(r: Rect2, xl: int, xr: int) -> void:
	var img := Image.create(2, int(r.size.y), false, Image.FORMAT_RGBA8)
	for i in range(int(r.size.y)):
		img.set_pixel(0, i, _bg_img.get_pixel(xl, int(r.position.y) + i))
		img.set_pixel(1, i, _bg_img.get_pixel(xr, int(r.position.y) + i))
	var tr := TextureRect.new()
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.texture = ImageTexture.create_from_image(img)
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	tr.position = r.position
	tr.size = r.size
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(tr)


func _unavailable(r: Rect2, fsize := 20, alpha := 0.55) -> void:
	var cover := _box(r, Color(0.03, 0.05, 0.2, alpha), Color(0, 0, 0, 0), 22, 0)
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := minf(r.size.x - 8.0, fsize * 7.2)
	var th := fsize * 1.6
	var tag := _box(Rect2(r.position + Vector2((r.size.x - tw) * 0.5, (r.size.y - th) * 0.5), Vector2(tw, th)), Color(0.1, 0.12, 0.3, 0.92), Color("8a93c8"), 14, 2)
	var t := UiKit.label(TAG_TEXT, fsize, Color("dfe5ff"), 3)
	t.size = tag.size
	tag.add_child(t)


# ---------------------------------------------------------------- البناء
func _build() -> void:
	var rank: int = int(data.get("rank", 1))
	var st: Array = data.get("standings", [])

	# المكافآت: العملات الحقيقية فقط
	_patch2(Rect2(158, 346, 152, 64), 154, 306)
	_lbl(str(int(data.get("coins", 0))), Rect2(160, 348, 150, 60), 48, Color("ffe15a"), HORIZONTAL_ALIGNMENT_CENTER, 5)
	_unavailable(Rect2(62, 432, 245, 72), 18, 0.86)    # الجواهر
	_unavailable(Rect2(62, 518, 245, 84), 18, 0.86)    # الخبرة
	if data.get("new_best", false):
		_lbl("رقم قياسي جديد!", Rect2(30, 648, 310, 44), 28, Color("fff3a0"), HORIZONTAL_ALIGNMENT_CENTER, 6)

	# لافتة المركز (تتبع ترتيب اللاعب)
	_patch(Rect2(436, 660, 240, 44), 425)
	_lbl("المركز " + ORD[clampi(rank - 1, 0, ORD.size() - 1)], Rect2(430, 655, 250, 52), 38, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 6)

	# جدول الترتيب (يتكيف مع عدد المتسابقين)
	_box(Rect2(814, 198, 820, 492), Color("01174f"), Color(0, 0, 0, 0), 22, 0)
	var n := maxi(st.size(), 1)
	var rh := minf(78.0, (480.0 - (n - 1) * 8.0) / n)
	var y := 204.0
	for k in range(st.size()):
		_row(k, st[k], y, rh)
		y += rh + 8.0

	# الأزرار
	_hit(Rect2(60, 775, 430, 140), func(): home_pressed.emit())
	_hit(Rect2(530, 775, 500, 140), func(): restart_pressed.emit())
	_unavailable(Rect2(1065, 775, 550, 140), 26)    # السباق التالي (حلبة واحدة فقط حاليًا)

	# معلومات الأداء (للاختبار)
	var perf := "FPS %.0f  •  p95 %.0f ms  •  %s" % [float(data.get("avg_fps", 0)), float(data.get("p95_ms", 0)), str(data.get("quality", ""))]
	_lbl(perf, Rect2(20, 160, 560, 30), 17, Color("c9ffd6"), HORIZONTAL_ALIGNMENT_LEFT, 4)


func _row(k: int, e: Dictionary, y: float, h: float) -> void:
	var cols := [
		[Color("f2b51c"), Color("ffe27a")],
		[Color("8fb0e8"), Color("d8e6ff")],
		[Color("d9803a"), Color("ffc080")],
	]
	var fill: Color
	var edge: Color
	if k < 3:
		fill = cols[k][0]
		edge = cols[k][1]
	else:
		fill = Color("1b57d0")
		edge = Color("4a9bff")
	var is_player: bool = bool(e.get("player", false))
	var rb := _box(Rect2(820, y, 808, h), fill, Color.WHITE if is_player else edge, int(h * 0.4), 4 if is_player else 2)
	var tc := Color("1a1040") if k < 2 else Color.WHITE
	_lbl(str(k + 1), Rect2(18, 0, 80, h), int(h * 0.62), tc, HORIZONTAL_ALIGNMENT_CENTER, 0 if k < 2 else 4, rb)
	var ic := Characters.icon(str(e.get("character", Settings.selected_character if is_player else "fox")))
	if ic:
		var isz := h - 8.0
		var tr := TextureRect.new()
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		tr.texture = ic
		tr.size = Vector2(isz * 1.1, isz)
		tr.position = Vector2(115, 4)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rb.add_child(tr)
	_lbl(str(e.get("name", "")), Rect2(240, 0, 250, h), int(h * 0.5), tc, HORIZONTAL_ALIGNMENT_LEFT, 0 if k < 2 else 4, rb)
	var pill := _box(Rect2(500, h * 0.14, 180, h * 0.72), Color(0.05, 0.07, 0.25, 0.75), Color(0, 0, 0, 0), int(h * 0.3), 0, rb)
	_lbl(str(e.get("time_text", "")), Rect2(0, 0, 180, h * 0.72), int(h * 0.44), Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 3, pill)
	if is_player:
		var cp := _box(Rect2(700, h * 0.14, 90, h * 0.72), Color(0.05, 0.07, 0.25, 0.75), Color(0, 0, 0, 0), int(h * 0.3), 0, rb)
		_lbl("+%d" % int(data.get("coins", 0)), Rect2(0, 0, 90, h * 0.72), int(h * 0.42), Color("ffe15a"), HORIZONTAL_ALIGNMENT_CENTER, 3, cp)
