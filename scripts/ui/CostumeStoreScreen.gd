class_name CostumeStoreScreen
extends ScreenBase
## متجر أزياء الشخصية على صور بلا نصوص: الأسماء والأسعار والتبويبات بلغة اللعبة.
## المتاح: الأساسي لفوكسي فقط؛ بقية الأزياء والشراء والمعاينة بوسم «غير متاح حاليًا».

signal start_pressed

const ORDER := ["fox", "bombo", "ziko", "robo", "lulu", "dino", "bibo", "batboot", "kung", "sosu", "zain", "arthur"]
const PRICES := [3500, 3000, 4000, 3500, 5000, 4500]
## cx: مراكز أعمدة البطاقات، y: مركز سطر السعر لكل صف، coin: هل الأيقونة مرسومة في الصورة
const LAYOUT := {
	"bombo": {"cx": [898, 1272, 1640], "y": [420, 672], "coin": false, "plus": [Rect2(1334, 27, 56, 48), Rect2(1614, 27, 55, 48)]},
	"ziko": {"cx": [910, 1267, 1634], "y": [411, 658], "coin": true, "plus": [Rect2(1344, 23, 66, 54), Rect2(1622, 24, 66, 52)]},
	"robo": {"cx": [904, 1270, 1640], "y": [411, 657], "coin": true, "plus": [Rect2(1342, 20, 62, 53), Rect2(1619, 20, 63, 53)]},
	"lulu": {"cx": [909, 1274, 1643], "y": [411, 659], "coin": true, "plus": [Rect2(1338, 22, 60, 52), Rect2(1619, 22, 61, 52)]},
	"dino": {"cx": [925, 1284, 1643], "y": [407, 650], "coin": true, "plus": [Rect2(1350, 22, 63, 51), Rect2(1632, 22, 63, 51)]},
	"bibo": {"cx": [913, 1276, 1650], "y": [412, 662], "coin": true, "plus": [Rect2(1339, 22, 60, 52), Rect2(1618, 24, 61, 50)]},
	"batboot": {"cx": [908, 1275, 1636], "y": [414, 665], "coin": true, "plus": [Rect2(1338, 24, 60, 51), Rect2(1620, 24, 61, 50)]},
	"kung": {"cx": [912, 1280, 1665], "y": [422, 668], "coin": true, "plus": [Rect2(1334, 23, 60, 50), Rect2(1616, 26, 60, 47)]},
	"sosu": {"cx": [946, 1314, 1682], "y": [430, 681], "coin": true, "plus": [Rect2(1362, 24, 61, 56), Rect2(1634, 24, 61, 56)]},
	"zain": {"cx": [943, 1317, 1685], "y": [408, 654], "coin": true, "plus": [Rect2(1337, 31, 55, 48), Rect2(1628, 30, 56, 49)]},
	"arthur": {"cx": [920, 1283, 1653], "y": [445, 708], "coin": false, "plus": [Rect2(1353, 29, 60, 46), Rect2(1631, 26, 60, 49)]},
}
const BAR_DY := {"arthur": 14, "sosu": 8, "zain": 4, "bombo": 2}
const FOX_CX := [873, 1146, 1415, 1688]
const FOX_Y := [412, 648]
const FOX_NAMES := ["الأساسي", "زي القبطان", "زي الغرب", "زي السباق", "زي الشتاء", "زي الملكي", "زي المستقبلي"]
const COSTUMES := {
	"bombo": ["زي الحارس الملكي", "زي الفايكينغ", "زي الملاكم الذهبي", "زي الشتاء", "زي الساموراي", "زي رائد الفضاء"],
	"ziko": ["زي النينجا الأحمر", "زي الظل الأسود", "زي التنين", "زي الثلج", "زي الساموراي الذهبي", "زي النينجا السيبراني"],
	"robo": ["زي الروبوت الفضي", "زي الروبوت الحربي", "زي الفارس الآلي", "زي الجليد", "زي الذهبي", "زي الفضاء"],
	"lulu": ["زي الساحرة الحمراء", "زي ساحرة الغابة", "زي ساحرة النجوم", "زي ساحرة الثلج", "زي الملكة", "زي ساحرة المستقبل"],
	"dino": ["زي المستكشف", "زي الفارس", "زي الديناصور الملكي", "زي الثلج", "زي الباحث عن الكنز", "زي الفضاء"],
	"bibo": ["زي أرنب الربيع", "زي أرنب الجزرة", "زي أرنب السباق", "زي أرنب الشتاء", "زي أرنب الأميرة", "زي أرنب المستقبل"],
	"batboot": ["زي الأدميرال", "زي القرصان الأسود", "زي البحار", "زي القطب", "زي الملك البحري", "زي الغواص"],
	"kung": ["زي المعلم", "زي الجنرال", "زي التنين الأحمر", "زي الثلج", "زي الإمبراطور", "زي الباندا الأسود"],
	"sosu": ["زي العنقاء الذهبية", "زي عنقاء اللهب", "زي الأميرة النارية", "زي عنقاء الجليد", "زي الملكة", "زي عنقاء الفجر"],
	"zain": ["زي البرق الأزرق", "زي العاصفة", "زي البطل الأسود", "زي الجليد", "زي الملك", "زي الفضاء"],
	"arthur": ["زي الملك الأبيض", "زي الذئب القطبي", "زي الفارس الجليدي", "زي الشتاء الأزرق", "زي العرش الذهبي", "زي ذئب العاصفة"],
}

var char_id := "fox"


static func has_store(id: String) -> bool:
	return id in ORDER


func _ready() -> void:
	bg_path = "res://assets/ui/cs_%s.webp" % char_id
	super._ready()


