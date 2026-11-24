class_name Ranking
extends RefCounted
## التصنيفات (نقاط أسبوعية ودائمة) والبطولات (كؤوس بعدد سباقات). تُحفظ في user://compete.cfg

const PATH := "user://compete.cfg"
## منافسون ثابتون كما في التصميم (أسبوعي / دائم)
const RIVALS_WEEK := [12850, 11420, 10980, 8750, 6390, 4120]
const RIVALS_ALL := [98450, 91200, 85730, 70120, 64880, 52310]
## البطولات: عدد السباقات والجائزة (عملات)
const CUPS := [
	{"races": 3, "reward": 500},
	{"races": 5, "reward": 1200},
	{"races": 5, "reward": 2500},
	{"races": 8, "reward": 5000},
]

static var all_pts := 0
static var week_pts := 0
static var week_id := -1
static var active := -1
static var prog: Array = [0, 0, 0, 0]
static var claimed: Array = [false, false, false, false]
static var _loaded := false


static func _week_now() -> int:
	return int(int(Time.get_unix_time_from_system() / 86400.0) / 7)


static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	var cf := ConfigFile.new()
	if cf.load(PATH) == OK:
		all_pts = int(cf.get_value("rank", "all", 0))
		week_pts = int(cf.get_value("rank", "week", 0))
		week_id = int(cf.get_value("rank", "week_id", -1))
		active = int(cf.get_value("cup", "active", -1))
		prog = cf.get_value("cup", "prog", [0, 0, 0, 0])
		claimed = cf.get_value("cup", "claimed", [false, false, false, false])
	if week_id != _week_now():
		week_id = _week_now()
		week_pts = 0


static func save() -> void:
	var cf := ConfigFile.new()
	cf.set_value("rank", "all", all_pts)
	cf.set_value("rank", "week", week_pts)
	cf.set_value("rank", "week_id", week_id)
	cf.set_value("cup", "active", active)
	cf.set_value("cup", "prog", prog)
	cf.set_value("cup", "claimed", claimed)
	cf.save(PATH)


static func reset_for_tests() -> void:
	_loaded = true
	all_pts = 0
	week_pts = 0
	week_id = _week_now()
	active = -1
	prog = [0, 0, 0, 0]
	claimed = [false, false, false, false]


static func points_for(rank: int, coins: int) -> int:
	return [100, 70, 50, 30][clampi(rank - 1, 0, 3)] + coins


## عند نهاية السباق
static func report_race(rank: int, coins: int) -> void:
	_load()
	var p := points_for(rank, coins)
	all_pts += p
	week_pts += p
	if active >= 0 and prog[active] < int(CUPS[active]["races"]):
		prog[active] += 1
	save()


static func score(weekly: bool) -> int:
	_load()
	return week_pts if weekly else all_pts


## ترتيب اللاعب بين المنافسين الستة (وما بعدهم يُقدَّر بالنقاط المتبقية)
static func rank_of(weekly: bool) -> int:
	var s := score(weekly)
	var rv: Array = RIVALS_WEEK if weekly else RIVALS_ALL
	var above := 0
	for r in rv:
		if r > s:
			above += 1
	if above < rv.size():
		return above + 1
	var gap := float(rv[rv.size() - 1] - s)
	return rv.size() + 1 + int(gap / (300.0 if weekly else 1000.0))


static func cup_progress(i: int) -> int:
	_load()
	return mini(int(prog[i]), int(CUPS[i]["races"]))


static func cup_done(i: int) -> bool:
	return cup_progress(i) >= int(CUPS[i]["races"])


static func cup_claimed(i: int) -> bool:
	_load()
	return bool(claimed[i])


static func start_cup(i: int) -> void:
	_load()
	if cup_done(i):
		return
	active = i
	save()


static func claim_cup(i: int) -> int:
	_load()
	if not cup_done(i) or claimed[i]:
		return 0
	claimed[i] = true
	if active == i:
		active = -1
	var r := int(CUPS[i]["reward"])
	var ml := Engine.get_main_loop()
	var st = (ml as SceneTree).root.get_node_or_null("Settings") if ml is SceneTree else null
	if st:
		st.total_coins += r
		st.save_settings()
	save()
	return r
