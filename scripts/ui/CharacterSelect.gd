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
var BG: Texture2D = Loc.tex("res://assets/ui/select_ref.png")

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
var _tab := 0          # 0 الكل، 1 الأساسية (8)، 2 الأسطورية (4)
var _grid: Control
const LEG_DY := -368.0


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
	var t := UiKit.label(Loc.t(TAG_TEXT), fsize, Color("dfe5ff"), 3)
	t.size = tag.size
	tag.add_child(t)


func _build() -> void:
	_grid = Control.new()
	_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_grid)
	_build_grid()

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
	coins.position = Vector2(1186, 17)
	coins.size = Vector2(98, 44)
	coins.clip_text = true
	_root.add_child(coins)
	_hit(Rect2(1286, 22, 56, 56), func(): UiKit.open_store(self, 0))     # زر + (المتجر)
	UiKit.counter(_root, _bg_img, Rect2(1416, 29, 92, 38), 1418, str(Settings.gems), 30)
	_hit(Rect2(1352, 20, 212, 62), func(): UiKit.open_store(self, 1))    # الجواهر

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
		_hit(ar, func(): _set_focus(_focus + step, step))


func _set_focus(i: int, step := 0) -> void:
	_focus = posmod(i, ORDER.size())
	if step != 0:
		var n := 0
		while _card_rect(_focus).size.x <= 0.0 and n < ORDER.size():
			_focus = posmod(_focus + step, ORDER.size())
			n += 1
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
	# أيقونة قدرة الشخصية بدل أيقونة فوكسي على الشريط
	var disc := _box(Rect2(88, 585, 70, 70), Color("0b2a8a"), Color("ffd54a"), 35, 3)
	var abic := TextureRect.new()
	abic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	abic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	abic.texture = load("res://assets/characters/%s_ability.png" % id) as Texture2D
	abic.position = Vector2(8, 8)
	abic.size = Vector2(54, 54)
	abic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	disc.add_child(abic)
	# أشرطة الإحصاءات (قيم مقترحة) فوق أشرطة فوكسي المرسومة
	var cols: Array = [Color("5cf514"), Color("fae601"), Color("3cc8ff"), Color("fa4efd")]
	var vals := Characters.stats(id)
	for row in range(4):
		var cy: float = [700.0, 748.0, 798.0, 851.0][row]
		_box(Rect2(52, cy - 22, 168, 44), Color(0.02, 0.05, 0.3, 1), Color(0, 0, 0, 0), 14, 0)
		for k in range(6):
			var x0 := 56.0 + k * 26.5
			var on: bool = k < int(vals[row])
			var poly := Polygon2D.new()
			poly.polygon = PackedVector2Array([Vector2(x0 + 7, cy - 13), Vector2(x0 + 27, cy - 13), Vector2(x0 + 20, cy + 13), Vector2(x0, cy + 13)])
			poly.color = cols[row] if on else Color(0.25, 0.28, 0.4, 0.9)
			_dyn.add_child(poly)
	# إطار تمييز على البطاقة المحدَّدة
	var fr := _card_rect(_focus)
	if fr.size.x > 0.0:
		_box(fr, Color(0, 0, 0, 0), Color("ffd54a"), 26, 5)
	if not playable:
		_unavailable(Rect2(590, 810, 605, 112), 26, 0.0, true, 0.6)
	_root = keep


# ------------------------------------------------------------------ التبويبات والشبكة
func _in_tab(i: int) -> bool:
	return _tab == 0 or (_tab == 1 and i < 8) or (_tab == 2 and i >= 8)


## مستطيل البطاقة كما تظهر في التبويب الحالي (حجم صفر = مخفية)
func _card_rect(i: int) -> Rect2:
	if not _in_tab(i):
		return Rect2()
	var r: Rect2 = CARDS[i].r
	if _tab == 2:
		r.position.y += LEG_DY
	return r


func _build_grid() -> void:
	for c in _grid.get_children():
		_grid.remove_child(c)
		c.queue_free()
	var keep := _root
	_root = _grid
	# تغطية البطاقات غير المعروضة بلون اللوحة، ورسم الصف الأسطوري في الأعلى عند تبويبه
	var panel := Color("1c2a84")
	if _tab == 1:
		_box(Rect2(437, 563, 1140, 213), panel, Color(0, 0, 0, 0), 0, 0)
		_soon(Loc.t("المزيد من الشخصيات قريبًا"), Rect2(437, 567, 1140, 209))
	elif _tab == 2:
		_box(Rect2(437, 183, 1140, 593), panel, Color(0, 0, 0, 0), 0, 0)
		var at := AtlasTexture.new()
		at.atlas = BG
		at.region = Rect2(437, 566, 1140, 210)
		var tr := TextureRect.new()
		tr.texture = at
		tr.position = Vector2(437, 566 + LEG_DY)
		tr.size = Vector2(1140, 210)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_grid.add_child(tr)
		_soon(Loc.t("المزيد من الأساطير قريبًا"), Rect2(437, 420, 1140, 340))
	for i in range(CARDS.size()):
		var r := _card_rect(i)
		if r.size.x <= 0.0:
			continue
		var id: String = CARDS[i].id
		if id == "":
			_unavailable(r, 20, 22.0)
		_hit(r, func():
			if id != "":
				Settings.selected_character = id
				Settings.save_settings()
			_set_focus(i))
	# التبويبات الثلاثة (نُعيد رسمها لتتبدّل حالتها)
	var tabs := [
		[Rect2(1205, 108, 325, 80), Loc.t("الكل (12)"), 0],
		[Rect2(810, 108, 385, 80), Loc.t("الشخصيات الأساسية (8)"), 1],
		[Rect2(412, 108, 388, 80), Loc.t("الشخصيات الأسطورية (4)"), 2],
	]
	for t in tabs:
		var rr: Rect2 = t[0]
		var act: bool = t[2] == _tab
		var bx := _box(rr, Color("f8b81a") if act else Color("141d5c"), Color("ffe48a") if act else Color("5a68b8"), 30, 4)
		var tl := UiKit.bold_label(t[1], 30, Color.WHITE if act else Color("c9d2ff"), Color("5a2d00") if act else Color("0a1040"), 6)
		tl.size = bx.size
		tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		bx.add_child(tl)
		var which: int = t[2]
		_hit(rr, func(): _set_tab(which))
	_root = keep


func _soon(text: String, r: Rect2) -> void:
	var l := UiKit.bold_label(text, 44, Color("8f9be0"), Color("0a1040"), 6)
	l.position = r.position
	l.size = r.size
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_grid.add_child(l)


func _set_tab(t: int) -> void:
	if t == _tab:
		return
	_tab = t
	_build_grid()
	if _card_rect(_focus).size.x <= 0.0:
		_set_focus(_focus, 1)
	else:
		_refresh()
