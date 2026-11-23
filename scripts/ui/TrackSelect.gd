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
## شاشة لكل حلبة (الصورة المرجعية بها لوحتها وبطاقتها المميَّزة). المتاحة للعب: الشلالات فقط.
const TRACKS := [
	{"id": "waterfalls", "img": preload("res://assets/ui/track_ref.png"), "playable": true},
	{"id": "forest", "img": preload("res://assets/ui/track_forest.png"), "playable": false},
	{"id": "desert", "img": preload("res://assets/ui/track_desert.png"), "playable": false},
	{"id": "city", "img": preload("res://assets/ui/track_city.png"), "playable": false},
	{"id": "snow", "img": preload("res://assets/ui/track_snow.png"), "playable": false},
	{"id": "volcano", "img": preload("res://assets/ui/track_volcano.png"), "playable": false},
]
## بطاقات الحلبات السفلية (يسار → يمين)
const CARDS := [
	Rect2(118, 556, 250, 178), Rect2(380, 556, 226, 178), Rect2(614, 556, 226, 178),
	Rect2(848, 556, 226, 178), Rect2(1082, 556, 230, 178), Rect2(1318, 556, 240, 178),
]

var _root: Control
var _bg_img: Image


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bg_img = (TRACKS[0].img as Texture2D).get_image()
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
	_add(t)


func _fmt(t: float) -> String:
	if t <= 0.0:
		return "--:--.--"
	var m := int(t) / 60
	return "%02d:%05.2f" % [m, t - m * 60.0]


var _sel := 0
var _bg: TextureRect
var _layer: Control


func _select(i: int) -> void:
	_sel = i
	_bg_img = (TRACKS[i].img as Texture2D).get_image()
	_bg.texture = TRACKS[i].img
	if _layer:
		_layer.queue_free()
	_layer = Control.new()
	_layer.size = Vector2(W, H)
	_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_layer)
	_build()


func _add(n: Node) -> void:
	_layer.add_child(n)


func _build() -> void:
	var playable: bool = TRACKS[_sel].playable
	# --- اختيار الحلبة من الشريط السفلي
	for i in range(CARDS.size()):
		if i != _sel:
			_hit(CARDS[i], func(): _select(i))
	_unavailable(Rect2(30, 585, 72, 110), 10, 0.0, false)      # سهم يسار
	_unavailable(Rect2(1568, 585, 72, 110), 10, 0.0, false)    # سهم يمين
	_unavailable(Rect2(350, 438, 90, 90), 10, 0.0, false)      # معاينة
	# --- المكافآت غير موجودة في اللعبة بعد
	_unavailable(Rect2(1165, 405, 396, 112), 20, 14.0, true, 0.82)
	_unavailable(Rect2(38, 782, 272, 100), 18, 0.0, true, 0.6)
	_unavailable(Rect2(320, 782, 274, 100), 18, 0.0, true, 0.6)

	# --- أفضل زمن (حقيقي للحلبة المتاحة، وغير متاح لغيرها)
	_patch2(1250, 1388, 338, 378, 1252, 1386)
	var bt := UiKit.label(_fmt(Settings.best_time) if playable else "--:--.--", 34, Color.WHITE, 4)
	bt.position = Vector2(1250, 336)
	bt.size = Vector2(138, 44)
	bt.clip_text = true
	_add(bt)

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
	_add(pt)
	var coins := UiKit.num_label(str(Settings.total_coins), 32)
	coins.position = Vector2(1194, 26)
	coins.size = Vector2(100, 42)
	coins.clip_text = true
	_add(coins)
	_unavailable(Rect2(1296, 22, 52, 52), 10, 0.0, false)
	_unavailable(Rect2(1380, 18, 192, 58), 16, 0.0, true, 0.9)

	# --- الأزرار
	_hit(Rect2(1575, 10, 90, 80), func():
		closed.emit()
		queue_free())
	_hit(Rect2(1198, 765, 432, 120), func(): choose_character_pressed.emit())
	if playable:
		_hit(Rect2(608, 765, 575, 135), func(): start_pressed.emit())
	else:
		_unavailable(Rect2(608, 765, 575, 135), 30, 0.0, true, 0.6)
