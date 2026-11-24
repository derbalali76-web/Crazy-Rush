class_name AboutScreen
extends Control
## شاشة «حول اللعبة» (تصميم المرجع): ثابتة؛ العملات حقيقية، والجواهر غير متاحة.
signal closed

const W := 1672.0
const H := 941.0
const TAG_TEXT := "غير متاح حاليًا"
var BG: Texture2D = Loc.tex("res://assets/ui/about_ref.png")

var _root: Control
var _bg_img: Image


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bg_img = BG.get_image()
	var vp := get_viewport_rect().size
	set_deferred("size", vp)
	custom_minimum_size = vp

	UiKit.add_backdrop(self, _bg_img, vp, W, H)

	var fit := UiKit.fit(vp, W, H)
	_root = Control.new()
	_root.size = Vector2(W, H)
	_root.scale = fit[0]
	_root.position = fit[1]
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


func _hit(r: Rect2, cb: Callable) -> void:
	var b := Button.new()
	b.flat = true
	b.position = r.position
	b.size = r.size
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	_root.add_child(b)


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
	_root.add_child(p)
	return p


func _unavailable(r: Rect2, fsize := 22, tag_dy := 0.0, show_tag := true, alpha := 0.55, radius := 26) -> void:
	var cover := _box(r, Color(0.03, 0.05, 0.2, alpha), Color(0, 0, 0, 0), radius, 0)
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	if not show_tag:
		return
	var tw := minf(r.size.x - 10.0, fsize * 7.2)
	var th := fsize * 1.6
	var tag := _box(Rect2(r.position + Vector2((r.size.x - tw) * 0.5, (r.size.y - th) * 0.5 + tag_dy), Vector2(tw, th)), Color(0.1, 0.12, 0.3, 0.92), Color("8a93c8"), 14, 2)
	var t := UiKit.label(Loc.t(TAG_TEXT), fsize, Color("dfe5ff"), 3)
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
	_root.add_child(tr)


func _fmt_time(t: float) -> String:
	if t <= 0.0:
		return "--:--.--"
	var m := int(t) / 60
	return "%02d:%05.2f" % [m, t - m * 60.0]


func _num(txt: String, r: Rect2, size := 62) -> Label:
	var l := UiKit.label(txt, size, Color("ffe45a"), 10)
	var fv := FontVariation.new()
	fv.base_font = UiKit.font()
	fv.variation_embolden = 1.1
	fv.variation_transform = Transform2D(Vector2(1, 0), Vector2(-0.2, 1), Vector2.ZERO)
	l.add_theme_font_override("font", fv)
	l.position = r.position + Vector2(0, -0.38 * float(size))
	l.size = r.size
	l.clip_text = true
	_root.add_child(l)
	return l


func _fmt_int(n: int) -> String:
	var s := str(n)
	var out := ""
	for i in range(s.length()):
		if i > 0 and (s.length() - i) % 3 == 0:
			out += ","
		out += s[i]
	return out


func _build() -> void:
	var strip := Image.create(1, 34, false, Image.FORMAT_RGBA8)
	for i in range(34):
		strip.set_pixel(0, i, _bg_img.get_pixel(1187, 32 + i))
	var pt := TextureRect.new()
	pt.texture = ImageTexture.create_from_image(strip)
	pt.position = Vector2(1190, 32)
	pt.size = Vector2(100, 34)
	pt.stretch_mode = TextureRect.STRETCH_SCALE
	pt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(pt)
	var cl := UiKit.num_label(str(Settings.total_coins), 32)
	cl.position = Vector2(1190, 19)
	cl.size = Vector2(100, 42)
	cl.clip_text = true
	_root.add_child(cl)
	_hit(Rect2(1296, 22, 52, 52), func(): UiKit.open_store(self, 0))
	UiKit.counter(_root, _bg_img, Rect2(1424, 19, 88, 44), 1420, str(Settings.gems), 34)
	_hit(Rect2(1362, 20, 212, 60), func(): UiKit.open_store(self, 1))
	_hit(Rect2(1578, 12, 92, 92), _close)
	_hit(Rect2(570, 795, 500, 130), _close)


func _close() -> void:
	closed.emit()
	queue_free()
