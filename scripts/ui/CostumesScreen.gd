class_name CostumesScreen
extends Control
## شاشة الأزياء (مرجع: صفحة «المتجر» في ملف التصميم) — مبنية بعناصر Godot حقيقية حادّة لا بصورة مقصوصة.
## فقط الصور (الشخصية ومصغّرات الأزياء) من الملف المرجعي؛ المتاح الآن: الزي «الأساسي» (مُلبَّس).
## بقية الأزياء والشراء والمعاينة والتبويبات معتَّمة بوسم «غير متاح حاليًا» حتى يُبنى الزي على نموذج فوكسي.

signal closed

const W := 1672.0
const H := 941.0
const TAG_TEXT := "غير متاح حاليًا"
const REF := preload("res://assets/ui/select_ref.png")
const MENU_REF := preload("res://assets/ui/menu_ref.png")

## الترتيب كما في المرجع: يسار→يمين، الصف الأول ثم الثاني
const ITEMS := [
	{"name": "الأساسي", "price": 0, "desc": "المظهر الأصلي لفوكسي"},
	{"name": "زي القبطان", "price": 3500, "desc": "مظهر بحري أنيق لفوكسي"},
	{"name": "زي الغرب", "price": 3000, "desc": "راعي بقر سريع"},
	{"name": "زي السباق", "price": 4000, "desc": "بطل حلبات السرعة"},
	{"name": "زي الشتاء", "price": 3500, "desc": "دفء وأناقة في الثلج"},
	{"name": "زي الملك", "price": 5000, "desc": "تاج وعباءة ذهبية"},
	{"name": "زي المستقبلي", "price": 4500, "desc": "من عالم الغد"},
	{"name": "قريبًا", "price": -1, "desc": "زي جديد قادم"},
]
const TABS := ["الأزياء", "الانفعالات", "آثار الركض", "عناصر تجميلية"]

var _root: Control
var _dyn: Control
var _focus := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	var vp := get_viewport_rect().size
	set_deferred("size", vp)
	custom_minimum_size = vp
	var img := REF.get_image()
	UiKit.add_backdrop(self, img, vp, W, H)
	var fit := UiKit.fit(vp, W, H)
	_root = Control.new()
	_root.size = Vector2(W, H)
	_root.scale = fit[0]
	_root.position = fit[1]
	add_child(_root)
	# مشهد الخلفية: نسخة ضبابية من الصورة المرجعية (بلا واجهة مقروءة)
	var small := img.duplicate() as Image
	small.resize(40, 22, Image.INTERPOLATE_BILINEAR)
	var bg := TextureRect.new()
	bg.texture = ImageTexture.create_from_image(small)
	bg.size = Vector2(W, H)
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	bg.modulate = Color(0.85, 0.88, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bg)
	_build()


# ---------------------------------------------------------------- أدوات
func _box(parent: Control, r: Rect2, fill: Color, edge: Color, radius := 24, bw := 3, shadow := 0) -> Panel:
	var p := Panel.new()
	p.position = r.position
	p.size = r.size
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = edge
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(radius)
	sb.anti_aliasing = true
	if shadow > 0:
		sb.shadow_color = Color(0, 0, 0, 0.45)
		sb.shadow_size = shadow
		sb.shadow_offset = Vector2(0, 4)
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
	return p


func _hit(r: Rect2, cb: Callable) -> void:
	var b := Button.new()
	b.flat = true
	b.position = r.position
	b.size = r.size
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	_root.add_child(b)


func _text(parent: Control, r: Rect2, s: String, size: int, color := Color.WHITE, outline := Color("1a1040"), ow := 7) -> Label:
	var l := UiKit.bold_label(s, size, color, outline, ow)
	l.position = r.position
	l.size = r.size
	l.clip_text = true
	parent.add_child(l)
	return l


func _tag(parent: Control, r: Rect2, fsize := 20, dy := 0.0, show_tag := true, alpha := 0.55) -> void:
	var cover := _box(parent, r, Color(0.03, 0.05, 0.2, alpha), Color(0, 0, 0, 0), 22, 0)
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	if not show_tag:
		return
	var tw := minf(r.size.x - 10.0, fsize * 7.4)
	var th := fsize * 1.6
	var t := _box(parent, Rect2(r.position + Vector2((r.size.x - tw) * 0.5, (r.size.y - th) * 0.5 + dy), Vector2(tw, th)), Color(0.1, 0.12, 0.3, 0.92), Color("8a93c8"), 14, 2)
	var l := UiKit.label(TAG_TEXT, fsize, Color("dfe5ff"), 3)
	l.size = t.size
	t.add_child(l)


func _round_sprite(src: Texture2D, region: Rect2, r: Rect2) -> void:
	var p := _box(_root, r, Color(0, 0, 0, 0), Color(0, 0, 0, 0), int(r.size.x * 0.5), 0)
	p.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	var at := AtlasTexture.new()
	at.atlas = src
	at.region = region
	var t := TextureRect.new()
	t.texture = at
	t.size = r.size
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(t)


