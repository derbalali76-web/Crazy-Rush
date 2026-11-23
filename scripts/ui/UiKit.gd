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
