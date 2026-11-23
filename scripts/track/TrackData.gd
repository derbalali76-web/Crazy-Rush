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

## ---- تجريبي (layout 2): ارتفاعات لكل عمود + تفرعات + أنفاق. الافتراضي بلا أثر (كل الارتفاعات صفر).
var has_heights := false
var col_off: Array = [[], [], []]      # لكل عمود مفاتيح [s, ارتفاع نسبةً للخط المركزي]
var common_off: Array = []             # فرق ارتفاع مشترك لكل الأعمدة (مثل هبوط قفزة الوادي)
var forks: Array = []                  # {id, s0, s1, high_col, low_col}
var tunnels: Array = []                # {s0, s1, col, height}
var mounds: Array = []                 # كتل جبلية للرسم فقط {s0, s1, x0, x1, top}

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
	if layout == 2:
		# منعطفات لطيفة؛ الصعود والهبوط الرئيسيان على الخط المركزي نفسه، وفروق التفرع على الأعمدة
		curv = _bends_to_keys([[130.0, 110.0, 35.0], [470.0, 150.0, -50.0], [700.0, 120.0, 45.0]])
		slope = [[0, 0.0], [110, 0.0], [135, 0.06], [245, 0.06], [270, 0.0], [440, 0.0], [470, -0.045], [540, -0.045], [560, 0.0],
			[574, 0.0], [584, 0.15], [592, 0.15], [598, -0.02], [680, -0.02], [700, 0.0], [LENGTH + 20, 0.0]]
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


## ارتفاع سطح العمود عند (s, x) نسبةً للخط المركزي. صفر دائمًا في الحلبات المستقرة (سلوك متطابق).
func deck_h(s: float, x: float) -> float:
	if not has_heights:
		return 0.0
	var h := 0.0
	if not common_off.is_empty():
		h = _keys_value(common_off, s)
	var keys: Array = col_off[col_of(x)]
	if not keys.is_empty():
		h += _keys_value(keys, s)
	return h


## مستوى السقوط (الهاوية) تحت العمود: يُعدّ اللاعب ساقطًا إن نزل عنه فوق فراغ.
func abyss_y(s: float, x: float) -> float:
	return deck_h(s, x) - 2.2


## سقف النفق عند (s, x) أو +INF إن لم يكن نفقًا (تستعمله الكاميرا).
func ceiling_at(s: float, x: float) -> float:
	if not has_heights:
		return INF
	var c := col_of(x)
	for t in tunnels:
		if int(t.col) == c and s >= t.s0 - 4.0 and s <= t.s1 + 4.0:
			return deck_h(s, x) + float(t.height)
	return INF


## التفرع الذي يشمل المسافة s (أو {}).
func fork_at(s: float, lead := 0.0) -> Dictionary:
	for f in forks:
		if s >= f.s0 - lead and s <= f.s1:
			return f
	return {}


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
	if layout == 1:
		_layout_jungle()
		return
	if layout == 2:
		_layout_branch()
		_apply_heights()
		return
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


