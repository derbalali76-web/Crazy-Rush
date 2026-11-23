extends Node
## نقطة الدخول: قائمة رئيسية بسيطة ثم السباق.

var current: Node = null


func _ready() -> void:
	_show_menu()


func _clear() -> void:
	if current:
		current.queue_free()
		current = null


func _show_menu() -> void:
	_clear()
	var m := Menu.new()
	m.play_pressed.connect(_start_race)
	add_child(m)
	current = m


func _start_race() -> void:
	_clear()
	await get_tree().process_frame
	# الحلبة التجريبية (بريميوم) اختيارية من الإعدادات؛ الافتراضي هو الحلبة المستقرة بلا تغيير.
	Toon.premium_enabled = Settings.premium_track
	Toon.use_normal_maps = Settings.quality == Settings.Quality.HIGH
	TrackData.layout = 2 if Settings.branch_track else (1 if Settings.premium_track else 0)
	var r := Race.new()
	r.exit_to_menu.connect(_show_menu)
	r.restart_requested.connect(_start_race)
	add_child(r)
	current = r
