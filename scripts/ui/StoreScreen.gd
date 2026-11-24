class_name StoreScreen
extends ScreenBase
## المتجر: تبويبان (عملات / جواهر). الشراء الحقيقي والإعلانات غير مفعّلة: أزرار الشراء والمكافأة والشريط بوسم «غير متاح حاليًا».

const TABS := [
	{"img": "res://assets/ui/c_store_coins.webp",
	 "cols": [Vector2(395, 752), Vector2(845, 1200), Vector2(1297, 1670)],
	 "btn": [Vector2(437, 705), Vector2(888, 1157), Vector2(1345, 1618)],
	 "pill": [Vector2(322, 365), Vector2(548, 592)], "bty": [Vector2(368, 420), Vector2(595, 648)],
	 "side_pill": Rect2(90, 535, 175, 60), "side_btn": Rect2(50, 605, 245, 66), "ribbon": Rect2(45, 215, 250, 80),
	 "plus_c": Rect2(1137, 15, 65, 54), "plus_g": Rect2(1538, 20, 65, 49), "tab_c": Rect2(580, 104, 330, 80), "tab_g": Rect2(1090, 104, 330, 80),
	 "amounts": [500, 1500, 3500, 8000, 20000, 50000]},
	{"img": "res://assets/ui/c_store_gems.webp",
	 "cols": [Vector2(360, 720), Vector2(822, 1195), Vector2(1297, 1665)],
	 "btn": [Vector2(405, 680), Vector2(868, 1148), Vector2(1340, 1625)],
	 "pill": [Vector2(308, 350), Vector2(548, 592)], "bty": [Vector2(355, 405), Vector2(595, 640)],
	 "side_pill": Rect2(40, 548, 195, 50), "side_btn": Rect2(35, 600, 205, 65), "ribbon": Rect2(20, 190, 225, 56),
	 "plus_c": Rect2(1132, 15, 67, 54), "plus_g": Rect2(1538, 15, 68, 54), "tab_c": Rect2(580, 100, 330, 80), "tab_g": Rect2(1080, 100, 330, 80),
	 "amounts": [50, 140, 300, 650, 1400, 3000]},
]
const PRICES := ["0.99$", "2.99$", "4.99$", "9.99$", "19.99$", "49.99$"]

var _tab := 0
var _layer: Control


func _init() -> void:
	bg_path = TABS[0].img


func _build() -> void:
	_select(0)


func _select(i: int) -> void:
	_tab = i
	var tb: Dictionary = TABS[i]
	_tex = load(tb.img)
	_bg_rect.texture = _tex
	if _layer:
		_layer.queue_free()
	_layer = Control.new()
	_layer.size = Vector2(W, H)
	_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_layer)
	_host = _layer
	# التبويبان
	txt(Loc.t("العملات"), tb.tab_c, 44, Color.WHITE, Color("0a1a5a"), 7)
	txt(Loc.t("الجواهر"), tb.tab_g, 44, Color.WHITE, Color("3a0a5a"), 7)
	hit(Rect2(450, 92, 480, 100), func(): _select(0))
	hit(Rect2(940, 92, 520, 100), func(): _select(1))
	# الحزم: الكمية في الشريط، والسعر على الزر (معتَّم: الشراء غير مفعّل)
	var n := 0
	for ri in range(2):
		for ci in range(3):
			var c: Vector2 = tb.cols[ci]
			var p: Vector2 = tb.pill[ri]
			var b: Vector2 = tb.btn[ci]
			var by: Vector2 = tb.bty[ri]
			num(UiKit.fmt_int(tb.amounts[n]), Rect2(c.x, p.x - 7, c.y - c.x, p.y - p.x), 36)
			unavailable(Rect2(b.x, by.x, b.y - b.x, by.y - by.x), 20, true, 0.5, 24)
			n += 1
	# مكافأة الإعلان (غير متاحة)
	txt(Loc.t("مكافأة مجانية"), tb.ribbon, 34, Color.WHITE, Color("5a0a10"), 6)
	num("+" + str(25 if i == 0 else 5), tb.side_pill, 34)
	unavailable(tb.side_btn, 18, true, 0.5, 24)
	unavailable(Rect2(100, 715, 1660, 105), 28, true, 0.55, 30)
	topbar(tb.plus_c, tb.plus_g, Rect2(1700, 0, 160, 100), func():
		closed.emit()
		queue_free())


func _plus(tab: int) -> void:
	_select(tab)
