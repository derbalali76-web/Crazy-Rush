class_name Menu
extends Control
## القائمة الرئيسية: الصورة المرجعية كخلفية فنية + عناصر Godot حقيقية فوقها.
## كل ما لم يُطوَّر بعد معتَّم بوسم «غير متاح حاليًا».

signal play_pressed

const W := 1672.0
const H := 941.0
const TAG_TEXT := "غير متاح حاليًا"
var BG: Texture2D = preload("res://assets/ui/menu_clean.png")   # بلا نصوص: كل النصوص تُكتب بلغة اللعبة

var _root: Control
var _settings: Control
var _bg_img: Image
var _dyn: Control
var _focus := 0
const ORDER := ["fox", "bombo", "ziko", "robo", "lulu", "dino", "bibo", "batboot", "kung", "sosu", "zain", "arthur"]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_bg_img = BG.get_image()
	var vp := get_viewport_rect().size
	set_deferred("size", vp)
	custom_minimum_size = vp

	# خلفية ضبابية ناعمة تملأ الأطراف على الشاشات الأعرض
	UiKit.add_backdrop(self, _bg_img, vp, W, H)

	var fit := UiKit.fit(vp, W, H)
	_root = Control.new()
	_root.size = Vector2(W, H)
	_root.scale = fit[0]
	_root.position = fit[1]
	add_child(_root)
	var bg := TextureRect.new()
	bg.texture = BG
	bg.size = Vector2(W, H)
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bg)

	_build()


func _hit(r: Rect2, cb: Callable) -> void:
	var b := Button.new()
	b.flat = true
	b.position = r.position
	b.size = r.size
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	_root.add_child(b)


func _box(r: Rect2, fill: Color, edge: Color, radius := 24, bw := 2) -> Panel:
	var p := Panel.new()
	p.position = r.position
	p.size = r.size
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = edge
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(radius)
	sb.anti_aliasing = true
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(p)
	return p


## تعتيم عنصر لم يُطوَّر بعد + وسم «غير متاح حاليًا» (ويمنع اللمس عليه).
func _unavailable(r: Rect2, fsize := 22, tag_dy := 0.0, show_tag := true) -> void:
	var cover := _box(r, Color(0.03, 0.05, 0.2, 0.52), Color(0, 0, 0, 0), 26, 0)
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	if not show_tag:
		return
	var tw := minf(r.size.x - 10.0, fsize * 7.2)
	var th := fsize * 1.6
	var tag := _box(Rect2(r.position + Vector2((r.size.x - tw) * 0.5, (r.size.y - th) * 0.5 + tag_dy), Vector2(tw, th)), Color(0.1, 0.12, 0.3, 0.92), Color("8a93c8"), 14, 2)
	var t := UiKit.label(Loc.t(TAG_TEXT), fsize, Color("dfe5ff"), 3)
	t.size = tag.size
	tag.add_child(t)


