class_name CostumesScreen
extends Control
## شاشة الأزياء: نسخة طبق الأصل من صفحة «المتجر» في ملف التصميم (الصورة مرجعًا) + أزرار حقيقية.
## المتاح: الأساسي (مُلبَّس) والعودة؛ بقية الأزياء والشراء والمعاينة والتبويبات بوسم «غير متاح حاليًا».

signal closed
signal start_pressed

const W := 1672.0
const H := 941.0
const TAG_TEXT := "غير متاح حاليًا"
const IMAGES := {
	"fox": "res://assets/ui/costumes_ref.png",
	"bombo": "res://assets/ui/costumes_bombo_ref.png",
	"ziko": "res://assets/ui/costumes_ziko_ref.png",
	"robo": "res://assets/ui/costumes_robo_ref.png",
	"lulu": "res://assets/ui/costumes_lulu_ref.png",
	"dino": "res://assets/ui/costumes_dino_ref.png",
	"bibo": "res://assets/ui/costumes_bibo_ref.png",
	"batboot": "res://assets/ui/costumes_batboot_ref.png",
	"kung": "res://assets/ui/costumes_kung_ref.png",
	"sosu": "res://assets/ui/costumes_sosu_ref.png",
	"zain": "res://assets/ui/costumes_zain_ref.png",
	"arthur": "res://assets/ui/costumes_arthur_ref.png",
}
const ORDER := ["fox", "bombo", "ziko", "robo", "lulu", "dino", "bibo", "batboot", "kung", "sosu", "zain", "arthur"]

## الشخصيات التي لها صورة متجر جاهزة
static func has_store(id: String) -> bool:
	return IMAGES.has(id)

var char_id := "fox"
var BG: Texture2D

var _root: Control
var _bg_img: Image


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup()


## يعيد بناء الشاشة بصورة أخرى (شخصية أخرى أو تبويب آخر)
func _switch(id: String) -> void:
	char_id = id
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_setup()


func _step_char(d: int) -> void:
	var i := ORDER.find(char_id)
	_switch(ORDER[posmod(i + d, ORDER.size())])


## يفتح المتجر (عملات/جواهر) فوق هذه الشاشة
func _open_store(tab: int) -> void:
	var st := StoreScreen.new()
	add_child(st)
	if tab != 0:
		st._select(tab)


func _setup() -> void:
	BG = Loc.tex(IMAGES.get(char_id, IMAGES["fox"]))
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


func _patch_num(x: float, y: float, w: float, h: float, sample_x: int, text: String) -> void:
	var strip := Image.create(1, int(h), false, Image.FORMAT_RGBA8)
	for i in range(int(h)):
		strip.set_pixel(0, i, _bg_img.get_pixel(sample_x, int(y) + i))
	var pt := TextureRect.new()
	pt.texture = ImageTexture.create_from_image(strip)
	pt.position = Vector2(x, y)
	pt.size = Vector2(w, h)
	pt.stretch_mode = TextureRect.STRETCH_SCALE
	pt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(pt)
	var l := UiKit.num_label(text, 34)
	l.position = Vector2(x - 6, y - 8)
	l.size = Vector2(w, h + 8)
	l.clip_text = true
	_root.add_child(l)


func _build() -> void:
	if char_id.begins_with("m_"):
		_build_missions()
		return
	if char_id.begins_with("r_"):
		_build_ranking()
		return
	if char_id == "tour":
		_build_tour()
		return
	if char_id != "fox":
		_build_bombo()
	else:
		_build_fox()
	# أسهم التبديل بين الشخصيات (فوق المعاينة وأعلى/أسفل القائمة الجانبية)
	_hit(Rect2(160, 480, 110, 160), func(): _step_char(-1))
	_hit(Rect2(570, 480, 110, 160), func(): _step_char(1))
	_hit(Rect2(40, 140, 100, 60), func(): _step_char(-1))
	_hit(Rect2(40, 800, 100, 70), func(): _step_char(1))
	# عدّاد العملات والجواهر يفتحان المتجر
	_hit(Rect2(1030, 26, 250, 66), func(): _open_store(0))
	_hit(Rect2(1285, 26, 250, 66), func(): _open_store(1))
	_hit(Rect2(1560, 22, 96, 92), func():
		closed.emit()
		queue_free())


