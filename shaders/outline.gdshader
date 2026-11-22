// خط محيط بأسلوب "الهيكل المقلوب": يُرسم كمرحلة تالية (next_pass).
shader_type spatial;
render_mode cull_front, unshaded;
uniform float thickness = 0.018;
uniform float darkness = 0.22;
varying vec3 v_col;
void vertex() {
	v_col = COLOR.rgb * darkness;
	float d = length((MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);
	VERTEX += NORMAL * thickness * clamp(d * 0.2, 0.6, 2.6);
}
void fragment() {
	ALBEDO = v_col;
}
