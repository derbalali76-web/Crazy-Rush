class_name ScreenBase
extends Control
## أساس الشاشات بصور بلا نصوص: الصورة كخلفية + نصوص وأرقام حقيقية بلغة اللعبة + أزرار شفافة.
## الصنف الفرعي يعيّن bg_path ثم يبني عناصره في _build().
signal closed

const TAG_TEXT := "غير متاح حاليًا"

var bg_path := ""
var W := 1863.0
var H := 844.0
var _root: Control
var _host: Control          # حاوية العناصر (افتراضيًا الجذر) تتبدّل في الشاشات متعددة التبويبات
var _bg_rect: TextureRect
var _bg_img: Image
var _tex: Texture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	_tex = load(bg_path)
	_bg_img = _tex.get_image()
	W = float(_bg_img.get_width())
	H = float(_bg_img.get_height())
	var vp := get_viewport_rect().size
	set_deferred("size", vp)
	custom_minimum_size = vp
	UiKit.add_backdrop(self, _bg_img, vp, W, H)
	var fit := UiKit.fit(vp, W, H)
	_root = Control.new()
	_root.size = Vector2(W, H)
	_root.scale = fit[0]
	_root.position = fit[1]
	add_child(_root)
	var bg := TextureRect.new()
	bg.texture = _tex
	bg.size = Vector2(W, H)
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bg)
	_bg_rect = bg
	_host = _root
	_build()


func _build() -> void:
	pass


func _close() -> void:
	closed.emit()
	queue_free()


func hit(r: Rect2, cb: Callable) -> Button:
	var b := Button.new()
	b.flat = true
	b.position = r.position
	b.size = r.size
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	_host.add_child(b)
	return b


func box(r: Rect2, fill: Color, edge := Color(0, 0, 0, 0), radius := 24, bw := 0) -> Panel:
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
	_host.add_child(p)
	return p


## نص ثقيل يُصغَّر ليتسع في المستطيل (سطر واحد) أو يلتف عند wrap.
func txt(text: String, r: Rect2, size := 34, color := Color.WHITE, outline_color := Color("0a1a5a"), outline := 6, wrap := false, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var f := UiKit.font()
	var sz := size
	if not wrap:
		while sz > 14 and f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x * 1.1 > r.size.x:
			sz -= 2
	var l := UiKit.bold_label(text, sz, color, outline_color, outline)
	l.position = r.position + Vector2(0, -0.2 * float(sz))
	l.size = r.size
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_constant_override("line_spacing", int(-0.34 * float(sz)))
		l.position.y += 0.1 * float(sz)
	_host.add_child(l)
	return l


## رقم ثقيل بنمط عدّادات اللعبة.
func num(text: String, r: Rect2, size := 36) -> Label:
	var l := UiKit.num_label(text, size)
	l.position = r.position
	l.size = r.size
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.clip_text = true
	_host.add_child(l)
	return l


func unavailable(r: Rect2, fsize := 22, show_tag := true, alpha := 0.55, radius := 26) -> void:
	var cover := box(r, Color(0.03, 0.05, 0.2, alpha), Color(0, 0, 0, 0), radius, 0)
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	if not show_tag:
		return
	var tw := minf(r.size.x - 10.0, fsize * 7.4)
	var th := fsize * 1.6
	var tag := box(Rect2(r.position + Vector2((r.size.x - tw) * 0.5, (r.size.y - th) * 0.5), Vector2(tw, th)), Color(0.1, 0.12, 0.3, 0.92), Color("8a93c8"), 14, 2)
	var t := UiKit.label(Loc.t(TAG_TEXT), fsize, Color("dfe5ff"), 3)
	t.size = tag.size
	tag.add_child(t)


## الشريط العلوي: عدّاد العملات والجواهر + أزرار + ومنزل. plus_c/plus_g = مستطيلا زرّي + (من كشف الصورة)
func topbar(plus_c: Rect2, plus_g: Rect2, home: Rect2, home_cb := Callable()) -> void:
	var cy := plus_c.position.y + plus_c.size.y * 0.5
	num(UiKit.fmt_int(Settings.total_coins), Rect2(plus_c.position.x - 150, cy - 24, 138, 48), 32)
	num(UiKit.fmt_int(Settings.gems), Rect2(plus_g.position.x - 150, cy - 24, 138, 48), 32)
	hit(plus_c.grow(10), func(): _plus(0))
	hit(plus_g.grow(10), func(): _plus(1))
	hit(home, home_cb if home_cb.is_valid() else _close)


func _plus(tab: int) -> void:
	UiKit.open_store(self, tab)
