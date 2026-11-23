class_name Characters
extends RefCounted
## سجلّ الشخصيات (12). كل شخصية: اسم كامل، اسم قصير، صورة عرض، وجه دائري، وهل يمكن اللعب بها.
## «playable» = لها نموذج ثلاثي الأبعاد داخل السباق؛ حاليًا فوكسي فقط، والبقية تُعرض كصور
## (منافسون في الترتيب والنتائج) وتبقى «غير متاح حاليًا» للاختيار حتى تُبنى نماذجها.

const LIST := {
	"fox": {"name": "فوكسي الثعلب", "short": "فوكسي", "playable": true},
	"bombo": {"name": "بومبو الملاكم", "short": "بومبو", "playable": false},
	"ziko": {"name": "زيكو النينجا", "short": "زيكو", "playable": false},
	"robo": {"name": "روبو الروبوت", "short": "روبو", "playable": false},
	"lulu": {"name": "لولو الساحرة", "short": "لولو", "playable": false},
	"dino": {"name": "دينو الديناصور", "short": "دينو", "playable": false},
	"bibo": {"name": "بيبو الأرنب", "short": "بيبو", "playable": false},
	"batboot": {"name": "بطبوط القبطان", "short": "بطبوط", "playable": false},
	"kung": {"name": "كونغ الباندا", "short": "كونغ", "playable": false},
	"sosu": {"name": "سوسو العنقاء", "short": "سوسو", "playable": false},
	"zain": {"name": "زين البرق", "short": "زين", "playable": false},
	"arthur": {"name": "آرثر ملك الجليد", "short": "آرثر", "playable": false},
}
const DEFAULT := "fox"
## ترتيب المنافسين الآليين (يطابق RaceLogic.NAMES)
const ROSTER := ["bombo", "ziko", "robo", "lulu", "dino", "bibo", "batboot"]


static func get_def(id: String) -> Dictionary:
	return LIST.get(id, LIST[DEFAULT])


static func portrait(id: String) -> Texture2D:
	return load("res://assets/characters/%s_portrait.png" % (id if LIST.has(id) else DEFAULT)) as Texture2D


static func icon(id: String) -> Texture2D:
	var p := "res://assets/characters/%s_icon.png" % (id if LIST.has(id) else DEFAULT)
	return load(p) as Texture2D if ResourceLoader.exists(p) else portrait(id)


static func character_name(id: String) -> String:
	return get_def(id).name


static func short_name(id: String) -> String:
	return get_def(id).short


static func is_playable(id: String) -> bool:
	return bool(get_def(id).playable)


static func id_from_short(short_name_: String) -> String:
	for k in LIST:
		if LIST[k].short == short_name_:
			return k
	return DEFAULT
