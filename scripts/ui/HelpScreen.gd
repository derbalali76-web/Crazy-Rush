class_name HelpScreen
extends ScreenBase
## شاشة «المساعدة»: صورة بلا نصوص + نصوص حقيقية بلغة اللعبة.


func _init() -> void:
	bg_path = "res://assets/ui/c_help.webp"


func _build() -> void:
	topbar(Rect2(1439, 28, 54, 36), Rect2(1693, 29, 54, 35), Rect2(1750, 0, 113, 100))
	txt(Loc.t("المساعدة"), Rect2(660, 14, 480, 82), 64, Color.WHITE, Color("2a0a4a"), 9)
	var cards := [
		[Rect2(150, 176, 385, 112), "زر القدرة الخاصة"],
		[Rect2(553, 176, 377, 112), "زر اللكمة لضرب المنافسين"],
		[Rect2(947, 176, 373, 112), "السحب للأعلى للقفز"],
		[Rect2(1340, 176, 375, 112), "السحب يمينًا ويسارًا للتوجيه"],
	]
	for c in cards:
		txt(Loc.t(c[1]), c[0], 46, Color.WHITE, Color("0a1a5a"), 8, true)
	txt(Loc.t("فهمت"), Rect2(700, 726, 460, 100), 66, Color.WHITE, Color("0b4a12"), 8)
	hit(Rect2(635, 722, 605, 108), _close)
