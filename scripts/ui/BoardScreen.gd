class_name BoardScreen
extends ScreenBase
## المهام (يومية/أسبوعية) والتصنيفات (أسبوعي/عام) والبطولات على صور بلا نصوص.
## char_id: m_day | m_week | r_week | r_all | tour

signal start_pressed

const PATHS := {
	"m_day": "res://assets/ui/c_m_day.webp", "m_week": "res://assets/ui/c_m_week.webp",
	"r_week": "res://assets/ui/c_r_week.webp", "r_all": "res://assets/ui/c_r_all.webp",
	"tour": "res://assets/ui/c_tour.webp",
}
const PLUS := {
	"m_day": [Rect2(1325, 23, 63, 49), Rect2(1613, 29, 62, 43)],
	"m_week": [Rect2(1327, 22, 61, 49), Rect2(1603, 22, 61, 49)],
	"r_week": [Rect2(1326, 20, 62, 51), Rect2(1605, 20, 61, 52)],
	"r_all": [Rect2(1320, 20, 62, 50), Rect2(1612, 20, 62, 50)],
	"tour": [Rect2(1327, 16, 62, 52), Rect2(1599, 16, 62, 52)],
}
const M_ROWS := [236.0, 320.0, 402.0, 486.0, 568.0, 652.0]
const R_ROWS := [230.0, 300.0, 370.0, 438.0, 506.0, 566.0, 640.0]
const T_ROWS := [214.0, 340.0, 466.0, 594.0]
const RIVALS := ["bombo", "lulu", "ziko", "zain", "robo", "dino"]
const CUP_NAMES := ["الكأس البرونزية", "الكأس الفضية", "الكأس الذهبية", "كأس الأبطال"]

var char_id := "m_day"
var _timer_lbl: Label
var _tick := 0.0


func _init() -> void:
	pass


func _ready() -> void:
	bg_path = PATHS[char_id]
	super._ready()


func _switch(id: String) -> void:
	char_id = id
	bg_path = PATHS[id]
	_tex = load(bg_path)
	_bg_img = _tex.get_image()
	_bg_rect.texture = _tex
	_timer_lbl = null
	for c in _root.get_children():
		if c != _bg_rect:
			c.queue_free()
	_host = _root
	_build()


func _build() -> void:
	var p: Array = PLUS[char_id]
	topbar(p[0], p[1], Rect2(1700, 0, 126, 96))
	if char_id.begins_with("m_"):
		_missions()
	elif char_id.begins_with("r_"):
		_ranking()
	else:
		_tour()


func _fox_pill(r: Rect2) -> void:
	txt(Loc.t("فوكسي الثعلب"), r, 40, Color.WHITE, Color("2a0a60"), 6)


func _bar(r: Rect2, prog: int, goal: int, size := 26) -> void:
	if prog > 0:
		var fw := maxf(r.size.y, (r.size.x - 8.0) * float(prog) / float(goal))
		var f := box(Rect2(r.position.x + 4, r.position.y + 4, minf(fw, r.size.x - 8.0), r.size.y - 8), Color("3fd12c"), Color("a6f27a"), int(r.size.y * 0.4), 2)
		f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	txt("%s/%s" % [Loc.digits(str(prog)), Loc.digits(str(goal))], r, size, Color.WHITE, Color("0a1440"), 5)


func _mission_text(d: Dictionary) -> String:
	var g := int(d["goal"])
	match str(d["kind"]):
		"races": return Loc.t("أكمل %d سباقات") % g
		"wins": return Loc.t("فز بـ %d سباقات") % g if g > 1 else Loc.t("فز بسباق واحد")
		"coins": return Loc.t("اجمع %d عملة") % g
		"fast": return Loc.t("أنهِ سباقًا في أقل من %d ثانية") % int(d.get("limit", 60.0))
		"hits": return Loc.t("اضرب %d منافسين") % g
	return Loc.t("استخدم القدرة %d مرات") % g


