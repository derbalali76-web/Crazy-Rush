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
const ORDER := ["bombo", "ziko", "robo", "lulu", "fox", "dino", "bibo", "batboot", "kung", "sosu", "zain", "arthur"]
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
var _dyn: Control
var _focus := 0


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
	for i in range(CARDS.size()):
		var r: Rect2 = CARDS[i].r
		var id: String = CARDS[i].id
		if id == "":
			_unavailable(r, 20, 22.0)
		_hit(r, func():
			if id != "":
				Settings.selected_character = id
				Settings.save_settings()
			_set_focus(i))

	# --- التبويبات (الكل نشط فقط)
	_unavailable(Rect2(412, 110, 388, 76), 18, 0.0, true, 0.88)
	_unavailable(Rect2(810, 110, 385, 76), 18, 0.0, true, 0.88)

	# --- أسهم تبديل الشخصية (لا توجد شخصيات أخرى بعد)

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
	var coins := UiKit.num_label(str(Settings.total_coins), 34)
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

	_dyn = Control.new()
	_dyn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_dyn)
	_focus = maxi(0, ORDER.find(Settings.selected_character))
	_refresh()
	# الأسهم فوق لوحة المعاينة دائمًا
	for a in [[Rect2(36, 420, 66, 84), "‹", -1], [Rect2(332, 420, 66, 84), "›", 1]]:
		var ar: Rect2 = a[0]
		var step: int = a[2]
		var bx := _box(ar, Color(0.15, 0.12, 0.05, 0.85), Color("f3b63a"), 18, 3)
		var gl := UiKit.label(a[1], 54, Color("ffd54a"), 4)
		gl.size = bx.size
		bx.add_child(gl)
		_hit(ar, func(): _set_focus(_focus + step))


func _set_focus(i: int) -> void:
	_focus = posmod(i, ORDER.size())
	_refresh()


## يعرض الشخصية المحدَّدة في اللوحة اليسرى؛ غير القابلة للعب تُعتَّم بوسم.
func _refresh() -> void:
	for c in _dyn.get_children():
		c.queue_free()
	var id: String = ORDER[_focus]
	var playable: bool = Characters.is_playable(id)
	if id == "fox":
		return
	var keep := _root
	_root = _dyn
	# خلفية اللوحة + الصورة + الشريط + الإحصاءات
	_box(Rect2(34, 128, 372, 440), Color(0.05, 0.08, 0.26, 0.96), Color("f3b63a"), 28, 4)
	var tex := Characters.portrait(id)
	var tr := TextureRect.new()
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.texture = tex
	tr.position = Vector2(54, 140)
	tr.size = Vector2(332, 416)
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dyn.add_child(tr)
	_unavailable(Rect2(34, 128, 372, 440), 22, -190.0, true, 0.2)
	var nme := Characters.character_name(id)
	UiKit.name_tag(_dyn, _bg_img, Rect2(160, 596, 204, 52), 156, nme, 34 if nme.length() < 12 else 28, Color("2a0a40"))
	_unavailable(Rect2(26, 664, 392, 240), 22, 0.0, true, 0.82)
	# إطار تمييز على البطاقة المحدَّدة
	_box(CARDS[_focus].r, Color(0, 0, 0, 0), Color("ffd54a"), 26, 5)
	if not playable:
		_unavailable(Rect2(590, 810, 605, 112), 26, 0.0, true, 0.6)
	_root = keep