func _switch(id: String) -> void:
	char_id = id
	bg_path = "res://assets/ui/cs_%s.webp" % id
	_tex = load(bg_path)
	_bg_img = _tex.get_image()
	_bg_rect.texture = _tex
	for c in _root.get_children():
		if c != _bg_rect:
			c.queue_free()
	_host = _root
	_build()


func _step(d: int) -> void:
	_switch(ORDER[posmod(ORDER.find(char_id) + d, ORDER.size())])


func _coin(c: Vector2) -> void:
	var o := box(Rect2(c.x - 19, c.y - 19, 38, 38), Color("ffc928"), Color("b87400"), 19, 3)
	var i := box(Rect2(c.x - 11, c.y - 11, 22, 22), Color("ffe15a"), Color("e0a010"), 11, 2)
	o.mouse_filter = Control.MOUSE_FILTER_IGNORE
	i.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _price(cx: float, y: float, price: int, draw_coin: bool, size := 30, coin_dx := 46.0) -> void:
	if draw_coin:
		_coin(Vector2(cx - coin_dx, y))
	num(UiKit.fmt_int(price), Rect2(cx - coin_dx + 22, y - 20, 104, 40), size)


func _build() -> void:
	var fox := char_id == "fox"
	var plus: Array = [Rect2(1327, 29, 54, 44), Rect2(1617, 30, 55, 43)] if fox else LAYOUT[char_id]["plus"]
	topbar(plus[0], plus[1], Rect2(1700, 0, 130, 100))
	txt(Loc.t("المتجر"), Rect2(800, 22, 250, 66), 46, Color.WHITE, Color("3a0a70"), 7)
	# التبويبات
	txt(Loc.t("الأزياء"), Rect2(1675, 122, 155, 62), 34, Color.WHITE, Color("6a3a00"), 6)
	# التبويبات غير الفعّالة: يحلّ الوسم محل الاسم بجانب الأيقونة
	unavailable(Rect2(1375, 118, 175, 70), 17, true, 0.45, 28)
	unavailable(Rect2(1095, 118, 180, 70), 17, true, 0.45, 28)
	unavailable(Rect2(800, 118, 190, 70), 17, true, 0.45, 28)
	unavailable(Rect2(1280, 116, 95, 76), 17, false, 0.45, 30)
	unavailable(Rect2(995, 116, 100, 76), 17, false, 0.45, 30)
	unavailable(Rect2(695, 116, 105, 76), 17, false, 0.45, 30)
	var sel_price := PRICES[0]
	var bar_name := Characters.character_name(char_id)
	if fox:
		for i in range(7):
			var cx: float = FOX_CX[i % 4]
			var y: float = FOX_Y[i / 4]
			var nm := Loc.t(FOX_NAMES[i])
			if i == 0:
				txt(nm, Rect2(cx - 105, y - 50, 210, 34), 26, Color.WHITE, Color("0a3a3a"), 5)
				txt(Loc.t("مجانًا"), Rect2(cx - 62, y - 16, 130, 32), 24, Color("6dff8a"), Color("0a3a1a"), 5)
				continue
			txt(nm, Rect2(cx - 105, y - 50, 210, 34), 26, Color.WHITE, Color("0a1a5a"), 5)
			_price(cx, y, PRICES[i - 1], false, 26, 22.0)
			unavailable(Rect2(cx - 124, y - 190, 248, 236), 15, true, 0.25, 26)
		txt(Loc.t("قريبًا"), Rect2(1565, 600, 250, 50), 34)
		unavailable(Rect2(1565, 460, 252, 225), 15, false, 0.15, 26)
		sel_price = PRICES[0]
		bar_name = Loc.t(FOX_NAMES[1])
		txt(bar_name, Rect2(250, 733, 340, 50), 38, Color("ffd54a"), Color("3a1a00"), 8)
		txt(Loc.t("مظهر بحري أنيق لفوكسي"), Rect2(250, 782, 340, 34), 22, Color.WHITE, Color("0a1a5a"), 4)
		txt(Characters.short_name("fox"), Rect2(28, 312, 128, 36), 24, Color.WHITE, Color("0a1a5a"), 5)
	else:
		var L: Dictionary = LAYOUT[char_id]
		for i in range(6):
			var cx: float = L["cx"][i % 3]
			var y: float = L["y"][i / 3]
			txt(Loc.t(COSTUMES[char_id][i]), Rect2(cx - 160, y - 49, 320, 36), 28, Color.WHITE, Color("0a1a5a"), 5)
			_price(cx, y, PRICES[i], not L["coin"])
			unavailable(Rect2(cx - 170, y - 210, 340, 250), 16, true, 0.22, 26)
		txt(bar_name, Rect2(245, 735 + BAR_DY.get(char_id, 0), 315, 76), 40, Color("ffd54a"), Color("3a1a00"), 8)
	# معاينة وشراء
	unavailable(Rect2(850, 738, 215, 94), 20, true, 0.4, 40)
	unavailable(Rect2(735, 738, 115, 94), 20, false, 0.4, 40)
	unavailable(Rect2(1065, 738, 90, 94), 20, false, 0.4, 40)
	num(UiKit.fmt_int(sel_price), Rect2(1585, 758, 170, 52), 34)
	unavailable(Rect2(1330, 738, 200, 94), 20, true, 0.4, 40)
	unavailable(Rect2(1190, 738, 140, 94), 20, false, 0.4, 40)
	unavailable(Rect2(1530, 738, 290, 94), 20, false, 0.4, 40)
	# التنقل بين الشخصيات
	hit(Rect2(170, 440, 130, 190), func(): _step(-1))
	hit(Rect2(590, 440, 130, 190), func(): _step(1))
	hit(Rect2(30, 130, 130, 60), func(): _step(-1))
	hit(Rect2(30, 735, 130, 70), func(): _step(1))
