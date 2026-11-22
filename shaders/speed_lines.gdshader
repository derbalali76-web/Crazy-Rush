shader_type canvas_item;
// خطوط السرعة على حواف الشاشة (خفيفة: حساب بسيط لكل بكسل بلا نسيج).
uniform float intensity = 0.0;

float hash(float n) {
	return fract(sin(n * 12.9898) * 43758.5453);
}

void fragment() {
	vec2 uv = UV - 0.5;
	uv.x *= SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	float r = length(uv);
	float a = atan(uv.y, uv.x);
	float n = floor(a * 38.0);
	float h = hash(n);
	float on = step(0.62, h);
	float fl = fract(r * 2.6 - TIME * (3.0 + h * 3.0) + h * 7.0);
	float edge = smoothstep(0.30, 0.78, r);
	float alpha = on * edge * (0.25 + 0.75 * fl) * intensity;
	COLOR = vec4(1.0, 1.0, 1.0, alpha * 0.5);
}
