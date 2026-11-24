class_name Missions
extends RefCounted
## المهام اليومية والأسبوعية: تقدّم يُحفظ في user://missions.cfg، والمكافأة تُستلم يدويًا.

const PATH := "user://missions.cfg"

## kind: races / wins / coins / fast (إنهاء بزمن أقل من limit) / hits / ability
const DAILY := [
	{"kind": "races", "goal": 3, "reward": 50},
	{"kind": "wins", "goal": 1, "reward": 100},
	{"kind": "coins", "goal": 50, "reward": 40},
	{"kind": "fast", "goal": 1, "reward": 150, "limit": 70.0},
	{"kind": "hits", "goal": 5, "reward": 30},
	{"kind": "ability", "goal": 3, "reward": 60},
]
const WEEKLY := [
	{"kind": "races", "goal": 20, "reward": 400},
	{"kind": "wins", "goal": 7, "reward": 600},
	{"kind": "coins", "goal": 500, "reward": 350},
	{"kind": "fast", "goal": 1, "reward": 800, "limit": 60.0},
	{"kind": "ability", "goal": 30, "reward": 500},
	{"kind": "hits", "goal": 50, "reward": 450},
]

static var _d := {}
static var _loaded := false


static func defs(scope: String) -> Array:
	return DAILY if scope == "day" else WEEKLY


static func _period(scope: String, now := -1.0) -> int:
	var t := Time.get_unix_time_from_system() if now < 0.0 else now
	var day := int(t / 86400.0)
	return day if scope == "day" else int(day / 7)


static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	var cf := ConfigFile.new()
	if cf.load(PATH) == OK:
		for s in ["day", "week"]:
			_d[s] = {
				"p": int(cf.get_value(s, "period", -1)),
				"prog": cf.get_value(s, "prog", []),
				"claimed": cf.get_value(s, "claimed", []),
			}
	_ensure()


static func _ensure(now := -1.0) -> void:
	for s in ["day", "week"]:
		var n := defs(s).size()
		var cur := _period(s, now)
		var e: Dictionary = _d.get(s, {})
		if e.is_empty() or int(e.get("p", -1)) != cur or e["prog"].size() != n:
			var z := []
			var c := []
			for i in range(n):
				z.append(0)
				c.append(false)
			_d[s] = {"p": cur, "prog": z, "claimed": c}


static func save() -> void:
	var cf := ConfigFile.new()
	for s in ["day", "week"]:
		cf.set_value(s, "period", _d[s]["p"])
		cf.set_value(s, "prog", _d[s]["prog"])
		cf.set_value(s, "claimed", _d[s]["claimed"])
	cf.save(PATH)


static func reset_for_tests() -> void:
	_d = {}
	_loaded = true
	_ensure()


static func progress(scope: String, i: int) -> int:
	_load()
	_ensure()
	return mini(int(_d[scope]["prog"][i]), int(defs(scope)[i]["goal"]))


static func is_done(scope: String, i: int) -> bool:
	return progress(scope, i) >= int(defs(scope)[i]["goal"])


static func is_claimed(scope: String, i: int) -> bool:
	_load()
	_ensure()
	return bool(_d[scope]["claimed"][i])


## يزيد تقدّم كل المهام من هذا النوع (يوميًا وأسبوعيًا)
static func add(kind: String, n := 1) -> void:
	_load()
	_ensure()
	for s in ["day", "week"]:
		var ds := defs(s)
		for i in range(ds.size()):
			if ds[i]["kind"] == kind:
				_d[s]["prog"][i] = int(_d[s]["prog"][i]) + n
	save()


## عند نهاية السباق
static func report_race(rank: int, time: float) -> void:
	_load()
	_ensure()
	for s in ["day", "week"]:
		var ds := defs(s)
		for i in range(ds.size()):
			match ds[i]["kind"]:
				"races":
					_d[s]["prog"][i] = int(_d[s]["prog"][i]) + 1
				"wins":
					if rank == 1:
						_d[s]["prog"][i] = int(_d[s]["prog"][i]) + 1
				"fast":
					if time < float(ds[i]["limit"]):
						_d[s]["prog"][i] = int(_d[s]["prog"][i]) + 1
	save()


## يستلم المكافأة: يعيد قيمتها (0 إن لم تكن جاهزة)
static func claim(scope: String, i: int) -> int:
	if not is_done(scope, i) or is_claimed(scope, i):
		return 0
	_d[scope]["claimed"][i] = true
	var r := int(defs(scope)[i]["reward"])
	var ml := Engine.get_main_loop()
	var st = (ml as SceneTree).root.get_node_or_null("Settings") if ml is SceneTree else null
	if st:
		st.total_coins += r
		st.save_settings()
	save()
	return r


static func claimable_count() -> int:
	var c := 0
	for s in ["day", "week"]:
		for i in range(defs(s).size()):
			if is_done(s, i) and not is_claimed(s, i):
				c += 1
	return c


## الثواني المتبقية حتى التجدّد (منتصف الليل بتوقيت الجهاز)
static func seconds_left(scope: String) -> int:
	var t := Time.get_unix_time_from_system()
	var off := int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	var local := int(t) + off
	var day := int(local / 86400)
	var end_day := day + 1 if scope == "day" else (int(day / 7) + 1) * 7
	return maxi(0, end_day * 86400 - local)


static func arabic_digits(s: String) -> String:
	var out := ""
	for ch in s:
		out += "٠١٢٣٤٥٦٧٨٩"[int(ch)] if ch >= "0" and ch <= "9" else ch
	return out
