class_name CostumesScreen
extends Control
## شاشة الأزياء: نسخة طبق الأصل من صفحة «المتجر» في ملف التصميم (الصورة مرجعًا) + أزرار حقيقية.
## المتاح: الأساسي (مُلبَّس) والعودة؛ بقية الأزياء والشراء والمعاينة والتبويبات بوسم «غير متاح حاليًا».

signal closed

const W := 1672.0
const H := 941.0
const TAG_TEXT := "غير متاح حاليًا"
const BG := preload("res://assets/ui/costumes_ref.png")

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


func _unavailable(r: Rect2, fsize := 22, tag_dy := 0.0, show_tag := true, alpha := 0.55) -> void:
	var cover := _box(r, Color(0.03, 0.05, 0.2, alpha), Color(0, 0, 0, 0), 26, 0)
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	if not show_tag:
		return
	var tw := minf(r.size.x - 10.0, fsize * 7.2)
	var th := fsize * 1.6
	var tag := _box(Rect2(r.position + Vector2((r.size.x - tw) * 0.5, (r.size.y - th) * 0.5 + tag_dy), Vector2(tw, th)), Color(0.1, 0.12, 0.3, 0.92), Color("8a93c8"), 14, 2)
	var t := UiKit.label(TAG_TEXT, fsize, Color("dfe5ff"), 3)
	t.size = tag.size
	tag.add_child(t)


func _patch_num(x: float, y: float, w: float, h: float, sample_x: int, text: String) -> void:
	var strip := Image.create(1, int(h), false, Image.FORMAT_RGBA8)
	for i in range(int(h)):
		strip.set_pixel(0, i, _bg_img.get_pixel(sample_x, int(y) + i))
	var pt := TextureRect.new()
	pt.texture = ImageTexture.create_from_image(strip)
	pt.position = Vector2(x, y)
	pt.size = Vector2(w, h)
	pt.stretch_mode = TextureRect.STRETCH_SCALE
	pt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(pt)
	var l := UiKit.num_label(text, 34)
	l.position = Vector2(x, y - 4)
	l.size = Vector2(w, h + 8)
	l.clip_text = true
	_root.add_child(l)


func _build() -> void:
	# أرصدة حقيقية فوق الأرقام المرسومة
	_patch_num(1132, 34, 106, 42, 1236, str(Settings.total_coins))
	_patch_num(1388, 34, 84, 42, 1478, "0")

	# بطاقات الأزياء: الأساسي (أول بطاقة) هو الفعّال فقط
	var xs := [730.0, 960.0, 1190.0, 1420.0]
	for i in range(1, 8):
		_unavailable(Rect2(xs[i % 4], 238.0 + (i / 4) * 256.0, 212, 240), 18, 24.0, true, 0.35)
	# التبويبات غير النشطة
	_unavailable(Rect2(1175, 135, 232, 70), 15, 0.0, true, 0.6)
	_unavailable(Rect2(930, 135, 232, 70), 15, 0.0, true, 0.6)
	_unavailable(Rect2(688, 135, 232, 70), 15, 0.0, true, 0.6)
	# قائمة الشخصيات الجانبية
	_unavailable(Rect2(18, 155, 148, 690), 14, 0.0, true, 0.5)
	# معاينة وشراء
	_unavailable(Rect2(760, 788, 325, 115), 20, 0.0, true, 0.55)
	_unavailable(Rect2(1150, 785, 485, 125), 24, 0.0, true, 0.5)
	# الأسهم والبطاقة الأولى: لا بديل ما دام زي واحد فقط
	_unavailable(Rect2(205, 520, 80, 100), 10, 0.0, false, 0.0)
	_unavailable(Rect2(610, 520, 80, 100), 10, 0.0, false, 0.0)

	# العودة
	_hit(Rect2(1560, 22, 96, 92), func():
		closed.emit()
		queue_free())
