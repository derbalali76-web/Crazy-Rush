extends Node
## إعدادات اللعبة (تُحفظ في user://settings.cfg) وتطبيق مستويات الجودة.

signal quality_changed

enum Quality { LOW, MEDIUM, HIGH }

const PATH := "user://settings.cfg"

var quality: int = Quality.MEDIUM
var steer_sensitivity: float = 1.0      # 0.5 .. 1.5
var sfx_volume: float = 0.8
var show_fps: bool = false
var auto_quality: bool = true
var vibration: bool = true
var premium_track: bool = false   # حلبة الغابة التجريبية (بريميوم): تخطيط متعرج + ديكور حقيقي
var best_time: float = 0.0
var total_coins: int = 0


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(PATH) != OK:
		quality = _guess_default_quality()
		return
	quality = clampi(int(cf.get_value("gfx", "quality", Quality.MEDIUM)), 0, 2)
	auto_quality = bool(cf.get_value("gfx", "auto_quality", true))
	show_fps = bool(cf.get_value("gfx", "show_fps", false))
	steer_sensitivity = clampf(float(cf.get_value("controls", "sensitivity", 1.0)), 0.4, 1.8)
	vibration = bool(cf.get_value("controls", "vibration", true))
	premium_track = bool(cf.get_value("gfx", "premium_track", false))
	sfx_volume = clampf(float(cf.get_value("audio", "sfx", 0.8)), 0.0, 1.0)
	best_time = float(cf.get_value("progress", "best_time", 0.0))
	total_coins = int(cf.get_value("progress", "coins", 0))


func save_settings() -> void:
	var cf := ConfigFile.new()
	cf.set_value("gfx", "quality", quality)
	cf.set_value("gfx", "auto_quality", auto_quality)
	cf.set_value("gfx", "show_fps", show_fps)
	cf.set_value("controls", "sensitivity", steer_sensitivity)
	cf.set_value("controls", "vibration", vibration)
	cf.set_value("gfx", "premium_track", premium_track)
	cf.set_value("audio", "sfx", sfx_volume)
	cf.set_value("progress", "best_time", best_time)
	cf.set_value("progress", "coins", total_coins)
	cf.save(PATH)


func reset_defaults() -> void:
	quality = _guess_default_quality()
	steer_sensitivity = 1.0
	sfx_volume = 0.8
	show_fps = false
	auto_quality = true
	vibration = true
	premium_track = false
	save_settings()
	quality_changed.emit()


func _guess_default_quality() -> int:
	# لا نعرف قدرة الهاتف قبل القياس؛ المتوسط هو الافتراضي الآمن، والتخفيف التلقائي يتكفل بالباقي.
	return Quality.MEDIUM


func set_quality(q: int) -> void:
	quality = clampi(q, 0, 2)
	quality_changed.emit()


## معاملات الجودة تُقرأ من مكان واحد.
func profile() -> Dictionary:
	match quality:
		Quality.LOW:
			return {"scale": 0.67, "msaa": 0, "shadows": false, "density": 0.35, "view": 150.0, "outline": false, "fog": true}
		Quality.HIGH:
			return {"scale": 1.0, "msaa": 2, "shadows": true, "density": 1.0, "view": 260.0, "outline": true, "fog": true}
		_:
			# الوضع المميز أثقل على البكسل (خامات PBR): دقة أقل على الشاشات عالية الدقة
			return {"scale": 0.70 if premium_track else 0.85, "msaa": 0, "shadows": true, "density": 0.65, "view": 200.0, "outline": true, "fog": true}


func quality_name() -> String:
	return ["منخفضة", "متوسطة", "عالية"][quality]


## تطبيق إعدادات المنفذ (Viewport) على الشاشة الحالية.
func apply_to_viewport(vp: Viewport, light: DirectionalLight3D = null) -> void:
	var p := profile()
	vp.scaling_3d_scale = p.scale
	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	match int(p.msaa):
		2: vp.msaa_3d = Viewport.MSAA_2X
		4: vp.msaa_3d = Viewport.MSAA_4X
		_: vp.msaa_3d = Viewport.MSAA_DISABLED
	if light:
		light.shadow_enabled = bool(p.shadows)