func _sprite(src: Texture2D, region: Rect2, r: Rect2) -> TextureRect:
	var at := AtlasTexture.new()
	at.atlas = src
	at.region = region
	var t := TextureRect.new()
	t.texture = at
	t.position = r.position
	t.size = r.size
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(t)
	return t


# ---------------------------------------------------------------- البناء
func _build() -> void:
	# الشعار (من الصورة المرجعية)
	var lg := TextureRect.new()
	lg.texture = load("res://assets/ui/hud/logo.png") as Texture2D
	lg.position = Vector2(24, 8)
	lg.size = Vector2(260, 144)
	lg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	lg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(lg)

	# شريط العنوان
	_box(_root, Rect2(560, 16, 560, 100), Color("5a1a9a"), Color("ffc233"), 40, 6, 10)
	_text(_root, Rect2(560, 16, 560, 100), "الأزياء", 58, Color.WHITE, Color("2a0a50"), 9)

	# العملات + الجواهر + البيت
	_box(_root, Rect2(1120, 26, 190, 58), Color("0b1f6e"), Color("ffc233"), 29, 4)
	_box(_root, Rect2(1112, 22, 66, 66), Color("ffc400"), Color("a86a00"), 33, 5, 4)
	_box(_root, Rect2(1126, 36, 38, 38), Color("ffdf5a"), Color("e8a000"), 19, 3)
	var coins := UiKit.num_label(str(Settings.total_coins), 34)
	coins.position = Vector2(1180, 26)
	coins.size = Vector2(100, 58)
	_root.add_child(coins)
	_box(_root, Rect2(1330, 26, 190, 58), Color("0b1f6e"), Color("c85cff"), 29, 4)
	var gem := Polygon2D.new()
	gem.polygon = PackedVector2Array([Vector2(1340, 40), Vector2(1362, 40), Vector2(1376, 56), Vector2(1351, 84), Vector2(1326, 56)])
	gem.color = Color("c85cff")
	_root.add_child(gem)
	var gem2 := Polygon2D.new()
	gem2.polygon = PackedVector2Array([Vector2(1340, 40), Vector2(1351, 56), Vector2(1326, 56)])
	gem2.color = Color("f0b8ff")
	_root.add_child(gem2)
	var gems := UiKit.num_label("0", 34)
	gems.position = Vector2(1390, 26)
	gems.size = Vector2(100, 58)
	_root.add_child(gems)
	_box(_root, Rect2(1566, 12, 94, 94), Color("1d6cf0"), Color("bfe0ff"), 47, 6, 8)
	var house := Polygon2D.new()
	house.polygon = PackedVector2Array([Vector2(1613, 34), Vector2(1642, 60), Vector2(1630, 60), Vector2(1630, 80), Vector2(1596, 80), Vector2(1596, 60), Vector2(1584, 60)])
	house.color = Color.WHITE
	_root.add_child(house)
	_hit(Rect2(1566, 12, 94, 94), func():
		closed.emit()
		queue_free())

	# التبويبات
	for i in range(TABS.size()):
		var tr := Rect2(1200.0 - i * 250.0 - 10.0, 128, 240, 64)
		if i == 0:
			_box(_root, tr, Color("ffb300"), Color("fff0a0"), 28, 4, 6)
			_text(_root, tr, TABS[i], 30, Color.WHITE, Color("6a3a00"), 7)
		else:
			_box(_root, tr, Color("2a2f9e"), Color("6a78e0"), 28, 3)
			_text(_root, tr, TABS[i], 26, Color("c8d0ff"), Color("0a1050"), 6)
			_tag(_root, tr, 16, 0.0, false, 0.5)
	_tag_tabs_note()

	# لوحة الأزياء
	_box(_root, Rect2(450, 205, 1190, 580), Color("1b1b78"), Color("ffc233"), 36, 7, 14)
	_box(_root, Rect2(466, 221, 1158, 548), Color("231f8a"), Color("4a4ac8"), 28, 3)

	# بطاقات الأزياء (الصف الأول والثاني)
	for i in range(ITEMS.size()):
		_card(i)

	# اللوحة اليسرى: منصة المعاينة
	_box(_root, Rect2(40, 140, 390, 520), Color(0.1, 0.1, 0.4, 0.45), Color(1, 1, 1, 0.25), 36, 3)

	_dyn = Control.new()
	_dyn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_dyn)

	# الأسهم (تبديل المعاينة)
	for a in [[Rect2(36, 380, 64, 100), -1, 1], [Rect2(370, 380, 64, 100), 1, -1]]:
		var ar: Rect2 = a[0]
		var step: int = a[1]
		var dirx: float = a[2]
		for w in [[44.0, Color("7a3a00")], [28.0, Color("ffb300")]]:
			var ln := Line2D.new()
			var cx := ar.position.x + ar.size.x * 0.5
			var cy := ar.position.y + ar.size.y * 0.5
			ln.points = PackedVector2Array([Vector2(cx + dirx * 16, cy - 36), Vector2(cx - dirx * 16, cy), Vector2(cx + dirx * 16, cy + 36)])
			ln.width = w[0]
			ln.default_color = w[1]
			ln.joint_mode = Line2D.LINE_JOINT_ROUND
			ln.begin_cap_mode = Line2D.LINE_CAP_ROUND
			ln.end_cap_mode = Line2D.LINE_CAP_ROUND
			_root.add_child(ln)
		_hit(ar, func(): _set_focus(_focus + step))

	_set_focus(0)


