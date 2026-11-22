// شيدر الرسوم الكرتونية (Cel Shading) — مشترك بين النسختين أحادية الوجه ومزدوجة الوجه.
uniform vec4 shade_color : source_color = vec4(0.52, 0.42, 0.78, 1.0);
uniform float band_soft = 0.045;
uniform float rim_power = 2.6;
uniform vec4 rim_color : source_color = vec4(1.0, 0.86, 0.62, 1.0);
uniform float rim_amount = 0.20;
uniform vec4 tint : source_color = vec4(1.0);
uniform float spec_amount = 0.0;
uniform float wind_amount = 0.0;
varying vec3 v_col;
varying float v_emit;

void vertex() {
	v_col = COLOR.rgb;
	v_emit = 1.0 - COLOR.a;
	if (wind_amount > 0.0) {
		vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		float w = sin(TIME * 2.2 + wp.x * 0.35 + wp.z * 0.25) * wind_amount * clamp(VERTEX.y * 0.25, 0.0, 1.5);
		VERTEX.x += w;
		VERTEX.z += w * 0.6;
	}
}

void fragment() {
	ALBEDO = v_col * tint.rgb;
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
