// خامة «واقعية مُنمَّطة»: خرائط PBR CC0 تُعرض Triplanar (بلا UV) وتُمزج مع ألوان الرؤوس (الهوية اللونية)
// ثم تُضاء بنمط كرتوني ناعم مع تضاريس من خريطة normal. تجريبية (فرع art-premium) خلف Toon.premium_enabled.
uniform sampler2D albedo_tex : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D normal_tex : hint_normal, repeat_enable, filter_linear_mipmap;
uniform float tex_scale = 0.6;
uniform float tex_avg_lum = 0.35;
uniform float vc_mix = 0.65;          // 0 لون الخامة كما هو، 1 لون الرؤوس مع تفاصيل الخامة
uniform float tex_sat = 0.55;
uniform float normal_strength = 0.9;
uniform bool use_normal = true;
uniform bool planar_only = false;   // عينة واحدة من الأعلى (أرض مسطحة): أرخص بثلاث مرات
uniform bool world_space = false;
uniform vec4 shade_color : source_color = vec4(0.46, 0.40, 0.70, 1.0);
uniform float band_soft = 0.32;       // أنعم من الكرتون الصلب
uniform float rim_power = 2.6;
uniform vec4 rim_color : source_color = vec4(1.0, 0.86, 0.62, 1.0);
uniform float rim_amount = 0.14;
uniform float wind_amount = 0.0;
varying vec3 v_pos;
varying vec3 v_nobj;
varying vec3 v_col;
varying float v_emit;

void vertex() {
	v_col = COLOR.rgb;
	v_emit = 1.0 - COLOR.a;
	v_nobj = NORMAL;
	v_pos = world_space ? (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz : VERTEX;
	if (wind_amount > 0.0) {
		vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		float w = sin(TIME * 2.2 + wp.x * 0.35 + wp.z * 0.25) * wind_amount * clamp(VERTEX.y * 0.25, 0.0, 1.5);
		VERTEX.x += w;
		VERTEX.z += w * 0.6;
	}
}

void fragment() {
	vec3 n = normalize(v_nobj);
	vec3 w = pow(abs(n), vec3(4.0));
	w /= (w.x + w.y + w.z);
	vec2 ux = v_pos.zy * tex_scale;
	vec2 uy = v_pos.xz * tex_scale;
	vec2 uz = v_pos.xy * tex_scale;
	vec3 t = planar_only ? texture(albedo_tex, uy).rgb : texture(albedo_tex, ux).rgb * w.x + texture(albedo_tex, uy).rgb * w.y + texture(albedo_tex, uz).rgb * w.z;
	float lum = dot(t, vec3(0.299, 0.587, 0.114));
	vec3 graded = mix(vec3(lum), t, tex_sat);
	vec3 from_vc = v_col * clamp(lum / tex_avg_lum, 0.35, 1.7);
	ALBEDO = mix(graded, from_vc, vc_mix);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	if (use_normal && !planar_only) {
		vec3 tx = texture(normal_tex, ux).xyz * 2.0 - 1.0;
		vec3 ty = texture(normal_tex, uy).xyz * 2.0 - 1.0;
		vec3 tz = texture(normal_tex, uz).xyz * 2.0 - 1.0;
		vec3 pert = w.x * vec3(0.0, tx.y, tx.x) + w.y * vec3(ty.x, 0.0, ty.y) + w.z * vec3(tz.x, tz.y, 0.0);
		vec3 no = normalize(n + pert * normal_strength);
		NORMAL = normalize((VIEW_MATRIX * vec4(normalize(MODEL_NORMAL_MATRIX * no), 0.0)).xyz);
	}
	float f = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), rim_power);
	EMISSION = rim_color.rgb * f * rim_amount * v_col + v_col * v_emit * 1.6;
}

void light() {
	float nl = dot(NORMAL, LIGHT);
	float lit = smoothstep(-band_soft, band_soft, nl) * ATTENUATION;
	vec3 shade = mix(shade_color.rgb, vec3(1.0), lit);
	DIFFUSE_LIGHT += LIGHT_COLOR / PI * shade;
}