## ترتيب العقبات للحلبة المتعرجة «غابة» (تجريبي): 8 مقاطع بإيقاع مقصود، انظر docs/art/JUNGLE_TRACK_DESIGN.md.
## القواعد: أقصر فجوة 6–8 م، ≥ 9 م بين أي خطرين متتاليين، ولا خطر بعد s=910 (الخط الأخير نظيف).
func _layout_jungle() -> void:
	var L := COLX[0]
	var M := COLX[1]
	var R := COLX[2]
	# 1) بوابة الغابة: سهل
	_coin_line(40, 70, M)
	_crate(84, M)
	_coin_arc(84, M, 7.0, 2.4, 5)
	_coin_line(98, 116, R)
	_pad(122, R)
	# 2) ممر الجذور (منعطف يمين): جذوع تعلّم القفز ثم الانحناء
	_log(150, -6.0, 2.0)
	_coin_line(140, 158, R)
	_log(168, -2.0, 6.0)
	_coin_arc(168, M, 9.0, 2.5)
	_vine(190, -6.0, 6.0)
	_coin_line(182, 198, M, 0.5, 2.0)
	_crate(212, L)
	_crate(212, M)
	_coin_line(206, 224, R)
	_log(236, -6.0, 6.0)
	_pad(250, M)
	# 3) معبد الأطلال (منعطف يسار): مطارق وصناديق بين الأعمدة
	_hammers(284, 0.0)
	_coin_line(272, 298, M, 0.9, 3.5)
	_crate(310, R, 2)
	_coin_line(302, 322, L)
	_vine(330, -6.0, 2.0)
	_coin_line(326, 336, R)
	# 4) الوادي والشلال: جسر فيه فجوات
	canyon.append([345.0, 560.0])
	_pit(360, 366, 7)
	_coin_arc(363, M, 11.0, 2.6, 7)
	_hammers(392, 1.2)
	_coin_line(380, 404, R, 0.9, 3.5)
	_pit(420, 426, 5)
	_coin_line(412, 434, M)
	_crate(446, L)
	_crate(446, M)
	_crate(446, R)
	_pit(468, 474, 3)
	_coin_line(458, 480, R)
	_hammers(498, 2.4, 2.4)
	_vine(522, -6.0, 6.0)
	_coin_line(516, 528, M, 0.5, 2.0)
	_pad(540, M)
	# 5) منعطف الصخور (يمين 120°): سرعة ثم صناديق متناثرة
	_crate(574, L)
	_crate(574, R)
	_crate(590, M)
	_coin_line(566, 604, M, 0.9, 5.0)
	_log(612, -6.0, 2.0)
	_pit(626, 632, 2)
	_coin_line(618, 640, R)
	# 6) جسر الحبال (يسار 70°): عقبات يسار/يمين متبادلة
	_log(656, 1.0, 6.0)
	_log(672, -6.0, -1.0)
	_pad(688, M)
	_pit(700, 708, 7)
	_coin_arc(704, M, 13.0, 2.8, 8)
	_vine(722, -2.0, 6.0)
	_crate(738, M, 2)
	_coin_line(728, 760, L)
	# 7) الدرب المضيء (يمين 55°): مطارق وصناديق متراصّة
	_pad(774, M)
	_coin_line(780, 812, M, 0.9, 3.0)
	_log(800, -6.0, -1.0)
	_log(800, 1.0, 6.0)
	_hammers(832, 0.6, 2.2)
	_pad(850, R)
	_pit(866, 872, 5)
	_coin_arc(869, M, 9.0, 2.4, 6)
	_crate(892, L)
	_crate(892, R)
	# 8) الخط الأخير: نظيف
	_pad(930, M)
	_coin_line(936, 990, M, 0.9, 3.0)


## يضيف ارتفاع السطح لكل عملة وعائق (إحداثيات y مطلقة نسبةً للخط المركزي).
func _apply_heights() -> void:
	if not has_heights:
		return
	for i in range(coins.size()):
		var c: Vector3 = coins[i]
		coins[i] = Vector3(c.x, c.y, c.z + deck_h(c.x, c.y))
	for o in obstacles:
		var xc := 0.5 * (float(o.x0) + float(o.x1))
		var h := deck_h(float(o.s), xc)
		o["y0"] = float(o.y0) + h
		o["y1"] = float(o.y1) + h
		o["base_h"] = h
		if o.type == "hammer":
			o["pivot_y"] = float(o.pivot_y) + h


