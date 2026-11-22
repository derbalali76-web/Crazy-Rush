class_name TrackData
extends RefCounted
## بيانات المسار (منطق بحت بلا رسوم): الخط المركزي، الحفر، العقبات، العملات، المسرّعات.
## المسار «جسر الغابة». الإحداثيات: s = المسافة على طول المسار، x = الإزاحة الجانبية (+ يمين).

const STEP := 1.0
const HALF_W := 6.0
const COL_W := 4.0
const LENGTH := 1060.0
const FINISH_S := 1000.0
const START_S := 8.0

## تخطيط الخط المركزي: 0 الحالي (شبه مستقيم، مستقر)، 1 «غابة متعرجة» تجريبي (فرع art-premium) بمنعطفات واضحة وتلال.
static var layout := 0

var count := 0
var pos := PackedVector3Array()
var fwd := PackedVector3Array()
var pits: Array = []
var obstacles: Array = []
var coins: Array = []        # Vector3(s, x, y)
var pads: Array = []         # {s, x, used}
var canyon: Array = []       # نطاقات [s0, s1] يظهر فيها الوادي المائي بدل الأرض
var signs: Array = []        # لافتات تحذير قبل الحفر

const COLX := [-4.0, 0.0, 4.0]


func _init() -> void:
	_build_centerline()
	_layout()


# ------------------------------------------------------------------ الخط المركزي
static func _keys_value(keys: Array, s: float) -> float:
	if s <= keys[0][0]:
		return keys[0][1]
	for i in range(keys.size() - 1):
		var a: Array = keys[i]
		var b: Array = keys[i + 1]
		if s <= b[0]:
			var t: float = (s - a[0]) / maxf(b[0] - a[0], 0.0001)
			return lerpf(a[1], b[1], smoothstep(0.0, 1.0, t))
	return keys[keys.size() - 1][1]


## يبني مفاتيح الانحناء من قائمة منعطفات [بداية s، طول، زاوية بالدرجات (+ يمين)] بدخول/خروج ناعمين.
static func _bends_to_keys(bends: Array) -> Array:
	var keys := [[0.0, 0.0]]
	for b in bends:
		var s0: float = b[0]
		var l: float = b[1]
		var k := deg_to_rad(float(b[2])) / maxf(l - 25.0, 1.0)
		keys.append([s0, 0.0])
		keys.append([s0 + 25.0, k])
		keys.append([s0 + l - 25.0, k])
		keys.append([s0 + l, 0.0])
	keys.append([LENGTH + 20.0, 0.0])
	return keys


func _build_centerline() -> void:
	var curv := [[0, 0.0], [130, 0.0], [175, 0.0030], [240, 0.0030], [285, -0.0040], [370, -0.0040], [415, 0.0], [530, 0.0],
		[575, 0.0030], [640, 0.0030], [685, -0.0028], [760, -0.0028], [800, 0.0], [LENGTH + 20, 0.0]]
	var slope := [[0, 0.0], [210, 0.0], [250, 0.05], [290, 0.05], [330, -0.03], [370, 0.0], [560, 0.0], [600, 0.045],
		[650, 0.045], [700, -0.04], [740, 0.0], [LENGTH + 20, 0.0]]
	if layout == 1:
		# أنصاف أقطار ≈ 60 إلى 70 م (الحافة الداخلية ≥ 54 م): آمنة لعرض 12 م وللكاميرا. مستقيم أخير ≥ 90 م قبل خط النهاية.
		curv = _bends_to_keys([[130.0, 110.0, 75.0], [270.0, 140.0, -100.0], [450.0, 170.0, 120.0], [680.0, 100.0, -70.0], [800.0, 90.0, 55.0]])
		slope = [[0, 0.0], [150, 0.0], [190, 0.05], [250, 0.05], [300, -0.045], [345, 0.0], [470, 0.0], [510, 0.04],
			[570, 0.04], [620, -0.05], [665, 0.0], [820, 0.0], [850, 0.03], [890, 0.03], [930, -0.035], [960, 0.0], [LENGTH + 20, 0.0]]
	count = int((LENGTH + 40.0) / STEP) + 1
	pos.resize(count)
	fwd.resize(count)
	var heading := 0.0
	var p := Vector3.ZERO
	for i in range(count):
		var s := float(i) * STEP
		pos[i] = p
		var sl := _keys_value(slope, s)
		var d := Vector3(sin(heading), sl, -cos(heading))
		fwd[i] = d.normalized()
		heading += _keys_value(curv, s) * STEP
		p += Vector3(sin(heading), 0.0, -cos(heading)) * STEP
		p.y += sl * STEP


