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
	var r := Race.new()
	r.exit_to_menu.connect(_show_menu)
	r.restart_requested.connect(_start_race)
	add_child(r)
	current = r