func _missions() -> void:
	var scope := "day" if char_id == "m_day" else "week"
	txt(Loc.t("المهام"), Rect2(660, 14, 330, 72), 46, Color.WHITE, Color("3a0a70"), 7)
	txt(Loc.t("الأسبوعية"), Rect2(1140, 112, 205, 60), 36)
	txt(Loc.t("اليومية"), Rect2(1470, 112, 215, 60), 36, Color.WHITE, Color("7a4a00"))
	hit(Rect2(1360, 104, 340, 76), func():
		if char_id != "m_day": _switch("m_day"))
	hit(Rect2(1016, 104, 340, 76), func():
		if char_id != "m_week": _switch("m_week"))
	var ds := Missions.defs(scope)
	for i in range(ds.size()):
		var y: float = M_ROWS[i]
		var prog := Missions.progress(scope, i)
		var done := Missions.is_done(scope, i)
		var claimed := Missions.is_claimed(scope, i)
		var goal := int(ds[i]["goal"])
		txt(_mission_text(ds[i]), Rect2(1335, y - 30, 345, 60), 26, Color.WHITE, Color("0a1a5a"), 5, true)
		num(UiKit.fmt_int(int(ds[i]["reward"])), Rect2(902, y - 27, 104, 44), 30)
		_bar(Rect2(1034, y - 22, 280, 44), prog, goal)
		var label := Loc.t("جاري")
		if claimed:
			label = Loc.t("تم ✓")
		elif done:
			label = Loc.t("استلام")
			box(Rect2(662, y - 30, 174, 60), Color("27c43a"), Color("b6ff8a"), 26, 3)
		txt(label, Rect2(662, y - 30, 174, 60), 32, Color.WHITE, Color("0e5a1c") if done and not claimed else Color("1b2350"), 6)
		if done and not claimed:
			var idx := i
			hit(Rect2(662, y - 30, 174, 60), func():
				Missions.claim(scope, idx)
				_switch(char_id))
	# الصندوق
	var ready := Missions.chest_ready(scope)
	var opened := Missions.chest_opened(scope)
	var ctxt := Loc.t("اضغط لفتح الصندوق!") if ready else (Loc.t("تم فتح الصندوق ✓") if opened else Loc.t("أكمل كل المهام"))
	txt(ctxt, Rect2(176, 268, 344, 40), 28, Color.WHITE, Color("2a0a60"), 5)
	if ready:
		hit(Rect2(150, 100, 420, 210), func():
			var rw := Missions.open_chest(scope)
			if not rw.is_empty():
				_toast(Loc.t("حصلت على %d جواهر و%d عملة!") % [rw["gems"], rw["coins"]])
				await get_tree().create_timer(1.6).timeout
				_switch(char_id))
	_fox_pill(Rect2(110, 722, 380, 76))
	_timer_lbl = txt("", Rect2(700, 740, 800, 60), 40, Color("ffe84a"), Color("4a1a00"), 6)
	_update_timer()


func _update_timer() -> void:
	if _timer_lbl == null or not is_instance_valid(_timer_lbl):
		return
	var scope := "day" if char_id == "m_day" else "week"
	var sec := Missions.seconds_left(scope)
	if char_id == "tour":
		return
	if scope == "day":
		_timer_lbl.text = Loc.t("تتجدد المهام بعد ") + Loc.digits("%02d:%02d:%02d" % [sec / 3600, (sec / 60) % 60, sec % 60])
	else:
		var d := ceili(sec / 86400.0)
		var w := Loc.t("يوم") if d == 1 else (Loc.t("أيام") if d <= 10 else Loc.t("يومًا"))
		_timer_lbl.text = Loc.t("تتجدد المهام بعد ") + Loc.digits(str(d)) + " " + w


func _process(delta: float) -> void:
	_tick += delta
	if _tick >= 1.0:
		_tick = 0.0
		if char_id.begins_with("m_"):
			_update_timer()


