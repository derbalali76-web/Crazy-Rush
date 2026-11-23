// ماء واقعي مبسّط للجوال: لون عمق، فرينل مع انعكاس السماء، لمعة الشمس، تموّجات ناعمة (بدون قراءة العمق).
shader_type spatial;
render_mode unshaded, cull_back;
uniform vec3 deep_color : source_color = vec3(0.03, 0.17, 0.15);
uniform vec3 shallow_color : source_color = vec3(0.10, 0.38, 0.32);
uniform vec3 sky_color : source_color = vec3(0.62, 0.78, 0.86);
uniform vec3 sun_dir = vec3(0.35, 0.62, 0.70);
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
vec2 grad(vec2 p, float t) {
	float a = sin(p.x * 0.9 + t * 0.8) * cos(p.y * 0.7 - t * 0.6);
	float b = sin(p.x * 2.3 - t * 1.4 + p.y * 1.7) * 0.5;
	float c = cos(p.y * 3.1 + t * 1.1 - p.x * 1.3) * 0.35;
	return vec2(a * 0.9 + b + c, cos(p.x * 1.1 - t) * 0.6 + b - c);
}
void fragment() {
	vec2 p = wp.xz;
	vec2 g = grad(p, TIME) * 0.10;
	vec3 n = normalize(vec3(-g.x, 1.0, -g.y));
	vec3 v = normalize((INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz);
	float fres = pow(1.0 - clamp(dot(n, v), 0.0, 1.0), 3.0);
	float k = clamp(sin(p.x * 0.11 + p.y * 0.08 + TIME * 0.2) * 0.5 + 0.5, 0.0, 1.0);
	vec3 col = mix(deep_color, shallow_color, k * 0.7);
	col = mix(col, sky_color, clamp(0.12 + fres * 0.75, 0.0, 0.85));
	vec3 r = reflect(-v, n);
	float spec = pow(clamp(dot(r, normalize(sun_dir)), 0.0, 1.0), 220.0);
	col += vec3(1.0, 0.93, 0.78) * spec * 1.2;
	float foam = smoothstep(0.80, 0.95, (sin(p.x * 0.6 + TIME * 0.5) * sin(p.y * 0.5 - TIME * 0.4)) * 0.5 + 0.5 + g.x * 1.2) * 0.04;
	ALBEDO = col + foam;
}