func _build_bombo() -> void:
	_patch_num(1100, 34, 112, 40, 1100, str(Settings.total_coins))
	_patch_num(1362, 34, 98, 40, 1358, str(Settings.gems))
	if char_id == "ziko":
		_fix_text(Rect2(1345, 678, 272, 38), 1338, 1622, 683, "زي النينجا السيبراني", 28)
	if char_id == "bombo":
		_fix_bombo_name()
	# تصحيح أخطاء إملائية مرسومة في صور المتجر
	var gold := Color("ffd54a")
	var gold_o := Color("3a1a00")
	match char_id:
		"batboot":
			_fix_text(Rect2(252, 782, 250, 56), 246, 504, 782, "كابتن بطبوط", 40, gold, gold_o)
		"robo":
			_fix_text(Rect2(252, 772, 250, 62), 246, 504, 772, "روبو الروبوت", 40, gold, gold_o)
		"bibo":
			_fix_text(Rect2(252, 782, 238, 56), 246, 494, 782, "بيبو الأرنب", 40, gold, gold_o)
			_fix_text(Rect2(732, 142, 148, 40), 728, 888, 142, "عناصر تجميلية", 25, Color.WHITE, Color("2a0a60"))
		"lulu":
			_fix_text(Rect2(1508, 142, 104, 40), 1503, 1622, 142, "الأزياء", 34, Color.WHITE, Color("6a3a00"))
	_build_six()


func _fix_text(r: Rect2, lx: int, rx: int, sy: int, text: String, size: int, color := Color.WHITE, outline := Color("0a0a40")) -> void:
	if not Loc.rtl():
		return
	var strip := Image.create(2, int(r.size.y), false, Image.FORMAT_RGBA8)
	for i in range(int(r.size.y)):
		strip.set_pixel(0, i, _bg_img.get_pixel(lx, sy + i))
		strip.set_pixel(1, i, _bg_img.get_pixel(rx, sy + i))
	var pt := TextureRect.new()
	pt.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	pt.texture = ImageTexture.create_from_image(strip)
	pt.position = r.position
	pt.size = r.size
	pt.stretch_mode = TextureRect.STRETCH_SCALE
	pt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(pt)
	var l := UiKit.bold_label(text, size, color, outline, 7)
	l.position = r.position - Vector2(0, 4)
	l.size = r.size + Vector2(0, 8)
	l.clip_text = true
	_root.add_child(l)


func _fix_bombo_name() -> void:
	if not Loc.rtl():
		return
	# تصحيح الاسم المرسوم («يومبو» ← «بومبو»)
	var strip := Image.create(2, 40, false, Image.FORMAT_RGBA8)
	for i in range(40):
		strip.set_pixel(0, i, _bg_img.get_pixel(240, 794 + i))
		strip.set_pixel(1, i, _bg_img.get_pixel(508, 794 + i))
	var pt := TextureRect.new()
	pt.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	pt.texture = ImageTexture.create_from_image(strip)
	pt.position = Vector2(244, 794)
	pt.size = Vector2(268, 40)
	pt.stretch_mode = TextureRect.STRETCH_SCALE
	pt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(pt)
	var nm := UiKit.bold_label(Loc.t("بومبو الملاكم"), 40, Color("ffd54a"), Color("3a1a00"), 8)
	nm.position = Vector2(244, 788)
	nm.size = Vector2(268, 52)
	nm.clip_text = true
	_root.add_child(nm)


func _build_six() -> void:
	# ست بطاقات: لا يملك المستخدم أيًا منها بعد
	var xs := [1325.0, 1002.0, 680.0]
	for i in range(6):
		_unavailable(Rect2(xs[i % 3], 222.0 + (i / 3) * 278.0, 305, 263), 20, 28.0, true, 0.3)
	_unavailable(Rect2(1160, 128, 236, 76), 15, 0.0, true, 0.6)
	_unavailable(Rect2(905, 128, 245, 76), 15, 0.0, true, 0.6)
	_unavailable(Rect2(652, 128, 240, 76), 15, 0.0, true, 0.6)
	_unavailable(Rect2(678, 802, 355, 112), 20, 0.0, true, 0.55)
	_unavailable(Rect2(1085, 798, 545, 118), 24, 0.0, true, 0.5)