func _ranking() -> void:
	var weekly := char_id == "r_week"
	txt(Loc.t("التصنيف"), Rect2(640, 14, 340, 72), 46, Color.WHITE, Color("3a0a70"), 7)
	if weekly:
		txt(Loc.t("العام"), Rect2(950, 112, 290, 60), 36)
		txt(Loc.t("الأسبوعي"), Rect2(1370, 112, 310, 60), 36, Color.WHITE, Color("7a4a00"))
		hit(Rect2(826, 104, 418, 76), func(): _switch("r_all"))
	else:
		txt(Loc.t("العام"), Rect2(930, 112, 280, 60), 36, Color.WHITE, Color("7a4a00"))
		txt(Loc.t("الأسبوعي"), Rect2(1330, 112, 330, 60), 36)
		hit(Rect2(1234, 104, 440, 76), func(): _switch("r_week"))
	txt(Loc.t("الأسبوعي") if weekly else Loc.t("العام"), Rect2(170, 196, 290, 50), 36, Color.WHITE, Color("3a0a70"), 6)
	var pts := Ranking.score(weekly)
	var rk := Ranking.rank_of(weekly)
	var rv: Array = Ranking.RIVALS_WEEK if weekly else Ranking.RIVALS_ALL
	for i in range(6):
		var y: float = R_ROWS[i]
		num(UiKit.fmt_int(int(rv[i])), Rect2(722, y - 27, 160, 44), 30)
		txt(Characters.short_name(RIVALS[i]), Rect2(1000, y - 28, 480, 56), 36, Color.WHITE, Color("0a1a5a"), 5, false, HORIZONTAL_ALIGNMENT_RIGHT)
		if i >= 3:
			num(str(i + 1), Rect2(1650, y - 27, 80, 44), 28)
	var y7: float = R_ROWS[6]
	num(UiKit.fmt_int(pts), Rect2(722, y7 - 27, 160, 44), 30)
	txt(Loc.t("أنت"), Rect2(1000, y7 - 28, 480, 56), 38, Color.WHITE, Color("7a4a00"), 6, false, HORIZONTAL_ALIGNMENT_RIGHT)
	num(str(rk), Rect2(1650, y7 - 27, 80, 44), 28)
	txt(Loc.t("المركز %s · %s نقطة") % [Loc.digits(str(rk)), Loc.digits(UiKit.fmt_int(pts))], Rect2(80, 738, 440, 62), 36, Color.WHITE, Color("1b0a50"), 6)
	var bar := Loc.t("الترتيب بين كل اللاعبين")
	if weekly:
		var d := ceili(Missions.seconds_left("week") / 86400.0)
		bar = Loc.t("يُعاد التصنيف بعد %s") % (Loc.digits(str(d)) + " " + (Loc.t("يوم") if d == 1 else Loc.t("أيام")))
	txt(bar, Rect2(640, 738, 800, 62), 40, Color("ffe84a"), Color("4a1a00"), 6)


func _tour() -> void:
	txt(Loc.t("البطولات"), Rect2(640, 14, 340, 72), 46, Color.WHITE, Color("5a3a00"), 7)
	for i in range(4):
		var y: float = T_ROWS[i]
		var cup: Dictionary = Ranking.CUPS[i]
		var races := int(cup["races"])
		var prog := Ranking.cup_progress(i)
		var done := Ranking.cup_done(i)
		var claimed := Ranking.cup_claimed(i)
		var gem := i == 3
		num(UiKit.fmt_int(int(cup["reward"])), Rect2(842, y - 27, 98 if gem else 136, 44), 28)
		if gem:
			num(str(int(cup["gems"])), Rect2(1008, y + 2, 44, 34), 22)
		var bx := 1062.0 if gem else 1000.0
		var bw := 216.0 if gem else 266.0
		_bar(Rect2(bx, y - 22, bw, 44), prog, races, 24)
		txt(Loc.t(CUP_NAMES[i]), Rect2(1305, y - 30, 280, 60), 32, Color.WHITE, Color("0a1a5a"), 5, true)
		var label := Loc.t("ابدأ")
		if claimed:
			label = Loc.t("تم ✓")
			box(Rect2(582, y - 34, 190, 68), Color("5c6384"), Color("9aa2c4"), 30, 3)
		elif done:
			label = Loc.t("استلام")
			box(Rect2(582, y - 34, 190, 68), Color("f5b81c"), Color("ffe38a"), 30, 3)
		elif Ranking.active == i or prog > 0:
			label = Loc.t("متابعة")
		txt(label, Rect2(582, y - 34, 190, 68), 36, Color.WHITE, Color("114a12"), 6)
		if not claimed:
			var idx := i
			hit(Rect2(582, y - 34, 190, 68), func():
				if Ranking.cup_done(idx):
					Ranking.claim_cup(idx)
					_switch(char_id)
				else:
					Ranking.start_cup(idx)
					start_pressed.emit())
	_fox_pill(Rect2(90, 706, 380, 76))
	txt(Loc.t("أكمل سباقات الكأس لتربح الجوائز"), Rect2(620, 724, 880, 70), 38, Color("ffe84a"), Color("4a1a00"), 6)


func _toast(text: String) -> void:
	var b := box(Rect2(436, 330, 990, 160), Color("1b2a9a"), Color("ffd23a"), 40, 6)
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	var l := UiKit.bold_label(text, 52, Color("ffe84a"), Color("4a1a00"), 8)
	l.size = b.size
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	b.add_child(l)