func _tag_tabs_note() -> void:
	pass


func _card_rect(i: int) -> Rect2:
	var col := i % 4
	var row := i / 4
	return Rect2(488.0 + col * 286.0, 240.0 + row * 262.0, 268, 244)


func _card(i: int) -> void:
	var it: Dictionary = ITEMS[i]
	var r := _card_rect(i)
	var locked: bool = it.price < 0
	var basic := i == 0
	var card := _box(_root, r, Color("3a3ad0") if not locked else Color("3a1f78"), Color("8aa0ff") if not locked else Color("7a5cc8"), 22, 4, 6)
	card.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	if not locked:
		var tx := load("res://assets/ui/costumes/c%d.png" % i) as Texture2D
		var th := TextureRect.new()
		th.texture = tx
		th.position = Vector2(0, 0)
		th.size = Vector2(r.size.x, 176)
		th.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		th.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		th.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		th.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(th)
	else:
		_text(card, Rect2(0, 40, r.size.x, 80), "؟", 80, Color("b89cff"), Color("1a0a50"), 8)
	# شريط الاسم
	var nb := _box(card, Rect2(0, 176, r.size.x, 68), Color(0.04, 0.05, 0.3, 0.92), Color(0, 0, 0, 0), 0, 0)
	_text(nb, Rect2(0, 0, r.size.x, 32), it.name, 24, Color.WHITE, Color("0a0a40"), 6)
	if basic:
		_text(nb, Rect2(0, 32, r.size.x, 28), "مجانًا", 22, Color("7dff6a"), Color("0a3a0a"), 6)
	elif not locked:
		_text(nb, Rect2(0, 32, r.size.x, 28), _num(it.price), 22, Color("ffd54a"), Color("3a2a00"), 6)
	if not basic:
		_tag(_root, r, 18, -22.0, true, 0.45)
	_hit(r, func(): _set_focus(i))


func _num(n: int) -> String:
	var s := str(n)
	return s.insert(s.length() - 3, ",") if s.length() > 3 else s


func _set_focus(i: int) -> void:
	_focus = posmod(i, ITEMS.size())
	for c in _dyn.get_children():
		c.queue_free()
	var it: Dictionary = ITEMS[_focus]
	var locked: bool = it.price < 0
	var keep := _root
	_root = _dyn
	# صورة المعاينة
	var tex: Texture2D
	var rect := Rect2(60, 150, 350, 450)
	if _focus == 0:
		tex = load("res://assets/characters/fox_portrait.png") as Texture2D
	elif _focus == 1:
		tex = load("res://assets/ui/costumes/preview_pirate.png") as Texture2D
	elif not locked:
		tex = load("res://assets/ui/costumes/c%d.png" % _focus) as Texture2D
	if tex != null:
		var tr := TextureRect.new()
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture = tex
		tr.position = rect.position
		tr.size = rect.size
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_dyn.add_child(tr)
	else:
		_text(_dyn, rect, "؟", 160, Color("b89cff"), Color("1a0a50"), 10)
	if _focus != 0:
		_tag(_dyn, Rect2(60, 150, 350, 450), 22, -150.0, true, 0.15)
	# شريط الاسم والوصف
	_box(_dyn, Rect2(50, 680, 370, 120), Color("4a1a9a"), Color("ffc233"), 34, 5, 8)
	_text(_dyn, Rect2(50, 686, 370, 56), it.name, 38, Color("ffe28a"), Color("2a0a50"), 8)
	_text(_dyn, Rect2(60, 742, 350, 44), it.desc, 22, Color("e6dcff"), Color("1a0a50"), 5)
	# إطار تمييز البطاقة
	_box(_dyn, _card_rect(_focus), Color(0, 0, 0, 0), Color("ff7ae0"), 22, 6)
	# الأزرار السفلية
	if _focus == 0:
		_box(_dyn, Rect2(560, 805, 520, 100), Color("1fa83a"), Color("b8ff9a"), 46, 6, 10)
		_text(_dyn, Rect2(560, 805, 520, 100), "ملبوس", 44, Color.WHITE, Color("0a4a14"), 9)
	else:
		_box(_dyn, Rect2(470, 805, 350, 100), Color("6a2ad8"), Color("d8b8ff"), 46, 6, 10)
		_text(_dyn, Rect2(470, 805, 350, 100), "معاينة", 42, Color.WHITE, Color("2a0a60"), 9)
		var price := "شراء  " + (_num(it.price) if not locked else "—")
		_box(_dyn, Rect2(860, 805, 440, 100), Color("ffa800"), Color("fff0a0"), 46, 6, 10)
		_text(_dyn, Rect2(860, 805, 440, 100), price, 42, Color.WHITE, Color("6a3a00"), 9)
		_tag(_dyn, Rect2(470, 805, 830, 100), 22, -78.0, true, 0.5)
	_root = keep