func _build_fox() -> void:
	# أرصدة حقيقية فوق الأرقام المرسومة
	_patch_num(1132, 34, 106, 42, 1236, str(Settings.total_coins))
	_patch_num(1388, 34, 84, 42, 1478, str(Settings.gems))

	# بطاقات الأزياء: الأساسي (أول بطاقة) هو الفعّال فقط
	var xs := [730.0, 960.0, 1190.0, 1420.0]
	for i in range(1, 8):
		_unavailable(Rect2(xs[i % 4], 238.0 + (i / 4) * 256.0, 212, 240), 18, 24.0, true, 0.35)
	# التبويبات غير النشطة
	_unavailable(Rect2(1175, 135, 232, 70), 15, 0.0, true, 0.6)
	_unavailable(Rect2(930, 135, 232, 70), 15, 0.0, true, 0.6)
	_unavailable(Rect2(688, 135, 232, 70), 15, 0.0, true, 0.6)
	# قائمة الشخصيات الجانبية
	# معاينة وشراء
	_unavailable(Rect2(760, 788, 325, 115), 20, 0.0, true, 0.55)
	_unavailable(Rect2(1150, 785, 485, 125), 24, 0.0, true, 0.5)
	# الأسهم والبطاقة الأولى: لا بديل ما دام زي واحد فقط


# ------------------------------------------------------------------ شاشة المهام
const M_ROWS := [262.0, 357.0, 452.0, 547.0, 642.0, 737.0]
var _timer_lbl: Label
var _timer_scope := "day"


func _patch_strip(r: Rect2, sample_x: int) -> void:
	var strip := Image.create(1, int(r.size.y), false, Image.FORMAT_RGBA8)
	for i in range(int(r.size.y)):
		strip.set_pixel(0, i, _bg_img.get_pixel(sample_x, int(r.position.y) + i))
	var pt := TextureRect.new()
	pt.texture = ImageTexture.create_from_image(strip)
	pt.position = r.position
	pt.size = r.size
	pt.stretch_mode = TextureRect.STRETCH_SCALE
	pt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(pt)


func _fmt(n: int) -> String:
	var s := str(n)
	var out := ""
	for i in range(s.length()):
		if i > 0 and (s.length() - i) % 3 == 0:
			out += ","
		out += s[i]
	return out


