class_name TrackSelect
extends Control
## شاشة «اختر الحلبة» (تصميم المرجع). المتاحة: حلبة الشلالات (الحلبة الحالية)؛
## بقية الحلبات والبطولات والتحديات والمكافآت معتَّمة بوسم «غير متاح حاليًا».

signal start_pressed
signal choose_character_pressed
signal closed

const W := 1670.0
const H := 942.0
const TAG_TEXT := "غير متاح حاليًا"
const BG := preload("res://assets/ui/track_ref.png")

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



func _patch2(x0: float, x1: float, y0: int, y1: int, cl: int, cr: int) -> void:
	var h := y1 - y0
	var st := Image.create(2, h, false, Image.FORMAT_RGBA8)
	for i in range(h):
		st.set_pixel(0, i, _bg_img.get_pixel(cl, y0 + i))
		st.set_pixel(1, i, _bg_img.get_pixel(cr, y0 + i))
	var t := TextureRect.new()
	t.texture = ImageTexture.create_from_image(st)
	t.position = Vector2(x0, y0)
	t.size = Vector2(x1 - x0, h)
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(t)


func _fmt(t: float) -> String:
	if t <= 0.0:
		return "--:--.--"
	var m := int(t) / 60
	return "%02d:%05.2f" % [m, t - m * 60.0]


func _build() -> void:
	# --- الحلبات الأخرى (الصف السفلي)
	for x in [385.0, 618.0, 852.0]:
		_unavailable(Rect2(x, 562, 216, 172), 18, 18.0, true, 0.6)
	_unavailable(Rect2(1085, 562, 220, 172), 18, 18.0, true, 0.6)
	_unavailable(Rect2(1322, 562, 232, 172), 18, 18.0, true, 0.6)
	_unavailable(Rect2(30, 585, 72, 110), 10, 0.0, false)      # سهم يسار
	_unavailable(Rect2(1568, 585, 72, 110), 10, 0.0, false)    # سهم يمين
	# --- معاينة الحلبة (تشغيل/نقاط)
	_unavailable(Rect2(350, 438, 90, 90), 10, 0.0, false)
	# --- المكافآت (غير موجودة في اللعبة بعد)
	_unavailable(Rect2(1165, 405, 396, 112), 20, 14.0, true, 0.82)
	# --- البطولات والتحديات
	_unavailable(Rect2(38, 782, 272, 100), 18, 0.0, true, 0.6)
	_unavailable(Rect2(320, 782, 274, 100), 18, 0.0, true, 0.6)

	# --- أفضل زمن حقيقي فوق الرقم المرسوم
	_patch2(1250, 1378, 338, 378, 1243, 1385)
	var bt := UiKit.label(_fmt(Settings.best_time), 34, Color.WHITE, 4)
	bt.position = Vector2(1250, 336)
	bt.size = Vector2(128, 44)
	bt.clip_text = true
	_root.add_child(bt)

	# --- العملات الحقيقية
	var strip := Image.create(1, 34, false, Image.FORMAT_RGBA8)
	for i in range(34):
		strip.set_pixel(0, i, _bg_img.get_pixel(1191, 30 + i))
	var pt := TextureRect.new()
	pt.texture = ImageTexture.create_from_image(strip)
	pt.position = Vector2(1194, 30)
	pt.size = Vector2(100, 34)
	pt.stretch_mode = TextureRect.STRETCH_SCALE
	pt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(pt)
	var coins := UiKit.label(str(Settings.total_coins), 32, Color.WHITE, 4)
	coins.position = Vector2(1194, 26)
	coins.size = Vector2(100, 42)
	coins.clip_text = true
	_root.add_child(coins)
	_unavailable(Rect2(1296, 22, 52, 52), 10, 0.0, false)
	_unavailable(Rect2(1380, 18, 192, 58), 16, 0.0, true, 0.9)

	# --- الأزرار الفعّالة
	_hit(Rect2(1575, 10, 90, 80), func():
		closed.emit()
		queue_free())
	_hit(Rect2(608, 765, 575, 135), func(): start_pressed.emit())
	_hit(Rect2(1198, 765, 432, 120), func(): choose_character_pressed.emit())
