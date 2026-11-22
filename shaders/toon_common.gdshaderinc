// شيدر الرسوم الكرتونية (Cel Shading) — مشترك بين النسختين أحادية الوجه ومزدوجة الوجه.
uniform vec4 shade_color : source_color = vec4(0.52, 0.42, 0.78, 1.0);
uniform float band_soft = 0.045;
uniform float rim_power = 2.6;
uniform vec4 rim_color : source_color = vec4(1.0, 0.86, 0.62, 1.0);
uniform float rim_amount = 0.20;
uniform vec4 tint : source_color = vec4(1.0);
uniform float spec_amount = 0.0;
uniform float wind_amount = 0.0;
uniform float hue_shift = 0.0;
uniform int detail_mode = 0;          // 0 بلا، 1 خشب، 2 عشب/أوراق، 3 صخر
uniform float detail_amount = 0.0;
varying vec3 v_obj;
varying vec3 v_wp;
varying vec3 v_col;
varying float v_emit;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
			mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x), f.y);
}

// تفاصيل مرسومة إجرائيًا (بلا ملفات صور): عامل ضرب على اللون الأساسي.
float detail_mul() {
	if (detail_mode == 1) {
		// خشب: ألياف طولية متموجة + عقد صغيرة + حافة داكنة
		float g = vnoise(vec2(v_obj.x * 3.0, v_obj.z * 22.0 + vnoise(v_obj.xz * 5.0) * 3.0));
		float rings = sin((v_obj.z + vnoise(v_obj.xz * 2.5) * 0.6) * 46.0) * 0.5 + 0.5;
		float knot = smoothstep(0.80, 0.97, vnoise(v_obj.xz * vec2(1.6, 7.0) + 11.0));
		return 1.0 - detail_amount * (0.60 * g + 0.10 * rings + 0.45 * knot) + detail_amount * 0.40;
	} else if (detail_mode == 2) {
		// عشب/أوراق: بقع كبيرة فاتحة وغامقة + ضربات صغيرة
		float b = vnoise(v_wp.xz * 0.55 + v_wp.y * 0.4);
		float sp = vnoise(v_wp.xz * 3.2 + v_wp.y * 1.7);
		float tick = smoothstep(0.72, 0.9, vnoise(v_wp.xz * vec2(9.0, 3.0) + v_wp.y * 2.0));
		return 1.0 + detail_amount * ((b - 0.5) * 0.9 + (sp - 0.5) * 0.35 + tick * 0.22);
	} else if (detail_mode == 3) {
		// صخر: تشققات خفيفة + تدرّج
		float n = vnoise(v_wp.xz * 1.3 + v_wp.y * 1.1);
		float cr = vnoise(v_wp.xz * 5.0 + v_wp.y * 4.0);
		float crack = smoothstep(0.46, 0.5, cr) * (1.0 - smoothstep(0.5, 0.54, cr));
		return 1.0 + detail_amount * ((n - 0.5) * 0.7 - crack * 0.9);
	}
	return 1.0;
}

vec3 hue_rot(vec3 c, float a) {
	float ca = cos(a);
	float sa = sin(a) * 0.57735;
	float k = (1.0 - ca) / 3.0;
	mat3 m = mat3(
		vec3(ca + k, k + sa, k - sa),
		vec3(k - sa, ca + k, k + sa),
		vec3(k + sa, k - sa, ca + k));
	return clamp(m * c, 0.0, 1.0);
}

void vertex() {
	v_col = COLOR.rgb;
	v_obj = VERTEX;
	v_wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_emit = 1.0 - COLOR.a;
	if (wind_amount > 0.0) {
		vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		float w = sin(TIME * 2.2 + wp.x * 0.35 + wp.z * 0.25) * wind_amount * clamp(VERTEX.y * 0.25, 0.0, 1.5);
		VERTEX.x += w;
		VERTEX.z += w * 0.6;
	}
}

void fragment() {
	vec3 base = hue_shift != 0.0 ? hue_rot(v_col, hue_shift) : v_col;
	if (detail_mode != 0) {
		base *= detail_mul();
	}
	ALBEDO = base * tint.rgb;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	float f = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), rim_power);
	EMISSION = rim_color.rgb * f * rim_amount * v_col + v_col * v_emit * 1.6;
}

void light() {
	float nl = dot(NORMAL, LIGHT);
	float lit = smoothstep(-band_soft, band_soft, nl) * ATTENUATION;
	float hi = smoothstep(0.55 - band_soft, 0.55 + band_soft, nl) * ATTENUATION;
	vec3 shade = mix(shade_color.rgb, vec3(1.0), lit);
	shade += vec3(0.16) * hi;
	DIFFUSE_LIGHT += LIGHT_COLOR / PI * shade;
	if (spec_amount > 0.0) {
		vec3 h = normalize(LIGHT + VIEW);
		float s = step(0.6, pow(max(dot(NORMAL, h), 0.0), 48.0)) * ATTENUATION;
		SPECULAR_LIGHT += LIGHT_COLOR / PI * s * spec_amount;
	}
}
