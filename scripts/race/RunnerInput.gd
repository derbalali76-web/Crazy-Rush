class_name RunnerInput
extends RefCounted
## مدخلات اللاعب. steer مستمر (-1..1)، والباقي أحداث لحظية يستهلكها Runner.

var steer := 0.0
var jump := false
var slide := false
var punch := false
var special := false


func clear_events() -> void:
	jump = false
	slide = false
	punch = false
	special = false
