class_name Menu
extends Node3D
## القائمة الرئيسية: فوكسي على منصة + أزرار حقيقية.

signal play_pressed

var _fox: Foxy
var _cam: Camera3D
var _t := 0.0
var _ui: CanvasLayer
var _settings: Control


func _ready() -> void:
	var sky := Sky.new()
	var pm := ProceduralSkyMaterial.new()
	pm.sky_top_color = Color("3f86e8")
	pm.sky_horizon_color = Color("cfe6ff")
	pm.ground_horizon_color = Color("cfe6ff")
	pm.ground_bottom_color = Color("9fb6d8")
	sky.sky_material = pm
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("c4b4f0")
	e.ambient_light_energy = 0.34
	var we := WorldEnvironment.new()
	we.environment = e
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -35, 0)
	sun.light_energy = 0.85
	sun.light_color = Color("fff0d6")
	sun.shadow_enabled = bool(Settings.profile().shadows)
	add_child(sun)
	Settings.apply_to_viewport(get_viewport(), sun)

	var pod := MeshBuilder.new()
	pod.add_cylinder(1.9, 1.8, 0.35, Color("8e6bd8"), Transform3D(Basis(), Vector3(0, -0.35, 0)), 40, true, Color("a98af0"))
	pod.add_cylinder(2.3, 2.3, 0.2, Color("5a3fb0"), Transform3D(Basis(), Vector3(0, -0.55, 0)), 40)
	Toon.mesh_instance(pod.build(), Toon.solid(), self)

	_fox = Foxy.create(true)
	add_child(_fox)
	_fox.anim = Foxy.Anim.IDLE
	_fox.rotation_degrees.y = 160.0

	_cam = Camera3D.new()
	_cam.fov = 38.0
	add_child(_cam)
	_cam.position = Vector3(0.0, 1.5, 6.4)
	_cam.look_at(Vector3(0.0, 1.0, 0), Vector3.UP)
	_cam.make_current()
	# تحريك الكاميرا يمينًا قليلًا ليبقى فوكسي في الثلث الأيسر
	_cam.h_offset = 0.9

	_ui = CanvasLayer.new()
	add_child(_ui)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(root)
	var vp := get_viewport().get_visible_rect().size
	var title := UiKit.label("CRAZY RUSH", 92, Color("ffd23a"), 14)
	title.size = Vector2(700, 120)
	title.position = Vector2(vp.x * 0.68 - 350, vp.y * 0.12)
	root.add_child(title)
	var sub := UiKit.label("سباق فوكسي المجنون", 34, Color.WHITE, 8)
	sub.size = Vector2(700, 50)
	sub.position = Vector2(vp.x * 0.68 - 350, vp.y * 0.12 + 118)
	root.add_child(sub)
	var play := UiKit.button("العب الآن", UiKit.C_GREEN_TOP, UiKit.C_GREEN_BOT, Vector2(340, 96), 44)
	play.position = Vector2(vp.x * 0.68 - 170, vp.y * 0.50)
	play.pressed.connect(func(): play_pressed.emit())
	root.add_child(play)
	var set := UiKit.button("الإعدادات", UiKit.C_BLUE_TOP, UiKit.C_BLUE_BOT, Vector2(260, 72), 30)
	set.position = Vector2(vp.x * 0.68 - 130, vp.y * 0.50 + 118)
	set.pressed.connect(_open_settings)
	root.add_child(set)
	var best := UiKit.label("", 26, Color("fff3a0"), 6)
	best.size = Vector2(500, 40)
	best.position = Vector2(vp.x * 0.68 - 250, vp.y * 0.86)
	if Settings.best_time > 0.0:
		best.text = "أفضل زمن: %.2f ث    العملات: %d" % [Settings.best_time, Settings.total_coins]
	root.add_child(best)
	var ph := UiKit.label("المرحلة 1 — نسخة اختبار", 20, Color(1, 1, 1, 0.8), 4)
	ph.size = Vector2(400, 30)
	ph.position = Vector2(20, vp.y - 40)
	root.add_child(ph)


func _open_settings() -> void:
	if _settings:
		return
	var sp := SettingsPanel.new()
	sp.closed.connect(func():
		_settings.queue_free()
		_settings = null)
	_settings = sp
	_ui.add_child(sp)


func _process(delta: float) -> void:
	_t += delta
	_fox.rotation_degrees.y = 160.0 + sin(_t * 0.6) * 14.0
