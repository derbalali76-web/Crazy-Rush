class_name RaceLogic
extends RefCounted
## منطق السباق متعدد المتسابقين (بلا رسوميات): اللاعب + 7 آليين، ضرب متبادل، ترتيب.

signal racer_hit(victim: int, attacker: int)

const RACERS := 8
const NAMES := ["ميمو", "زوزو", "كيكو", "لولو", "توتو", "بيبو", "فيفي"]
const HUES := [2.1, -2.0, 1.0, -0.9, 3.1, 0.45, -1.45]   # دوران صبغة فراء كل منافس (راديان)

var runners: Array[Runner] = []
var ais: Array = []            # RacerAI أو null للاعب
var player := 0
var _order_cache: Array = []


## player_runner يملك TrackData الخاص به (يُعرض بصريًا)؛ لكل آلي نسخته المنفصلة لأن العوائق تحمل حالة.
func _init(player_runner: Runner, player_slot := 3, seed_v := 1234) -> void:
	player = player_slot
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var xs := _grid()
	var ai_i := 0
	for i in range(RACERS):
		if i == player_slot:
			runners.append(player_runner)
			ais.append(null)
		else:
			var r := Runner.new(TrackData.new())
			var sk := rng.randf_range(0.62, 0.95)
			var ag := rng.randf_range(0.25, 0.85)
			r.speed_scale = lerpf(0.965, 1.0, sk)
			runners.append(r)
			ais.append(RacerAI.new(sk, ag, seed_v + 31 * (ai_i + 1)))
			ai_i += 1
		runners[i].x = xs[i]
		if ais[i] != null:
			ais[i].lane_x = xs[i]
	for i in range(RACERS):
		runners[i].punch_strike.connect(_on_strike.bind(i))


static func _grid() -> Array:
	var xs := []
	for i in range(RACERS):
		xs.append(-5.25 + 1.5 * float(i))
	return xs


func start() -> void:
	for r in runners:
		r.start_race()


func step(dt: float) -> void:
	var player_r := runners[player]
	for i in range(RACERS):
		var ai = ais[i]
		if ai != null:
			var r := runners[i]
			# تعويض خفيف: المتأخر يلحق والمتقدم جدًا يهدأ
			var gap := r.s - player_r.s
			var rubber := 1.0
			if gap > 14.0:
				rubber = 0.965
			elif gap < -14.0:
				rubber = 1.05
			r.speed_scale = clampf(lerpf(0.965, 1.0, ai.skill) * rubber * (1.03 if ai.chasing else 1.0), 0.9, 1.08)
			ai.update(dt, r, runners)
		runners[i].step(dt)


func _on_strike(attacker: int) -> void:
	var a := runners[attacker]
	var got := false
	for j in range(RACERS):
		if j == attacker:
			continue
		var v := runners[j]
		var ds := v.s - a.s
		if ds > -0.3 and ds < Runner.PUNCH_RANGE + 0.2 and absf(v.x - a.x) < 1.3:
			if v.take_hit():
				got = true
				racer_hit.emit(j, attacker)
	if got:
		a.mark_rival_hit()


## الترتيب: من أنهى السباق بحسب الزمن ثم الباقي بحسب المسافة.
func standings() -> Array:
	var idx := range(RACERS)
	idx.sort_custom(func(a: int, b: int) -> bool:
		var ra := runners[a]
		var rb := runners[b]
		var fa := ra.state == Runner.State.FINISHED
		var fb := rb.state == Runner.State.FINISHED
		if fa and fb:
			return ra.finish_time < rb.finish_time
		if fa != fb:
			return fa
		return ra.s > rb.s)
	return idx


func rank_of(i: int) -> int:
	return standings().find(i) + 1
