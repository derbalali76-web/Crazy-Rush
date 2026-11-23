class_name StoreScreen
extends Control
## شاشة المتجر (تصميم المرجع). المتجر غير مطوَّر بعد: المحتوى معتَّم بوسم «غير متاح حاليًا»،
## والرأس (العودة + العملات) حقيقي.

signal closed

const W := 1672.0
const H := 941.0
const BG := preload("res://assets/ui/store_ref.png")

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


func _build() -> void:
	# المحتوى كله غير متاح: تعتيم + وسم كبير (ويمنع اللمس عليه)
	var cover := _box(Rect2(0, 118, W, H - 118), Color(0.03, 0.05, 0.2, 0.66), Color(0, 0, 0, 0), 0, 0)
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	var tag := _box(Rect2(W * 0.5 - 300, 440, 600, 100), Color(0.1, 0.12, 0.3, 0.94), Color("8a93c8"), 40, 4)
	var t := UiKit.label("غير متاح حاليًا", 54, Color("dfe5ff"), 4)
	t.size = tag.size
	tag.add_child(t)
	var sub := UiKit.label("المتجر قيد التطوير", 30, Color("c9d6ff"), 4)
	sub.size = Vector2(600, 50)
	sub.position = Vector2(W * 0.5 - 300, 548)
	_root.add_child(sub)

	# عدّاد العملات الحقيقي فوق الرقم المرسوم
	var strip := Image.create(1, 34, false, Image.FORMAT_RGBA8)
	for i in range(34):
		strip.set_pixel(0, i, _bg_img.get_pixel(1160, 34 + i))
	var pt := TextureRect.new()
	pt.texture = ImageTexture.create_from_image(strip)
	pt.position = Vector2(1046, 34)
	pt.size = Vector2(112, 34)
	pt.stretch_mode = TextureRect.STRETCH_SCALE
	pt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(pt)
	var coins := UiKit.label(str(Settings.total_coins), 32, Color.WHITE, 4)
	coins.position = Vector2(1046, 28)
	coins.size = Vector2(112, 38)
	coins.clip_text = true
	_root.add_child(coins)
	# الجواهر + أزرار «+» غير متاحة
	_box(Rect2(1165, 22, 56, 56), Color(0.03, 0.05, 0.2, 0.55), Color(0, 0, 0, 0), 28, 0).mouse_filter = Control.MOUSE_FILTER_STOP
	_box(Rect2(1240, 22, 255, 56), Color(0.03, 0.05, 0.2, 0.55), Color(0, 0, 0, 0), 28, 0).mouse_filter = Control.MOUSE_FILTER_STOP

	# زر العودة (البيت)
	var home := Button.new()
	home.flat = true
	home.position = Vector2(1525, 10)
	home.size = Vector2(105, 105)
	home.focus_mode = Control.FOCUS_NONE
	home.pressed.connect(func():
		closed.emit()
		queue_free())
	_root.add_child(home)