func _build() -> void:
	# --- الأزرار الفعّالة
	_hit(Rect2(1100, 775, 555, 145), func(): play_pressed.emit())      # العب الآن
	_hit(Rect2(1158, 208, 500, 120), _open_tracks)                    # ضد الكمبيوتر: اختيار الحلبة
	_hit(Rect2(1562, 18, 104, 108), _open_settings)                   # الإعدادات

	# --- عدّاد العملات والجواهر (الخلفية بلا أرقام)
	_txt(str(Settings.total_coins), Rect2(1145, 28, 112, 50), 38, Color.WHITE, Color("0b1450"), 8)
	_hit(Rect2(1240, 22, 56, 56), func(): _open_store(0))             # زر + (متجر العملات)
	# الجواهر
	_txt(str(Settings.gems), Rect2(1398, 28, 108, 50), 38, Color.WHITE, Color("0b1450"), 8)
	_hit(Rect2(1312, 22, 240, 56), func(): _open_store(1))             # متجر الجواهر
	# الملف الشخصي
	_hit(Rect2(30, 15, 440, 140), _open_account)                       # الملف الشخصي

	# --- العمود الأيسر
	_hit(Rect2(12, 245, 258, 96), _open_missions)                      # المهام
	_hit(Rect2(12, 362, 258, 96), func(): _open_screen("tour"))        # البطولات
	_hit(Rect2(12, 480, 258, 96), _open_costumes)                      # الأزياء
	_hit(Rect2(12, 598, 258, 96), func(): _open_store(0))                        # المتجر (شاشته جاهزة والمحتوى غير متاح)
	_build_texts()
	# اختيار الشخصية
	_dyn = Control.new()
	_dyn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_dyn)
	_focus = maxi(0, ORDER.find(Settings.selected_character))
	_refresh_char()
	_hit(Rect2(478, 570, 90, 100), func(): _set_focus(_focus - 1))    # سهم: تبديل الشخصية
	_hit(Rect2(1000, 570, 90, 100), func(): _set_focus(_focus + 1))
	# --- الأزرار اليمنى
	_unavailable(Rect2(1148, 340, 510, 115), 26)
	_unavailable(Rect2(1138, 468, 520, 120), 26)
	_unavailable(Rect2(1130, 600, 525, 120), 26)
	# --- الشريط السفلي
	_hit(Rect2(25, 808, 200, 112), func(): _open_screen("tour"))      # البطولات
	_hit(Rect2(235, 808, 200, 112), func(): _open_screen("r_week"))   # التصنيفات
	_hit(Rect2(445, 808, 200, 112), _open_tracks)                     # المسارات
	_hit(Rect2(655, 808, 200, 112), _open_select)                     # الشخصيات

	# أفضل زمن
	if Settings.best_time > 0.0:
		var best := UiKit.label(Loc.t("أفضل زمن: %.2f ث") % Settings.best_time, 28, Color("fff3a0"), 6)
		best.position = Vector2(40, 165)
		best.size = Vector2(430, 40)
		_root.add_child(best)


func _set_focus(i: int) -> void:
	_focus = posmod(i, ORDER.size())
	var id: String = ORDER[_focus]
	if Characters.is_playable(id):
		Settings.selected_character = id
		Settings.save_settings()
	_refresh_char()


