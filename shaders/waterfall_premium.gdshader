// شلال واقعي مبسّط: ماء شفاف بخيوط بيضاء ناعمة، يزداد بياضاً عند القاع مع رذاذ.
shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never;
uniform vec3 water_color : source_color = vec3(0.55, 0.78, 0.80);
uniform vec3 foam_color : source_color = vec3(0.96, 1.0, 1.0);
varying vec2 uv2;
void vertex() { uv2 = vec2(VERTEX.x / 9.0 + 0.5, clamp(-VERTEX.y / 34.0, 0.0, 1.0)); }
float h(float x) { return fract(sin(x * 127.1) * 43758.5453); }
void fragment() {
	float col = floor(uv2.x * 26.0);
	float sp = 0.55 + h(col) * 0.7;
	float y = uv2.y * 2.2 - TIME * sp + h(col + 3.0) * 5.0;
	float streak = smoothstep(0.35, 0.95, sin(y * 6.28) * 0.5 + 0.5);
	float fine = sin(uv2.x * 90.0 + sin(uv2.y * 8.0 - TIME * 2.0)) * 0.5 + 0.5;
	float f = clamp(streak * 0.7 + fine * 0.25, 0.0, 1.0);
	float edge = smoothstep(0.0, 0.12, uv2.x) * smoothstep(1.0, 0.88, uv2.x) * smoothstep(0.0, 0.08, uv2.y);
	float mist = smoothstep(0.80, 1.0, uv2.y);
	ALBEDO = mix(water_color, foam_color, clamp(f + mist * 0.8, 0.0, 1.0));
	ALPHA = clamp((0.45 + f * 0.4 + mist * 0.3) * edge, 0.0, 0.92);
}
