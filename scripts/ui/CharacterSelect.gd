class_name CharacterSelect
extends Control
## شاشة «اختر المتسابق» (تصميم المرجع). المتاح حاليًا: فوكسي فقط؛ بقية البطاقات
## والتبويبات والجواهر معتَّمة بوسم «غير متاح حاليًا» حتى تُطوَّر كل شخصية.
## أضف شخصية جديدة: سجّلها في Characters.LIST ثم أضف مستطيل بطاقتها في CARDS.

signal start_pressed
signal closed

const W := 1672.0
const H := 941.0
const TAG_TEXT := "غير متاح حاليًا"
const BG := preload("res://assets/ui/select_ref.png")

## مستطيلات البطاقات الاثنتي عشرة؛ "id" فارغ = غير متاحة بعد.
const CARDS := [
	{"r": Rect2(447, 195, 271, 178), "id": ""},   # بومبو
	{"r": Rect2(745, 195, 255, 178), "id": ""},   # زيكو
	{"r": Rect2(1027, 195, 255, 178), "id": ""},  # روبو
	{"r": Rect2(1308, 195, 262, 178), "id": ""},  # لولو
	{"r": Rect2(447, 390, 271, 175), "id": "fox"},  # فوكسي
	{"r": Rect2(745, 390, 255, 175), "id": ""},   # دينو
	{"r": Rect2(1027, 390, 255, 175), "id": ""},  # بيبو
	{"r": Rect2(1308, 390, 262, 175), "id": ""},  # بطبوط
	{"r": Rect2(442, 580, 276, 192), "id": ""},   # كونغ
	{"r": Rect2(737, 580, 266, 192), "id": ""},   # سوسو
	{"r": Rect2(1022, 580, 262, 192), "id": ""},  # زين
	{"r": Rect2(1302, 580, 270, 192), "id": ""},  # آرثر
]

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


func _build() -> void:
	# --- البطاقات: المتاحة تُختار، وغيرها معتَّمة بوسم
	for c in CARDS:
		var r: Rect2 = c.r
		var id: String = c.id
		if id == "":
			_unavailable(r, 20, 22.0)
		else:
			_hit(r, func():
				Settings.selected_character = id
				Settings.save_settings())

	# --- التبويبات (الكل نشط فقط)
	_unavailable(Rect2(412, 110, 388, 76), 18, 0.0, true, 0.88)
	_unavailable(Rect2(810, 110, 385, 76), 18, 0.0, true, 0.88)

	# --- أسهم تبديل الشخصية (لا توجد شخصيات أخرى بعد)
	_unavailable(Rect2(36, 420, 66, 84), 10, 0.0, false)
	_unavailable(Rect2(332, 420, 66, 84), 10, 0.0, false)

	# --- عدّاد العملات الحقيقي فوق الرقم المرسوم
	var strip := Image.create(1, 38, false, Image.FORMAT_RGBA8)
	for i in range(38):
		strip.set_pixel(0, i, _bg_img.get_pixel(1184, 30 + i))
	var pt := TextureRect.new()
	pt.texture = ImageTexture.create_from_image(strip)
	pt.position = Vector2(1186, 30)
	pt.size = Vector2(98, 38)
	pt.stretch_mode = TextureRect.STRETCH_SCALE
	pt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(pt)
	var coins := UiKit.label(str(Settings.total_coins), 34, Color.WHITE, 4)
	coins.position = Vector2(1186, 26)
	coins.size = Vector2(98, 44)
	coins.clip_text = true
	_root.add_child(coins)
	_unavailable(Rect2(1286, 22, 56, 56), 10, 0.0, false)     # زر + (المتجر)
	_unavailable(Rect2(1352, 20, 212, 62), 16, 0.0, true, 0.9)           # الجواهر

	# --- زر العودة (البيت)
	_hit(Rect2(1572, 12, 90, 90), func():
		closed.emit()
		queue_free())

	# --- ابدأ السباق
	_hit(Rect2(590, 810, 605, 112), func(): start_pressed.emit())