func _build_missions() -> void:
	var scope := "day" if char_id == "m_day" else "week"
	_timer_scope = scope
	# العدّادان
	_patch_num(1100, 34, 112, 40, 1098, _fmt(Settings.total_coins))
	_patch_num(1366, 34, 100, 40, 1366, str(Settings.gems))
	# الصفوف
	var ds := Missions.defs(scope)
	for i in range(ds.size()):
		var y: float = M_ROWS[i]
		var goal := int(ds[i]["goal"])
		var prog := Missions.progress(scope, i)
		var done := Missions.is_done(scope, i)
		var claimed := Missions.is_claimed(scope, i)
		# شريط التقدّم
		_box(Rect2(928, y - 20, 250, 40), Color("0b1c52"), Color("6f8fe0"), 20, 2)
		if prog > 0:
			var fw := maxf(24.0, 242.0 * float(prog) / float(goal))
			var fill := _box(Rect2(932, y - 16, fw, 32), Color("3fd12c"), Color("a6f27a"), 16, 2)
			fill.size.x = minf(fw, 242.0)
		var t := UiKit.bold_label("%d/%d" % [prog, goal], 26, Color.WHITE, Color("0a1440"), 5)
		t.position = Vector2(928, y - 22)
		t.size = Vector2(250, 44)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_root.add_child(t)
		# زر الحالة
		var txt := Loc.t("جاري")
		var fillc := Color("8b93ad")
		var edge := Color("d5daf0")
		if claimed:
			txt = Loc.t("تم ✓")
			fillc = Color("5c6384")
			edge = Color("9aa2c4")
		elif done:
			txt = Loc.t("استلام")
			fillc = Color("27c43a")
			edge = Color("b6ff8a")
		_box(Rect2(598, y - 35, 158, 70), fillc, edge, 32, 3)
		var bl := UiKit.bold_label(txt, 34, Color.WHITE, Color("1b2350") if not done or claimed else Color("0e5a1c"), 6)
		bl.position = Vector2(598, y - 35)
		bl.size = Vector2(158, 70)
		bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_root.add_child(bl)
		if done and not claimed:
			var idx := i
			_hit(Rect2(598, y - 35, 158, 70), func():
				Missions.claim(scope, idx)
				_switch(char_id))
	# صندوق اليوم/الأسبوع
	var ready := Missions.chest_ready(scope)
	var opened := Missions.chest_opened(scope)
	var ctxt := Loc.t("اضغط لفتح الصندوق!") if ready else (Loc.t("تم فتح الصندوق ✓") if opened else Loc.t("أكمل كل المهام"))
	var cb := _box(Rect2(150, 296, 330, 46), Color("f5b81c") if ready else Color("141d5c"), Color("ffe48a") if ready else Color("5a68b8"), 22, 3)
	var cl := UiKit.bold_label(ctxt, 26, Color.WHITE, Color("5a2d00") if ready else Color("0a1040"), 5)
	cl.size = cb.size
	cb.add_child(cl)
	if ready:
		var tw := create_tween().set_loops()
		tw.tween_property(cb, "modulate", Color(1.25, 1.25, 1.0), 0.6)
		tw.tween_property(cb, "modulate", Color.WHITE, 0.6)
		_hit(Rect2(150, 120, 330, 225), func():
			var rw := Missions.open_chest(scope)
			if not rw.is_empty():
				_toast(Loc.t("حصلت على %d جواهر و%d عملة!") % [rw["gems"], rw["coins"]])
				await get_tree().create_timer(1.6).timeout
				_switch(char_id))
	# العدّ التنازلي
	_patch_strip(Rect2(650, 832, 688, 66), 1346 if scope == "day" else 1322)
	_timer_lbl = UiKit.bold_label("", 44 if Loc.rtl() else 36, Color("ffe84a"), Color("4a1a00"), 6)
	_timer_lbl.position = Vector2(650, 832)
	_timer_lbl.size = Vector2(688, 66)
	_timer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_timer_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_root.add_child(_timer_lbl)
	_update_timer()
	# التبويبان
	_hit(Rect2(1225, 118, 300, 84), func():
		if char_id != "m_day": _switch("m_day"))
	_hit(Rect2(915, 118, 305, 84), func():
		if char_id != "m_week": _switch("m_week"))
	# العدّادان يفتحان المتجر + العودة
	_hit(Rect2(1030, 26, 250, 66), func(): _open_store(0))
	_hit(Rect2(1285, 26, 250, 66), func(): _open_store(1))
	_hit(Rect2(1560, 22, 96, 92), func():
		closed.emit()
		queue_free())


func _update_timer() -> void:
	if _timer_lbl == null:
		return
	var sec := Missions.seconds_left(_timer_scope)
	if _timer_scope == "day":
		_timer_lbl.text = Loc.t("تتجدد المهام بعد ") + Loc.digits("%02d:%02d:%02d" % [sec / 3600, (sec / 60) % 60, sec % 60])
	else:
		var d := ceili(sec / 86400.0)
		var w := Loc.t("يوم") if d == 1 else (Loc.t("أيام") if d <= 10 else Loc.t("يومًا"))
		_timer_lbl.text = Loc.t("تتجدد المهام بعد ") + Loc.digits(str(d)) + " " + w


var _tick := 0.0


func _process(delta: float) -> void:
	_tick += delta
	if _tick >= 1.0:
		_tick = 0.0
		_update_timer()


# ------------------------------------------------------------------ التصنيفات والبطولات
func _patch_text(r: Rect2, sample_x: int, text: String, size: int, color := Color.WHITE, outline := Color("0a1440")) -> void:
	_patch_strip(r, sample_x)
	var l := UiKit.bold_label(text, size, color, outline, 5)
	l.position = r.position
	l.size = r.size
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_root.add_child(l)


func _solid_text(r: Rect2, sample: Vector2i, text: String, size: int, color := Color.WHITE, outline := Color("0a1440")) -> void:
	var b := _box(r, _bg_img.get_pixelv(sample), Color(0, 0, 0, 0), 14, 0)
	var l := UiKit.bold_label(text, size, color, outline, 5)
	l.size = b.size
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	b.add_child(l)


