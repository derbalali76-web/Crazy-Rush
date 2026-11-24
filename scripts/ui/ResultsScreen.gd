class_name ResultsScreen
extends ScreenBase
## شاشة نتائج السباق: صورة بلا نصوص (منصّة بلا شخصيات)؛ الشخصيات والأسماء والأزمنة والمكافآت حقيقية.
## الشخصيات تأتي من سجلّ Characters (entry.character، وإلا فوكسي).

signal restart_pressed
signal home_pressed

const ROWS := [210.0, 273.0, 335.0, 397.0]
const ROW_H := 54.0
## منصّة التتويج: {x مركز الشخصية، y القدمين، الارتفاع الأقصى، العرض الأقصى}
const PODIUM := [
	{"x": 985.0, "y": 326.0, "h": 235.0, "w": 260.0},   # الأول
	{"x": 742.0, "y": 352.0, "h": 190.0, "w": 210.0},   # الثاني
	{"x": 1318.0, "y": 358.0, "h": 190.0, "w": 210.0},  # الثالث
]

var data: Dictionary = {}


func _init() -> void:
	bg_path = "res://assets/ui/c_results.webp"


func _build() -> void:
	var st: Array = data.get("standings", [])
	txt(Loc.t("نتيجة السباق"), Rect2(660, 28, 540, 92), 66, Color.WHITE, Color("0a1a5a"), 9)
	# منصّة التتويج بشخصياتنا (أول ثلاثة في الترتيب)
	for k in range(mini(3, st.size())):
		var pd: Dictionary = PODIUM[k]
		var tex := Characters.portrait(str(st[k].get("character", "fox")))
		if tex == null:
			continue
		var ts := tex.get_size()
		var sc := minf(float(pd.h) / ts.y, float(pd.w) / ts.x)
		var tr := TextureRect.new()
		tr.texture = tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		tr.size = ts * sc
		tr.position = Vector2(float(pd.x) - tr.size.x * 0.5, float(pd.y) - tr.size.y)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_root.add_child(tr)
	# المكافآت
	txt(Loc.t("مكافآتك"), Rect2(870, 418, 370, 54), 38, Color.WHITE, Color("0a1a5a"), 7)
	num("%d" % int(data.get("coins", 0)), Rect2(800, 486, 240, 62), 44)
	num("0", Rect2(1285, 486, 190, 62), 44)
	unavailable(Rect2(1095, 480, 390, 74), 20, true, 0.5, 30)           # الجواهر غير مكتسبة بعد
	txt(Loc.t("شاهد إعلانًا لمضاعفة العملات"), Rect2(820, 585, 620, 66), 32, Color.WHITE, Color("0b4a12"), 6)
	unavailable(Rect2(650, 570, 830, 96), 26, true, 0.78, 40)
	if data.get("new_best", false):
		txt(Loc.t("رقم قياسي جديد!"), Rect2(1330, 150, 300, 50), 30, Color("fff3a0"), Color("5a3a00"), 7)
	# جدول الترتيب
	for k in range(mini(st.size(), ROWS.size())):
		_row(k, st[k])
	# الأزرار
	txt(Loc.t("التالي"), Rect2(1080, 715, 160, 80), 40, Color.WHITE, Color("0b4a12"), 7)
	hit(Rect2(375, 705, 240, 105), func(): home_pressed.emit())
	hit(Rect2(680, 705, 300, 105), func(): restart_pressed.emit())
	unavailable(Rect2(1050, 705, 430, 105), 24, true, 0.78, 50)       # التالي: حلبة واحدة حاليًا
	var perf := "FPS %.0f  •  p95 %.0f ms  •  %s" % [float(data.get("avg_fps", 0)), float(data.get("p95_ms", 0)), str(data.get("quality", ""))]
	txt(perf, Rect2(1450, 6, 400, 28), 16, Color("c9ffd6"), Color("0a1a5a"), 4, false, HORIZONTAL_ALIGNMENT_RIGHT)


func _row(k: int, e: Dictionary) -> void:
	var c: float = ROWS[k]
	var is_player: bool = bool(e.get("player", false))
	txt(str(k + 1), Rect2(118, c - 28, 58, 56), 40, Color.WHITE, Color("3a1a00"), 6)
	# الشخصية فوق الأفاتار المرسوم
	var frame := box(Rect2(180, c - 28, 82, 56), Color("f6b81c") if k == 0 else Color("1d3fa8"), Color.WHITE, 20, 3)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ic := Characters.icon(str(e.get("character", Settings.selected_character if is_player else "fox")))
	if ic:
		var tr := TextureRect.new()
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture = ic
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		tr.size = Vector2(54, 54)
		tr.position = Vector2(194, c - 27)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_root.add_child(tr)
	txt(str(e.get("name", "")), Rect2(270, c - 27, 150, 54), 30, Color.WHITE, Color("0a1a5a"), 5)
	txt(str(e.get("time_text", "")), Rect2(418, c - 27, 130, 54), 26, Color.WHITE, Color("0a1a5a"), 5)
	if is_player:
		var ring := box(Rect2(112, c - 31, 440, 62), Color(0, 0, 0, 0), Color.WHITE, 28, 4)
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