## الشخصية المعروضة وسط القائمة؛ غير المتاحة تُعرض بصورتها مع وسم «غير متاح حاليًا».
func _refresh_char() -> void:
	for c in _dyn.get_children():
		c.queue_free()
	var id: String = ORDER[_focus]
	var keep := _root
	_root = _dyn
	# نقاط المؤشر أسفل الشخصية: 4 نقاط، كل نقطة تمثّل 3 شخصيات
	var page := _focus / 3
	for i in range(4):
		var on := i == page
		var dot := _box(Rect2(705.0 + i * 47.3 - 17.0, 756.0 - 17.0, 34, 34), Color("ffd54a") if on else Color("0a2a8a"), Color.WHITE if on else Color("5aa0ff"), 19, 4)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# الشخصية واقفة على المنصة (بلا بطاقة): ظل + حركة تنفّس خفيفة
	var tex := load("res://assets/characters/fox_menu.png") as Texture2D if id == "fox" else Characters.portrait(id)
	var ts := tex.get_size()
	var sc := minf(420.0 / ts.x, 440.0 / ts.y)
	var sz := ts * sc
	var feet := Vector2(795.0, 722.0)
	var shadow := Polygon2D.new()
	var pts := PackedVector2Array()
	for k in range(32):
		var an := TAU * k / 32.0
		pts.append(feet + Vector2(cos(an) * minf(sz.x * 0.5, 150.0), sin(an) * 24.0 - 6.0))
	shadow.polygon = pts
	shadow.color = Color(0.05, 0.0, 0.2, 0.38)
	_dyn.add_child(shadow)
	var tr := TextureRect.new()
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.texture = tex
	tr.size = sz
	tr.position = Vector2(feet.x - sz.x * 0.5, feet.y - sz.y)
	tr.pivot_offset = Vector2(sz.x * 0.5, sz.y)
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dyn.add_child(tr)
	tr.scale = Vector2(0.9, 0.9)
	var pop := create_tween()
	pop.tween_property(tr, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_callback(func():
		var br := create_tween().set_loops()
		br.tween_property(tr, "scale", Vector2(1.0, 1.018), 1.2).set_trans(Tween.TRANS_SINE)
		br.tween_property(tr, "scale", Vector2(1.0, 1.0), 1.2).set_trans(Tween.TRANS_SINE))
	var nme := Characters.character_name(id)
	UiKit.name_tag(_dyn, _bg_img, Rect2(342, 302, 236, 48), 338, nme, 40 if nme.length() < 12 else 32, Color("5a1a00"))
	# بطاقة القدرة الخاصة بالشخصية (بنفس تنسيق بطاقة فوكسي)
	var ab := Characters.ability(id)
	_box(Rect2(295, 395, 310, 172), Color(0.02, 0.16, 0.52, 1), Color("3aa8ff"), 24, 5)
	var ic := TextureRect.new()
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var ptex := "res://assets/characters/%s_ability.png" % id
	ic.texture = load(ptex) as Texture2D
	ic.position = Vector2(311, 414)
	ic.size = Vector2(108, 108)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dyn.add_child(ic)
	var at := UiKit.bold_label(ab[0], 27 if ab[0].length() < 14 else 22, Color("ffe400"), Color("3a2a00"), 7)
	at.position = Vector2(428, 405)
	at.size = Vector2(168, 44)
	at.clip_text = true
	_dyn.add_child(at)
	var ln := _box(Rect2(440, 452, 148, 2), Color("5ac8ff"), Color(0, 0, 0, 0), 1, 0)
	var ad := UiKit.bold_label(ab[1], 20 if ab[1].length() < 38 else 17, Color.WHITE, Color("0a1a4a"), 5)
	ad.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ad.custom_minimum_size = Vector2(168, 0)
	ad.position = Vector2(428, 456)
	ad.size = Vector2(172, 110)
	ad.add_theme_constant_override("line_spacing", -6)
	ad.clip_text = true
	_dyn.add_child(ad)
	if not Characters.is_playable(id):
		_unavailable(Rect2(1100, 775, 555, 145), 28)
	_root = keep


## نص بحجم يلائم المستطيل (يصغّر الخط حتى يتسع)
func _txt(text: String, r: Rect2, size: int, color: Color, outline_color: Color, outline := 6, bold := true) -> Label:
	var f := UiKit.font()
	var sz := size
	while sz > 16 and f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x * 1.12 > r.size.x:
		sz -= 2
	var l := UiKit.bold_label(text, sz, color, outline_color, outline) if bold else UiKit.label(text, sz, color, outline)
	l.position = r.position
	l.size = r.size
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_root.add_child(l)
	return l


func _player_level() -> Array:
	var xp: int = Settings.races_played * 50 + Settings.wins * 100 + Settings.total_coins
	return [xp / 500 + 1, xp % 500, 500]


func _build_texts() -> void:
	var navy := Color("0a1a5a")
	# بطاقة اللاعب: الاسم + المستوى + شريط الخبرة
	_txt(Settings.player_name, Rect2(180, 30, 280, 46), 40, Color.WHITE, navy, 6)
	var lv := _player_level()
	_txt(str(lv[0]), Rect2(172, 78, 66, 52), 34, Color.WHITE, Color("5a3a00"), 6)
	_box(Rect2(232, 90, 206, 36), Color("0b1c52"), Color("5a7ae0"), 16, 2)
	var fw := maxf(14.0, 198.0 * float(lv[1]) / float(lv[2]))
	_box(Rect2(236, 94, fw, 28), Color("ffc21a"), Color("ffe38a"), 13, 1)
	_txt("%d / %d" % [lv[1], lv[2]], Rect2(232, 90, 206, 36), 24, Color.WHITE, navy, 5)
	# العمود الأيسر
	for e in [[290.0, "المهام"], [405.0, "البطولات"], [522.0, "الأزياء"], [640.0, "المتجر"]]:
		_txt(Loc.t(e[1]), Rect2(126, e[0] - 40, 142, 80), 42, Color.WHITE, navy, 7)
	# البطاقات اليمنى (النص بين الأيقونتين)
	_txt(Loc.t("ضد الكمبيوتر"), Rect2(1290, 226, 190, 48), 42, Color("4a2400"), Color.WHITE, 5)
	_txt(Loc.t("تحدي الذكاء الاصطناعي"), Rect2(1285, 272, 200, 40), 24, Color("4a2400"), Color.WHITE, 0, false)
	var cards := [[399.0, "أونلاين", "منافسة عالمية", Color("0a2a7a"), Rect2(1300, 0, 215, 0)], [526.0, "غرفة الأصدقاء", "العب مع أصدقائك", Color("3a0a70"), Rect2(1165, 0, 255, 0)], [655.0, "بلوتوث", "لعب محلي قريب", Color("0a4a14"), Rect2(1165, 0, 235, 0)]]
	for c in cards:
		var zr: Rect2 = c[4]
		_txt(Loc.t(c[1]), Rect2(zr.position.x, c[0] - 46, zr.size.x, 50), 42, Color.WHITE, c[3], 7)
		_txt(Loc.t(c[2]), Rect2(zr.position.x, c[0] + 6, zr.size.x, 40), 24, Color("e8eeff"), c[3], 4)
	# زر العب الآن
	_txt(Loc.t("العب الآن"), Rect2(1270, 785, 270, 90), 66, Color("5a2300"), Color.WHITE, 9)
	# الشريط السفلي
	for e in [[130.0, "البطولات"], [340.0, "الترتيب"], [548.0, "المسارات"], [755.0, "الشخصيات"]]:
		_txt(Loc.t(e[1]), Rect2(e[0] - 95, 855, 190, 46), 36, Color.WHITE, navy, 6)
	_txt(Loc.t("الرئيسية"), Rect2(860, 855, 190, 46), 36, Color.WHITE, Color("7a3a00"), 6)


func _open_costumes() -> void:
	if _settings:
		return
	var cid: String = ORDER[_focus]
	if not CostumesScreen.has_store(cid):
		cid = "fox"
	var cs := CostumesScreen.new()
	cs.char_id = cid
	cs.closed.connect(func(): _settings = null)
	_settings = cs
	add_child(cs)


func _open_missions() -> void:
	_open_screen("m_day")


func _open_screen(id: String) -> void:
	if _settings:
		return
	var ms := CostumesScreen.new()
	ms.char_id = id
	ms.start_pressed.connect(func(): play_pressed.emit())
	ms.closed.connect(func(): _settings = null)
	_settings = ms
	add_child(ms)


func _open_account() -> void:
	if _settings:
		return
	var ac := AccountScreen.new()
	ac.closed.connect(func(): _settings = null)
	_settings = ac
	add_child(ac)


func _open_tracks() -> void:
	if _settings:
		return
	var ts := TrackSelect.new()
	ts.closed.connect(func(): _settings = null)
	ts.start_pressed.connect(func(): play_pressed.emit())
	ts.choose_character_pressed.connect(func():
		ts.queue_free()
		_settings = null
		_open_select())
	_settings = ts
	add_child(ts)


func _open_select() -> void:
	if _settings:
		return
	var cs := CharacterSelect.new()
	cs.closed.connect(func(): _settings = null)
	cs.start_pressed.connect(func(): play_pressed.emit())
	_settings = cs
	add_child(cs)


func _open_store(tab := 0) -> void:
	if _settings:
		return
	var st := StoreScreen.new()
	st.closed.connect(func(): _settings = null)
	_settings = st
	add_child(st)
	if tab != 0:
		st._select(tab)


func _open_settings() -> void:
	if _settings:
		return
	var sp := SettingsPanel.new()
	sp.closed.connect(func():
		_settings.queue_free()
		_settings = null)
	_settings = sp
	add_child(sp)
