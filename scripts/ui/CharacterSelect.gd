class_name CharacterSelect
extends ScreenBase
## شاشة «اختر المتسابق»: صورة بلا نصوص + نصوص حقيقية. المتاح للعب: فوكسي فقط؛ بقية الشخصيات تُعرض معتَّمة بوسم.
## أضف شخصية: سجّلها في Characters.LIST ثم فعّلها بـ playable.

signal start_pressed

const ORDER := ["bombo", "ziko", "robo", "lulu", "fox", "dino", "bibo", "batboot", "kung", "sosu", "zain", "arthur"]
const CARDS := [
	{"r": Rect2(437, 195, 273, 172), "id": "bombo", "bar": 326},
	{"r": Rect2(735, 195, 260, 172), "id": "ziko", "bar": 326},
	{"r": Rect2(1018, 195, 257, 172), "id": "robo", "bar": 326},
	{"r": Rect2(1300, 195, 265, 172), "id": "lulu", "bar": 326},
	{"r": Rect2(437, 382, 273, 160), "id": "fox", "bar": 492},
	{"r": Rect2(735, 382, 260, 160), "id": "dino", "bar": 492},
	{"r": Rect2(1018, 382, 257, 160), "id": "bibo", "bar": 492},
	{"r": Rect2(1300, 382, 265, 160), "id": "batboot", "bar": 492},
	{"r": Rect2(435, 548, 276, 195), "id": "kung", "bar": 690},
	{"r": Rect2(730, 548, 266, 195), "id": "sosu", "bar": 690},
	{"r": Rect2(1015, 548, 262, 195), "id": "zain", "bar": 690},
	{"r": Rect2(1298, 548, 270, 195), "id": "arthur", "bar": 690},
]
const LEG_DY := -355.0
const PANEL := Color8(3, 20, 108)

var _dyn: Control
var _grid: Control
var _focus := 0
var _tab := 0          # 0 الكل، 1 الأساسية (8)، 2 الأسطورية (4)


func _init() -> void:
	bg_path = "res://assets/ui/c_select.webp"


func _build() -> void:
	_grid = Control.new()
	_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_grid)
	_build_grid()
	txt(Loc.t("اختر المتسابق"), Rect2(660, 12, 380, 82), 56, Color.WHITE, Color("2a0a4a"), 9)
	topbar(Rect2(1273, 26, 50, 42), Rect2(1499, 26, 51, 44), Rect2(1565, 0, 106, 110))
	# أسماء الإحصاءات
	var names := ["السرعة", "التسارع", "التحكم", "الطاقة"]
	for r in range(4):
		var cy: float = [665.0, 714.0, 764.0, 815.0][r]
		txt(Loc.t(names[r]), Rect2(292, cy - 22, 112, 44), 24, Color.WHITE, Color("0a1a5a"), 4)
	# ابدأ السباق
	txt(Loc.t("ابدأ السباق"), Rect2(770, 790, 310, 92), 52, Color("4a2400"), Color.WHITE, 5)
	hit(Rect2(580, 775, 625, 115), func(): start_pressed.emit())
	_dyn = Control.new()
	_dyn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_dyn)
	_focus = maxi(0, ORDER.find(Settings.selected_character))
	_refresh()
	for a in [[Rect2(38, 412, 64, 76), -1], [Rect2(328, 412, 64, 76), 1]]:
		var step: int = a[1]
		hit(a[0], func(): _set_focus(_focus + step, step))


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
	var keep := _host
	_host = _dyn
	if id != "fox":
		box(Rect2(34, 128, 372, 420), Color(0.05, 0.08, 0.26, 0.97), Color("f3b63a"), 28, 4)
		var tr := TextureRect.new()
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture = Characters.portrait(id)
		tr.position = Vector2(54, 140)
		tr.size = Vector2(332, 392)
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_dyn.add_child(tr)
		unavailable(Rect2(34, 128, 372, 420), 22, true, 0.2)
		for a in [[Rect2(38, 412, 64, 76), "‹"], [Rect2(328, 412, 64, 76), "›"]]:
			var ar: Rect2 = a[0]
			var bx := box(ar, Color(0.15, 0.12, 0.05, 0.85), Color("f3b63a"), 18, 3)
			var gl := UiKit.label(a[1], 54, Color("ffd54a"), 4)
			gl.size = bx.size
			bx.add_child(gl)
	txt(Characters.character_name(id), Rect2(100, 558, 250, 58), 36, Color.WHITE, Color("2a0a40"), 6)
	# أشرطة الإحصاءات (تغطي الأشرطة المرسومة وتُرسم بقيم الشخصية)
	var cols: Array = [Color("5cf514"), Color("fae601"), Color("3cc8ff"), Color("fa4efd")]
	var vals := Characters.stats(id)
	for row in range(4):
		var cy: float = [665.0, 714.0, 764.0, 815.0][row]
		box(Rect2(48, cy - 22, 176, 44), Color(0.02, 0.05, 0.3, 1), Color(0, 0, 0, 0), 14, 0)
		for k in range(6):
			var x0 := 54.0 + k * 27.0
			var on: bool = k < int(vals[row])
			var poly := Polygon2D.new()
			poly.polygon = PackedVector2Array([Vector2(x0 + 7, cy - 13), Vector2(x0 + 27, cy - 13), Vector2(x0 + 20, cy + 13), Vector2(x0, cy + 13)])
			poly.color = cols[row] if on else Color(0.25, 0.28, 0.4, 0.9)
			_dyn.add_child(poly)
	var fr := _card_rect(_focus)
	if fr.size.x > 0.0:
		box(fr, Color(0, 0, 0, 0), Color("ffd54a"), 26, 5)
	if not playable:
		unavailable(Rect2(580, 775, 625, 115), 26, true, 0.6, 50)
	_host = keep


