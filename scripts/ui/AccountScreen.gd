class_name AccountScreen
extends ScreenBase
## شاشة «الحساب»: إحصاءات حقيقية + تغيير الاسم.

var _name_label: Label
var _dialog: Control


func _init() -> void:
	bg_path = "res://assets/ui/c_account.webp"


static func _fmt_time(t: float) -> String:
	if t <= 0.0:
		return "--:--.--"
	var m := int(t) / 60
	return "%02d:%05.2f" % [m, t - m * 60.0]


func _build() -> void:
	topbar(Rect2(1421, 27, 55, 37), Rect2(1668, 28, 56, 36), Rect2(1745, 0, 118, 100))
	txt(Loc.t("حسابي"), Rect2(640, 20, 520, 70), 52, Color.WHITE, Color("5a2a00"), 8)
	# الاسم والمستوى
	_name_label = txt(Settings.player_name, Rect2(200, 470, 340, 62), 46, Color("dfe9ff"), Color("0a1a5a"), 6)
	var xp: int = Settings.races_played * 50 + Settings.wins * 100 + Settings.total_coins
	var lvl := xp / 500 + 1
	txt(str(lvl), Rect2(92, 565, 146, 90), 58, Color.WHITE, Color("2a0a5a"), 8)
	box(Rect2(256, 584, 334, 50), Color("0b1c52"), Color("0b1c52"), 20, 0)
	var fw := maxf(18.0, 322.0 * float(xp % 500) / 500.0)
	box(Rect2(262, 590, fw, 38), Color("3bd63a"), Color("9dff8a"), 16, 2)
	txt("%d / 500 XP" % (xp % 500), Rect2(256, 584, 334, 50), 26, Color.WHITE, Color("0a1a5a"), 5)
	# بطاقات الإحصاءات
	var stats := [
		[Rect2(745, 305, 390, 66), "أفضل زمن", _fmt_time(Settings.best_time)],
		[Rect2(1280, 305, 400, 66), "السباقات", str(Settings.races_played)],
		[Rect2(745, 528, 390, 66), "مجموع العملات", UiKit.fmt_int(Settings.total_coins)],
		[Rect2(1280, 528, 400, 66), "الانتصارات", str(Settings.wins)],
	]
	for s in stats:
		var pr: Rect2 = s[0]
		txt(Loc.t(s[1]), Rect2(pr.position.x + pr.size.x * 0.5, pr.position.y, pr.size.x * 0.46, pr.size.y), 28, Color("ffe45a"), Color("0a1a5a"), 5, false, HORIZONTAL_ALIGNMENT_RIGHT)
		num(s[2], Rect2(pr.position.x + 10, pr.position.y, pr.size.x * 0.46, pr.size.y), 40)
	txt(Loc.t("رجوع"), Rect2(545, 690, 305, 100), 52, Color.WHITE, Color("5a0a10"), 8)
	txt(Loc.t("تغيير الاسم"), Rect2(960, 690, 390, 100), 48, Color.WHITE, Color("0b4a12"), 8)
	hit(Rect2(365, 685, 495, 120), _close)
	hit(Rect2(925, 685, 575, 120), _rename)


func _rename() -> void:
	if _dialog:
		return
	_dialog = Control.new()
	_dialog.size = Vector2(W, H)
	_root.add_child(_dialog)
	var dim := box(Rect2(0, 0, W, H), Color(0.02, 0.03, 0.16, 0.72), Color(0, 0, 0, 0), 0, 0)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	var panel := box(Rect2(W * 0.5 - 330, 200, 660, 340), Color("14246e"), Color("ffc21a"), 36, 6)
	var title := UiKit.label(Loc.t("تغيير الاسم"), 46, Color("ffe45a"), 8)
	title.position = Vector2(W * 0.5 - 330, 216)
	title.size = Vector2(660, 70)
	_root.add_child(title)
	var le := LineEdit.new()
	le.text = Settings.player_name
	le.max_length = 12
	le.alignment = HORIZONTAL_ALIGNMENT_CENTER
	le.position = Vector2(W * 0.5 - 270, 300)
	le.size = Vector2(540, 80)
	le.add_theme_font_size_override("font_size", 44)
	le.add_theme_font_override("font", UiKit.font())
	_root.add_child(le)
	var ok := UiKit.button(Loc.t("حفظ"), UiKit.C_GREEN_TOP, UiKit.C_GREEN_BOT, Vector2(250, 80), 36)
	ok.position = Vector2(W * 0.5 - 270, 420)
	ok.pressed.connect(func():
		var n := le.text.strip_edges()
		if n != "":
			Settings.player_name = n
			Settings.save_settings()
			_name_label.text = n
		_close_dialog(dim, panel, title, le))
	_root.add_child(ok)
	var cancel := UiKit.button(Loc.t("إلغاء"), UiKit.C_RED_TOP, UiKit.C_RED_BOT, Vector2(250, 80), 36)
	cancel.position = Vector2(W * 0.5 + 20, 420)
	cancel.pressed.connect(func(): _close_dialog(dim, panel, title, le))
	_root.add_child(cancel)
	_dialog.set_meta("extra", [ok, cancel])
	le.grab_focus()


func _close_dialog(dim: Control, panel: Control, title: Control, le: Control) -> void:
	for n in [dim, panel, title, le] + (_dialog.get_meta("extra") as Array):
		n.queue_free()
	_dialog.queue_free()
	_dialog = null