func _idx(s: float) -> Array:
	var f := clampf(s / STEP, 0.0, float(count - 1) - 0.001)
	var i := int(f)
	return [i, f - float(i)]


func center(s: float) -> Vector3:
	var a := _idx(s)
	return pos[a[0]].lerp(pos[a[0] + 1], a[1])


func forward(s: float) -> Vector3:
	var a := _idx(s)
	return (fwd[a[0]].lerp(fwd[a[0] + 1], a[1])).normalized()


func right(s: float) -> Vector3:
	var f := forward(s)
	var h := Vector3(f.x, 0.0, f.z).normalized()
	return h.cross(Vector3.UP).normalized()


func frame(s: float) -> Transform3D:
	var f := forward(s)
	var r := right(s)
	var u := r.cross(f).normalized()
	return Transform3D(Basis(r, u, -f), center(s))


func world(s: float, x: float, y: float = 0.0) -> Vector3:
	return center(s) + right(s) * x + Vector3.UP * y


func ground_y(s: float) -> float:
	return center(s).y


# ------------------------------------------------------------------ الحفر والتحقق من الأرضية
static func col_of(x: float) -> int:
	return clampi(int(floor((x + HALF_W) / COL_W)), 0, 2)


## هل توجد ألواح تحت النقطة (s, x)؟
func solid_at(s: float, x: float) -> bool:
	if s < 0.0:
		return true
	var mask_bit := 1 << col_of(x)
	for p in pits:
		if s >= p.s0 and s < p.s1 and (int(p.mask) & mask_bit) != 0:
			return false
	return true


func pit_at(s: float, x: float) -> Dictionary:
	var mask_bit := 1 << col_of(x)
	for p in pits:
		if s >= p.s0 and s < p.s1 and (int(p.mask) & mask_bit) != 0:
			return p
	return {}


# ------------------------------------------------------------------ بناء التخطيط
func _pit(s0: float, s1: float, mask: int) -> void:
	pits.append({"s0": s0, "s1": s1, "mask": mask})
	signs.append(s0 - 7.0)


func _log(s: float, x0: float, x1: float) -> void:
	obstacles.append({"type": "log", "s0": s - 0.55, "s1": s + 0.55, "x0": x0, "x1": x1, "y0": 0.0, "y1": 0.9, "alive": true, "s": s})


func _vine(s: float, x0: float, x1: float) -> void:
	obstacles.append({"type": "vine", "s0": s - 0.45, "s1": s + 0.45, "x0": x0, "x1": x1, "y0": 1.0, "y1": 3.2, "alive": true, "s": s})


func _crate(s: float, xc: float, levels := 1) -> void:
	obstacles.append({"type": "crate", "s0": s - 0.65, "s1": s + 0.65, "x0": xc - 0.65, "x1": xc + 0.65, "y0": 0.0, "y1": 1.25 * levels, "levels": levels, "alive": true, "s": s, "x": xc})


func _hammers(s: float, phase := 0.0, omega := 2.1) -> void:
	for k in range(2):
		var sgn := -1.0 if k == 0 else 1.0
		obstacles.append({"type": "hammer", "s": s, "px": 3.0 * sgn, "phase": phase + (0.0 if k == 0 else PI), "omega": omega, "amp": 0.72, "len": 5.45, "pivot_y": 6.2, "radius": 0.8, "alive": true,
			"s0": s - 1.3, "s1": s + 1.3, "x0": -6.0, "x1": 6.0, "y0": 0.0, "y1": 3.0})


func _coin_line(s0: float, s1: float, x: float, y := 0.9, gap := 3.0) -> void:
	var s := s0
	while s <= s1:
		coins.append(Vector3(s, x, y))
		s += gap


func _coin_arc(s: float, x: float, span := 8.0, peak := 2.2, n := 7) -> void:
	for k in range(n):
		var t := float(k) / float(n - 1)
		coins.append(Vector3(s - span * 0.5 + span * t, x, 0.9 + sin(t * PI) * (peak - 0.9)))