# ------------------------------------------------------------------ التبويبات والشبكة
func _in_tab(i: int) -> bool:
	return _tab == 0 or (_tab == 1 and i < 8) or (_tab == 2 and i >= 8)


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
	var keep := _host
	_host = _grid
	if _tab == 1:
		box(Rect2(420, 545, 1160, 215), PANEL, Color(0, 0, 0, 0), 0, 0)
		_soon(Loc.t("المزيد من الشخصيات قريبًا"), Rect2(420, 548, 1160, 209))
	elif _tab == 2:
		box(Rect2(420, 190, 1160, 570), PANEL, Color(0, 0, 0, 0), 0, 0)
		var at := AtlasTexture.new()
		at.atlas = _tex
		at.region = Rect2(420, 538, 1160, 222)
		var tr := TextureRect.new()
		tr.texture = at
		tr.position = Vector2(420, 538 + LEG_DY)
		tr.size = Vector2(1160, 222)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_grid.add_child(tr)
		_soon(Loc.t("المزيد من الأساطير قريبًا"), Rect2(420, 400, 1160, 340))
	for i in range(CARDS.size()):
		var r := _card_rect(i)
		if r.size.x <= 0.0:
			continue
		var id: String = CARDS[i].id
		var by: float = CARDS[i].bar + (LEG_DY if _tab == 2 else 0.0)
		txt(Characters.short_name(id), Rect2(r.position.x + 70, by, r.size.x - 84, 40), 28, Color.WHITE, Color("0a1a5a"), 5)
		if id != "fox":
			unavailable(r, 20, true, 0.35)
		hit(r, func():
			if id == "fox":
				Settings.selected_character = id
				Settings.save_settings()
			_set_focus(i))
	var tabs := [
		[Rect2(1195, 108, 335, 80), Loc.t("الكل (12)"), 0],
		[Rect2(805, 108, 385, 80), Loc.t("الشخصيات الأساسية (8)"), 1],
		[Rect2(405, 108, 392, 80), Loc.t("الشخصيات الأسطورية (4)"), 2],
	]
	for t in tabs:
		var rr: Rect2 = t[0]
		var act: bool = t[2] == _tab
		box(rr, Color("f8b81a") if act else Color("141d5c"), Color("ffe48a") if act else Color("5a68b8"), 32, 4)
		txt(t[1], rr, 30, Color.WHITE if act else Color("c9d2ff"), Color("5a2d00") if act else Color("0a1040"), 6)
		var which: int = t[2]
		hit(rr, func(): _set_tab(which))
	_host = keep


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
