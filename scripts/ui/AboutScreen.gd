class_name AboutScreen
extends ScreenBase
## شاشة «حول اللعبة».


func _init() -> void:
	bg_path = "res://assets/ui/c_about.webp"


func _build() -> void:
	topbar(Rect2(1419, 27, 55, 37), Rect2(1669, 28, 55, 36), Rect2(1745, 0, 118, 100))
	txt(Loc.t("حول اللعبة"), Rect2(640, 20, 520, 70), 52, Color.WHITE, Color("5a2a00"), 8)
	txt(Loc.t("الإصدار") + " " + str(ProjectSettings.get_setting("application/config/version", "1.0")), Rect2(715, 338, 425, 62), 38, Color.WHITE, Color("0a1a5a"), 6)
	txt(Loc.t("لعبة سباق مجانية للجميع"), Rect2(728, 414, 400, 52), 28, Color("ffe45a"), Color("0a1a5a"), 5)
	txt(Loc.t("رجوع"), Rect2(700, 725, 360, 90), 56, Color.WHITE, Color("5a0a10"), 8)
	hit(Rect2(605, 705, 590, 120), _close)