func _pad(s: float, x: float) -> void:
	pads.append({"s": s, "x": x, "used": false})


func _layout() -> void:
	var L := COLX[0]
	var M := COLX[1]
	var R := COLX[2]
	# --- منطقة الانطلاق (سهلة)
	_coin_line(40, 70, M)
	_crate(82, M)
	_coin_arc(82, M, 7.0, 2.4, 5)
	_log(108, -6.0, 2.0)
	_coin_line(100, 118, R)
	_pad(128, R)
	_coin_line(135, 150, M)
	# --- غابة العقبات
	_vine(170, -6.0, 6.0)
	_coin_line(164, 176, M, 0.5, 2.0)
	_crate(196, L)
	_crate(196, M)
	_coin_line(188, 205, R)
	_log(218, -6.0, 6.0)
	_coin_arc(218, M, 9.0, 2.5)
	_pit(238, 244, 1)
	_coin_line(232, 250, M)
	_crate(262, M, 2)
	_coin_line(252, 272, R)
	_vine(282, -6.0, 2.0)
	_coin_line(278, 288, R)
	_log(298, -2.0, 2.0)
	_pit(310, 318, 6)
	_coin_line(304, 322, L)
	# --- الجسر (حفر ومطارق)
	canyon.append([335.0, 560.0])
	_pit(346, 352, 7)
	_coin_arc(349, M, 11.0, 2.6, 7)
	_hammers(384, 0.0)
	_coin_line(372, 396, R, 0.9, 3.5)
	_pit(414, 420, 5)
	_coin_line(406, 428, M)
	_crate(442, L)
	_crate(442, M)
	_crate(442, R)
	_hammers(474, 1.2)
	_vine(500, -6.0, 6.0)
	_coin_line(494, 506, M, 0.5, 2.0)
	_pit(520, 526, 3)
	_coin_line(514, 534, R)
	# --- منطقة الفوضى
	_crate(548, L)
	_crate(548, M)
	_crate(562, M)
	_crate(562, R)
	_crate(576, L)
	_crate(576, R)
	_coin_line(540, 586, M, 0.9, 5.0)
	_log(600, -6.0, 2.0)
	_pit(612, 618, 2)
	_coin_line(604, 624, R)
	_hammers(644, 2.4, 2.4)
	_pad(664, M)
	_pit(676, 684, 7)
	_coin_arc(680, M, 13.0, 2.8, 8)
	_vine(704, -2.0, 6.0)
	_crate(722, M, 2)
	_coin_line(712, 740, L)
	# --- الاندفاع الأخير
	_pad(780, M)
	_coin_line(786, 820, M, 0.9, 3.0)
	_log(800, -6.0, -1.0)
	_log(800, 1.0, 6.0)
	_pad(836, R)
	_hammers(862, 0.6, 2.2)
	_pit(900, 905, 5)
	_coin_arc(902, M, 9.0, 2.4, 6)
	_crate(930, L)
	_crate(930, R)
	_pad(950, M)
	_coin_line(955, 990, M, 0.9, 3.0)


## أصغر مسافة أفقية بين نقطتين من المسار تفصل بينهما مسافة قوسية ≥ arc_gap (للتحقق من عدم اقتراب المسار من نفسه).
func min_self_distance(arc_gap := 120.0) -> float:
	var best := 1e9
	var i := 0
	while i < count:
		var j := i + int(arc_gap / STEP)
		while j < count:
			var d := Vector2(pos[i].x - pos[j].x, pos[i].z - pos[j].z).length()
			best = minf(best, d)
			j += 3
		i += 3
	return best


## أقصى انحناء مطلق (1/م) على الخط المركزي.
func max_curvature() -> float:
	var m := 0.0
	for i in range(1, count - 1):
		var a := Vector2(fwd[i - 1].x, fwd[i - 1].z).normalized()
		var b := Vector2(fwd[i + 1].x, fwd[i + 1].z).normalized()
		m = maxf(m, absf(a.angle_to(b)) / (2.0 * STEP))
	return m


## مجموع تغيّر الاتجاه (درجات، موجب = يمين) بين بداية المسار ونهايته.
func total_turn_deg() -> float:
	var a := Vector2(fwd[0].x, fwd[0].z).normalized()
	var b := Vector2(fwd[count - 2].x, fwd[count - 2].z).normalized()
	return rad_to_deg(a.angle_to(b))
