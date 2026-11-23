class_name Characters
extends RefCounted
## سجلّ الشخصيات. كل شخصية جديدة تُضاف هنا فقط (صورة عرض + اسم)، وتظهر تلقائيًا
## في نافذة الإيقاف وشاشة النتائج (الشخصية المختارة في Settings.selected_character).

const LIST := {
	"fox": {
		"name": "فوكسي الثعلب",
		"portrait": "res://assets/characters/fox_portrait.png",
		"icon": "res://assets/characters/fox_icon.png",
	},
}
const DEFAULT := "fox"


static func get_def(id: String) -> Dictionary:
	return LIST.get(id, LIST[DEFAULT])


static func portrait(id: String) -> Texture2D:
	return load(get_def(id).portrait) as Texture2D


static func icon(id: String) -> Texture2D:
	var p: String = get_def(id).icon
	return load(p) as Texture2D if ResourceLoader.exists(p) else portrait(id)


static func character_name(id: String) -> String:
	return get_def(id).name