## تفرع: عمود علوي (ridge) وعمود سفلي (نفق) يفصل بينهما فراغ، مع ممر هبوط وعتبة مهارة وسرعة مكافأة.
## side = -1 العلوي يسار، +1 العلوي يمين. يضيف الفراغ والعتبة والمسرّعات والنفق والعملات.
func _fork(id: String, s0: float, side: int, hi: float) -> void:
	var hc := 0 if side < 0 else 2
	var lc := 2 if side < 0 else 0
	var hx: float = COLX[hc]
	var lx: float = COLX[lc]
	var sg := float(side)
	# العمود العلوي: يصعد خلال 38 م ويبقى ثم ينزل خلال 41 م
	col_off[hc] = [[0.0, 0.0], [s0, 0.0], [s0 + 38.0, hi], [s0 + 112.0, hi], [s0 + 153.0, 0.0], [LENGTH + 20.0, 0.0]]
	# الفراغ الفاصل (العمود الأوسط) مع نافذة هبوط/عبور بين s0+78 و s0+98
	_pit(s0, s0 + 78.0, 2)
	signs.append(s0 - 14.0)
	_pit(s0 + 98.0, s0 + 158.0, 2)
	# عتبة المهارة: ثلم 6 م في المسار العلوي ثم مسرّعان
	_pit(s0 + 56.0, s0 + 62.0, 1 << hc)
	_coin_arc(s0 + 59.0, hx, 10.0, 2.8, 7)
	_pad(s0 + 70.0, hx)
	_pad(s0 + 92.0, hx)
	_coin_line(s0 + 36.0, s0 + 52.0, hx)
	_coin_line(s0 + 66.0, s0 + 76.0, hx)
	# النفق السفلي
	tunnels.append({"s0": s0 + 25.0, "s1": s0 + 140.0, "col": lc, "height": 7.5})
	_crate(s0 + 42.0, lx)
	_log(s0 + 60.0, lx - 1.8, lx + 1.8)
	_vine(s0 + 82.0, lx - 1.8, lx + 1.8)
	_crate(s0 + 104.0, lx, 2)
	_log(s0 + 122.0, lx - 1.8, lx + 1.8)
	_coin_line(s0 + 30.0, s0 + 138.0, lx, 0.9, 6.0)
	# ممر الهبوط (الفراغ مغلق): عملات على العمود الأوسط
	_coin_line(s0 + 80.0, s0 + 96.0, COLX[1], 0.9, 4.0)
	# كتل الجبل للرسم
	mounds.append({"s0": s0 + 20.0, "s1": s0 + 145.0, "x0": 2.2 if lc == 2 else -14.0, "x1": 14.0 if lc == 2 else -2.2, "top": 13.0})
	forks.append({"id": id, "s0": s0, "s1": s0 + 158.0, "high_col": hc, "low_col": lc, "side": side, "hi": hi})


func _layout_branch() -> void:
	has_heights = true
	var M := COLX[1]
	var R := COLX[2]
	var L := COLX[0]
	# 1) انطلاق سهل
	_coin_line(40, 70, M)
	_crate(84, M)
	_coin_arc(84, M, 7.0, 2.4, 5)
	_coin_line(98, 116, R)
	_pad(122, R)
	# 2) مرتفع صاعد بعقبات خفيفة
	_log(152, -6.0, 2.0)
	_coin_line(142, 160, R)
	_log(176, -2.0, 6.0)
	_vine(204, -6.0, 6.0)
	_coin_line(190, 230, M, 0.9, 4.0)
	# 3) تفرع A (العلوي يسار، 262 → 420)
	_fork("A", 262.0, -1, 7.0)
	# 4) وادٍ هابط ثم قفزة الوادي 592→600 (كامل العرض) بمنحدر إقلاع وهبوط أخفض
	_coin_line(450, 500, M, 0.9, 4.0)
	_crate(470, L)
	_crate(470, R)
	_log(500, -6.0, 2.0)
	_vine(526, -6.0, 6.0)
	_pad(560, M)
	_pit(592.0, 600.0, 7)
	signs.append(578.0)
	_coin_arc(596.0, M, 12.0, 3.4, 8)
	common_off = [[0.0, 0.0], [594.0, 0.0], [596.5, -2.2], [LENGTH + 20.0, -2.2]]
	_pad(606, M)
	# 5) هبوط ثم تفرع B (العلوي يمين) 700 → 858 مع عودة الارتفاع للصفر
	_crate(640, M)
	_log(656, 1.0, 6.0)
	_log(672, -6.0, -1.0)
	_fork("B", 700.0, 1, 6.0)
	# 6) النهاية
	_crate(880, L)
	_crate(880, R)
	_pad(900, M)
	_vine(918, -6.0, 6.0)
	_coin_line(936, 990, M, 0.9, 3.0)


## أصغر فجوة بين خطرين متتاليين (حفر/عقبات) بعد ترتيبهما على المحور s، وآخر خطر.
func hazard_stats() -> Dictionary:
	var ss: Array = []
	for p in pits:
		ss.append(float(p.s0))
	for o in obstacles:
		if o.type == "hammer" or o.type == "log" or o.type == "vine" or o.type == "crate":
			ss.append(float(o.s))
	ss.sort()
	var mn := 1e9
	for i in range(1, ss.size()):
		if ss[i] - ss[i - 1] > 0.5:
			mn = minf(mn, ss[i] - ss[i - 1])
	var maxpit := 0.0
	for p in pits:
		maxpit = maxf(maxpit, float(p.s1) - float(p.s0))
	return {"min_gap": mn, "last": ss[ss.size() - 1], "max_pit": maxpit}