func _common_top(coin_x: int, gem_x: int) -> void:
	_patch_num(1100, 34, 112, 40, coin_x, _fmt(Settings.total_coins))
	_patch_num(1366, 34, 100, 40, gem_x, str(Settings.gems))
	_hit(Rect2(1030, 26, 250, 66), func(): _open_store(0))
	_hit(Rect2(1285, 26, 250, 66), func(): _open_store(1))
	_hit(Rect2(1560, 22, 96, 92), func():
		closed.emit()
		queue_free())


func _build_ranking() -> void:
	var weekly := char_id == "r_week"
	_common_top(1098, 1366)
	var pts := Ranking.score(weekly)
	var rk := Ranking.rank_of(weekly)
	_solid_text(Rect2(690, 696, 146, 40), Vector2i(838, 716), _fmt(pts), 34)
	_solid_text(Rect2(1494, 696, 60, 40), Vector2i(1490, 716), str(rk), 34, Color("ffd23a"), Color("3a2200"))
	_patch_text(Rect2(104, 832, 420, 54), 98, Loc.t("المركز %s · %s نقطة") % [Loc.digits(str(rk)), Loc.digits(_fmt(pts))], 38, Color.WHITE, Color("1b0a50"))
	_hit(Rect2(1120, 118, 400, 84), func():
		if not weekly: _switch("r_week"))
	_hit(Rect2(770, 118, 345, 84), func():
		if weekly: _switch("r_all"))


func _build_tour() -> void:
	_common_top(1098, 1366)
	var ys := [245.0, 395.0, 540.0, 688.0]
	for i in range(4):
		var y: float = ys[i]
		var races := int(Ranking.CUPS[i]["races"])
		var prog := Ranking.cup_progress(i)
		var done := Ranking.cup_done(i)
		var claimed := Ranking.cup_claimed(i)
		var px := 985.0 if i == 3 else 930.0
		var pw := 192.0 if i == 3 else 230.0
		_box(Rect2(px, y - 25, pw, 50), Color("0b1c52"), Color("6f8fe0"), 24, 2)
		if prog > 0:
			var fill := _box(Rect2(px + 4, y - 21, maxf(26.0, (pw - 8.0) * float(prog) / float(races)), 42), Color("3fd12c"), Color("a6f27a"), 20, 2)
			fill.size.x = minf(fill.size.x, pw - 8.0)
		var t := UiKit.bold_label("%d/%d" % [prog, races], 28, Color.WHITE, Color("0a1440"), 5)
		t.position = Vector2(px, y - 25)
		t.size = Vector2(pw, 50)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_root.add_child(t)
		var txt := Loc.t("ابدأ")
		var fillc := Color("2fcf2c")
		var edge := Color("b6ff8a")
		if claimed:
			txt = Loc.t("تم ✓")
			fillc = Color("5c6384")
			edge = Color("9aa2c4")
		elif done:
			txt = Loc.t("استلام")
			fillc = Color("f5b81c")
			edge = Color("ffe38a")
		elif Ranking.active == i or prog > 0:
			txt = Loc.t("متابعة")
		_box(Rect2(552, y - 45, 175, 90), fillc, edge, 40, 3)
		var bl := UiKit.bold_label(txt, 38, Color.WHITE, Color("114a12") if fillc == Color("2fcf2c") else Color("2b2f55"), 6)
		bl.position = Vector2(552, y - 45)
		bl.size = Vector2(175, 90)
		bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_root.add_child(bl)
		if not claimed:
			var idx := i
			_hit(Rect2(552, y - 45, 175, 90), func():
				if Ranking.cup_done(idx):
					Ranking.claim_cup(idx)
					_switch(char_id)
				else:
					Ranking.start_cup(idx)
					start_pressed.emit())


## رسالة قصيرة في منتصف الشاشة
func _toast(text: String) -> void:
	var b := _box(Rect2(436, 380, 800, 140), Color("1b2a9a"), Color("ffd23a"), 40, 6)
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	var l := UiKit.bold_label(text, 48, Color("ffe84a"), Color("4a1a00"), 8)
	l.size = b.size
	b.add_child(l)
