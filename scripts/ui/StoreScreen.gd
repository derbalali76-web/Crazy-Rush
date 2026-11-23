class_name StoreScreen
extends Control
## شاشة المتجر (تصميم المرجع): تبويبان (العملات / الجواهر). الشراء الحقيقي والإعلانات غير مفعّلة بعد:
## كل الحزم والمكافأة بالإعلان وشريط الإعلان معتَّمة بوسم «غير متاح حاليًا». العدّاد الأيسر حقيقي.
signal closed

const W := 1672.0
const H := 941.0
const TAG_TEXT := "غير متاح حاليًا"
const TABS := [
	{"img": preload("res://assets/ui/store_coins_ref.png"),
	 "cols": [Vector2(320, 715), Vector2(728, 1120), Vector2(1132, 1545)], "rows": [Vector2(255, 492), Vector2(503, 752)],
	 "side": Rect2(30, 235, 252, 548)},
	{"img": preload("res://assets/ui/store_gems_ref.png"),
	 "cols": [Vector2(298, 695), Vector2(708, 1105), Vector2(1118, 1520)], "rows": [Vector2(250, 487), Vector2(500, 747)],
	 "side": Rect2(18, 225, 224, 542)},
]
const BG := preload("res://assets/ui/store_coins_ref.png")

var _root: Control
var _bg_img: Image
var _bg: TextureRect
var _layer: Control
var _tab := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bg_img = (TABS[0].img as Texture2D).get_image()
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
	_bg = bg
	bg.texture = TABS[0].img
	bg.size = Vector2(W, H)
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bg)
	_select(0)


func _hit(r: Rect2, cb: Callable) -> void:
	var b := Button.new()
	b.flat = true
	b.position = r.position
	b.size = r.size
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	_add(b)


func _box(r: Rect2, fill: Color, edge: Color, radius := 24, bw := 2) -> Panel:
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
	_add(p)
	return p


func _unavailable(r: Rect2, fsize := 22, tag_dy := 0.0, show_tag := true, alpha := 0.55, radius := 26) -> void:
	var cover := _box(r, Color(0.03, 0.05, 0.2, alpha), Color(0, 0, 0, 0), radius, 0)
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	if not show_tag:
		return
	var tw := minf(r.size.x - 10.0, fsize * 7.2)
	var th := fsize * 1.6
	var tag := _box(Rect2(r.position + Vector2((r.size.x - tw) * 0.5, (r.size.y - th) * 0.5 + tag_dy), Vector2(tw, th)), Color(0.1, 0.12, 0.3, 0.92), Color("8a93c8"), 14, 2)
	var t := UiKit.label(TAG_TEXT, fsize, Color("dfe5ff"), 3)
	t.size = tag.size
	tag.add_child(t)


func _patch2(x0: float, x1: float, y0: int, y1: int, cl: int, cr: int) -> void:
	var h := y1 - y0
	var st := Image.create(2, h, false, Image.FORMAT_RGBA8)
	for i in range(h):
		st.set_pixel(0, i, _bg_img.get_pixel(cl, y0 + i))
		st.set_pixel(1, i, _bg_img.get_pixel(cr, y0 + i))
	var tr := TextureRect.new()
	tr.texture = ImageTexture.create_from_image(st)
	tr.position = Vector2(x0, y0)
	tr.size = Vector2(x1 - x0, h)
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_add(tr)



func _add(n: Node) -> void:
	_layer.add_child(n)


func _select(i: int) -> void:
	_tab = i
	_bg_img = (TABS[i].img as Texture2D).get_image()
	_bg.texture = TABS[i].img
	if _layer:
		_layer.queue_free()
	_layer = Control.new()
	_layer.size = Vector2(W, H)
	_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_layer)
	_build()


func _build() -> void:
	var tb: Dictionary = TABS[_tab]
	# --- الحزم (الشراء غير مفعّل بعد)
	for r in tb.rows:
		for c in tb.cols:
			_unavailable(Rect2(c.x, r.x, c.y - c.x, r.y - r.x), 20, -78.0, true, 0.4)
	# --- المكافأة بالإعلان + شريط الإعلان (الإعلانات لاحقًا)
	_unavailable(tb.side, 18, -130.0, true, 0.45)
	_unavailable(Rect2(92, 800, 1488, 125), 28, 0.0, true, 0.55)
	# --- التبويبان
	_hit(Rect2(425, 118, 415, 110), func(): _select(0))
	_hit(Rect2(845, 118, 440, 110), func(): _select(1))
	# --- عدّاد العملات الحقيقي
	_patch2(886, 1040, 34, 72, 882, 1044)
	var cl := UiKit.num_label(str(Settings.total_coins), 36)
	var fv := FontVariation.new()
	fv.base_font = UiKit.font()
	fv.variation_embolden = 1.0
	cl.add_theme_font_override("font", fv)
	cl.position = Vector2(886, 28)
	cl.size = Vector2(154, 46)
	cl.autowrap_mode = TextServer.AUTOWRAP_OFF
	_add(cl)
	_unavailable(Rect2(1050, 22, 56, 56), 10, 0.0, false)            # +
	_unavailable(Rect2(1150, 14, 340, 76), 18, 0.0, true, 0.9)       # الجواهر
	_hit(Rect2(1520, 10, 140, 108), func():
		closed.emit()
		queue_free())
