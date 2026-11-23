class_name UiKit
extends RefCounted
## أدوات بناء واجهات كرتونية لامعة بعناصر Godot حقيقية (ليست صورًا خلفية).

static var _font: Font

const C_GOLD_TOP := Color("ffd23a")
const C_GOLD_BOT := Color("ff9a12")
const C_BLUE_TOP := Color("4aa3ff")
const C_BLUE_BOT := Color("2456d8")
const C_GREEN_TOP := Color("5be04e")
const C_GREEN_BOT := Color("1fa83a")
const C_PURPLE_TOP := Color("b36bff")
const C_PURPLE_BOT := Color("6a35d8")
const C_RED_TOP := Color("ff6a5c")
const C_RED_BOT := Color("d4262c")
const C_PANEL := Color("1b2a6b")
const C_PANEL_EDGE := Color("5aa0ff")


static func font() -> Font:
	if _font == null:
		_font = load("res://assets/fonts/Cairo.ttf")
	return _font


static func style(top: Color, bottom: Color, radius := 22, border := Color.WHITE, border_w := 4) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = top.lerp(bottom, 0.5)
	sb.set_corner_radius_all(radius)
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 7
	sb.shadow_offset = Vector2(0, 5)
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	sb.anti_aliasing = true
	return sb


static func label(text: String, size := 28, color := Color.WHITE, outline := 6, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color("1a1040"))
	l.add_theme_constant_override("outline_size", outline)
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func button(text: String, top: Color, bottom: Color, size := Vector2(260, 72), font_size := 30) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = size
	b.add_theme_font_override("font", font())
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color("fff2b0"))
	b.add_theme_color_override("font_outline_color", Color("2a1450"))
	b.add_theme_constant_override("outline_size", 7)
	var n := style(top, bottom)
	var h := style(top.lightened(0.12), bottom.lightened(0.1))
	var p := style(top.darkened(0.12), bottom.darkened(0.12))
	p.shadow_offset = Vector2(0, 1)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", p)
	b.add_theme_stylebox_override("focus", n)
	b.focus_mode = Control.FOCUS_NONE
	return b


static func panel(size: Vector2) -> Panel:
	var p := Panel.new()
	p.custom_minimum_size = size
	p.size = size
	var sb := style(C_PANEL, C_PANEL.darkened(0.25), 30, C_PANEL_EDGE, 5)
	sb.bg_color = Color(0.1, 0.16, 0.45, 0.94)
	sb.shadow_size = 14
	p.add_theme_stylebox_override("panel", sb)
	return p


static func center_in(parent: Control, child: Control) -> void:
	parent.add_child(child)
	child.set_anchors_preset(Control.PRESET_CENTER)
	child.position = (parent.size - child.size) * 0.5


## اسم شخصية بنمط اسم «فوكسي»: يُغطّى النص المرسوم بشريط من لون الشريط نفسه ثم يُكتب الاسم بخط أبيض ثقيل بحدّ داكن.
static func name_tag(parent: Control, bg_img: Image, r: Rect2, sample_x: int, text: String, size: int, outline: Color) -> void:
	var strip := Image.create(1, int(r.size.y), false, Image.FORMAT_RGBA8)
	for i in range(int(r.size.y)):
		strip.set_pixel(0, i, bg_img.get_pixel(sample_x, int(r.position.y) + i))
	var pt := TextureRect.new()
	pt.texture = ImageTexture.create_from_image(strip)
	pt.position = r.position
	pt.size = r.size
	pt.stretch_mode = TextureRect.STRETCH_SCALE
	pt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(pt)
	var fv := FontVariation.new()
	fv.base_font = font()
	fv.variation_embolden = 1.1
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", fv)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_color_override("font_outline_color", outline)
	l.add_theme_constant_override("outline_size", 9)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.position = r.position
	l.size = r.size
	l.clip_text = true
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)


## رقم عدّاد العملات: خط ثقيل أبيض بحدّ داكن ليناسب أرقام الواجهة المرسومة.
static func num_label(text: String, size := 36) -> Label:
	var fv := FontVariation.new()
	fv.base_font = font()
	fv.variation_embolden = 1.3
	var l := label(text, size, Color.WHITE, 8)
	l.add_theme_font_override("font", fv)
	l.add_theme_color_override("font_outline_color", Color("0b1450"))
	return l


## نص ثقيل بنمط نصوص الواجهة المرسومة (خط Cairo مُسمَّك + حدّ داكن).
static func bold_label(text: String, size: int, color: Color, outline_color: Color, outline := 7) -> Label:
	var fv := FontVariation.new()
	fv.base_font = font()
	fv.variation_embolden = 1.0
	var l := label(text, size, color, outline)
	l.add_theme_font_override("font", fv)
	l.add_theme_color_override("font_outline_color", outline_color)
	return l


## ملاءمة شاشة مرجعية W×H لأي نسبة عرض: تمدّد أفقي طفيف (حتى 12%) ثم هوامش تُملأ بامتداد حافة الصورة.
## يعيد [مقياس Vector2, موضع Vector2].
static func fit(vp: Vector2, w: float, h: float) -> Array:
	var s := minf(vp.x / w, vp.y / h)
	var sx := minf(vp.x / w, s * 1.12)
	var sy := minf(vp.y / h, s * 1.12) if vp.y / h > s else s
	var sc := Vector2(sx, sy)
	return [sc, (vp - Vector2(w, h) * sc) * 0.5]


## خلفية تملأ الشاشة كلها: تُستخرج من الصورة المرجعية بتثبيت الحواف (clamp) وتنعيمها فتتصل ألوانها بالمشهد.
static func add_backdrop(parent: Control, ref: Image, vp: Vector2, w: float, h: float) -> void:
	var f := fit(vp, w, h)
	var sc: Vector2 = f[0]
	var pos: Vector2 = f[1]
	var small := ref.duplicate() as Image
	small.resize(24, 14, Image.INTERPOLATE_BILINEAR)
	small.resize(167, 94, Image.INTERPOLATE_BILINEAR)
	var bw := 240
	var bh := maxi(8, int(round(bw * vp.y / vp.x)))
	var out := Image.create(bw, bh, false, Image.FORMAT_RGB8)
	for j in range(bh):
		var v := _fold(((j + 0.5) / bh * vp.y - pos.y) / (h * sc.y))
		for i in range(bw):
			var u := _fold(((i + 0.5) / bw * vp.x - pos.x) / (w * sc.x))
			out.set_pixel(i, j, small.get_pixel(int(u * 167), int(v * 94)))
	var tr := TextureRect.new()
	tr.texture = ImageTexture.create_from_image(out)
	tr.size = vp
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	tr.modulate = Color(0.85, 0.88, 0.95)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(tr)


## انعكاس مثلثي إلى [0، 0.999] لاستمرار المشهد خلف الحواف بدل تمديد عمود واحد.
static func _fold(t: float) -> float:
	var m := fposmod(t, 2.0)
	if m > 1.0:
		m = 2.0 - m
	return clampf(m, 0.0, 0.999)
