// ماء كرتوني متحرك بخطوط رغوة.
shader_type spatial;
render_mode unshaded, cull_back;
uniform vec4 deep_color : source_color = vec4(0.05, 0.38, 0.72, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.18, 0.78, 0.92, 1.0);
uniform vec4 foam_color : source_color = vec4(0.92, 1.0, 1.0, 1.0);
varying vec3 wp;
void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float a = sin(wp.x * 0.35 + TIME * 0.9) * sin(wp.z * 0.28 - TIME * 0.7);
	float b = sin(wp.x * 0.9 - TIME * 1.3 + wp.z * 0.4) * 0.5 + 0.5;
	vec3 col = mix(deep_color.rgb, shallow_color.rgb, clamp(a * 0.5 + 0.5, 0.0, 1.0) * 0.8);
	float foam = smoothstep(0.93, 0.97, sin(wp.z * 0.55 + sin(wp.x * 0.3 + TIME * 0.5) * 2.0 + TIME * 0.8) * 0.5 + 0.5) * 0.7;
	foam += smoothstep(0.96, 0.99, b) * 0.35;
	ALBEDO = mix(col, foam_color.rgb, clamp(foam, 0.0, 1.0));
}
