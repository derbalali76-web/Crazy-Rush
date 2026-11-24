class_name TrackSelect
extends ScreenBase
## شاشة «اختر الحلبة»: صور بلا نصوص + نصوص حقيقية. المتاحة للعب: الشلالات فقط؛ الباقي بوسم «غير متاح حاليًا».

signal start_pressed
signal choose_character_pressed

const TRACKS := [
	{"id": "waterfalls", "name": "الشلالات", "img": "res://assets/ui/c_t_waterfalls.webp", "playable": true},
	{"id": "forest", "name": "الغابة", "img": "res://assets/ui/c_t_forest.webp", "playable": false},
	{"id": "desert", "name": "الصحراء", "img": "res://assets/ui/c_t_desert.webp", "playable": false},
	{"id": "city", "name": "المدينة", "img": "res://assets/ui/c_t_city.webp", "playable": false},
	{"id": "snow", "name": "الثلج", "img": "res://assets/ui/c_t_snow.webp", "playable": false},
	{"id": "volcano", "name": "البركان", "img": "res://assets/ui/c_t_volcano.webp", "playable": false},
]
## مستطيلات الزرّين + (من كشف الصور) لكل حلبة
const PLUS := [
	[Rect2(1407, 19, 54, 41), Rect2(1652, 20, 53, 40)],
	[Rect2(1421, 20, 57, 42), Rect2(1669, 20, 56, 42)],
	[Rect2(1416, 19, 61, 45), Rect2(1665, 19, 62, 45)],
	[Rect2(1411, 20, 55, 41), Rect2(1666, 21, 54, 40)],
	[Rect2(1421, 21, 59, 42), Rect2(1666, 20, 58, 42)],
	[Rect2(1411, 20, 59, 44), Rect2(1663, 20, 60, 44)],
]
const CARDS := [
	Rect2(135, 500, 270, 150), Rect2(425, 500, 240, 150), Rect2(690, 500, 245, 150),
	Rect2(950, 500, 245, 150), Rect2(1215, 500, 245, 150), Rect2(1480, 500, 260, 150),
]

var _sel := 0
var _layer: Control


func _init() -> void:
	bg_path = TRACKS[0].img


func _build() -> void:
	_select(0)


static func _fmt(t: float) -> String:
	if t <= 0.0:
		return "--:--.--"
	var m := int(t) / 60
	return "%02d:%05.2f" % [m, t - m * 60.0]


func _select(i: int) -> void:
	_sel = i
	_tex = load(TRACKS[i].img)
	_bg_rect.texture = _tex
	if _layer:
		_layer.queue_free()
	_layer = Control.new()
	_layer.size = Vector2(W, H)
	_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_layer)
	_host = _layer
	var playable: bool = TRACKS[i].playable
	var tname := Loc.t(TRACKS[i].name)
	txt(Loc.t("اختر الحلبة"), Rect2(700, 12, 420, 80), 56, Color.WHITE, Color("3a0a14"), 9)
	topbar(PLUS[i][0], PLUS[i][1], Rect2(1740, 0, 123, 100))
	# اللوحة الكبيرة واللوحة اليمنى
	txt(Loc.t("حلبة") + " " + tname, Rect2(500, 128, 300, 62), 40, Color.WHITE, Color("0a1a5a"), 7)
	txt(tname, Rect2(1440, 112, 300, 70), 42, Color.WHITE, Color("0a1a5a"), 7)
	num(_fmt(Settings.best_time) if playable else "--:--.--", Rect2(1390, 298, 140, 46), 30)
	num(UiKit.fmt_int(Settings.total_coins) if playable else "--", Rect2(1385, 400, 215, 50), 32)
	unavailable(Rect2(375, 385, 100, 100), 10, false)       # معاينة الفيديو
	# بطاقات الحلبات
	for k in range(CARDS.size()):
		var c: Rect2 = CARDS[k]
		txt(Loc.t(TRACKS[k].name), Rect2(c.position.x + 62, 596, c.size.x - 78, 48), 30, Color.WHITE, Color("0a1a5a"), 6)
		if k != i:
			hit(c, func(): _select(k))
	unavailable(Rect2(25, 520, 95, 110), 10, false)       # سهم يسار
	unavailable(Rect2(1755, 520, 95, 110), 10, false)     # سهم يمين
	# الأزرار السفلية
	txt(Loc.t("البطولات"), Rect2(180, 705, 150, 85), 34, Color.WHITE, Color("2a0a4a"), 6)
	txt(Loc.t("التحديات"), Rect2(480, 705, 165, 85), 34, Color.WHITE, Color("2a0a4a"), 6)
	unavailable(Rect2(45, 700, 290, 95), 14, true, 0.6, 40)
	unavailable(Rect2(350, 700, 305, 95), 14, true, 0.6, 40)
	txt(Loc.t("ابدأ السباق"), Rect2(790, 700, 390, 100), 58, Color.WHITE, Color("0b4a12"), 9)
	txt(Loc.t("اختر الشخصية"), Rect2(1500, 705, 300, 85), 34, Color.WHITE, Color("0a2a6a"), 6)
	hit(Rect2(1330, 700, 485, 95), func(): choose_character_pressed.emit())
	if playable:
		hit(Rect2(670, 685, 645, 130), func(): start_pressed.emit())
	else:
		unavailable(Rect2(670, 685, 645, 130), 30, true, 0.6, 60)


func _plus(tab: int) -> void:
	UiKit.open_store(self, tab)
