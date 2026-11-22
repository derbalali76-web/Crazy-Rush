// شلال: خطوط بيضاء زرقاء تنزل للأسفل.
shader_type spatial;
render_mode unshaded, cull_disabled;
uniform vec4 base_color : source_color = vec4(0.35, 0.82, 1.0, 1.0);
uniform vec4 foam_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
void fragment() {
	float streak = sin(UV.x * 38.0 + sin(UV.y * 5.0) * 1.5) * 0.5 + 0.5;
	float flow = fract(UV.y * 3.0 + TIME * 0.9 + streak * 0.6);
	float f = smoothstep(0.55, 0.9, flow) * (0.6 + 0.4 * streak);
	ALBEDO = mix(base_color.rgb, foam_color.rgb, f);
}
