// عملة ذهبية تدور (تُستخدم مع MultiMesh).
shader_type spatial;
render_mode cull_back;
varying vec3 v_col;
void vertex() {
	v_col = COLOR.rgb;
	float a = TIME * 3.2 + float(INSTANCE_ID) * 0.61;
	float c = cos(a);
	float s = sin(a);
	VERTEX = vec3(VERTEX.x * c + VERTEX.z * s, VERTEX.y, -VERTEX.x * s + VERTEX.z * c);
	NORMAL = vec3(NORMAL.x * c + NORMAL.z * s, NORMAL.y, -NORMAL.x * s + NORMAL.z * c);
	VERTEX.y += sin(TIME * 2.4 + float(INSTANCE_ID)) * 0.07;
}
void fragment() {
	ALBEDO = v_col;
	METALLIC = 0.0;
	ROUGHNESS = 0.6;
	EMISSION = v_col * 0.55;
}
void light() {
	float nl = max(dot(NORMAL, LIGHT), 0.0);
	DIFFUSE_LIGHT += LIGHT_COLOR / PI * mix(0.55, 1.0, step(0.25, nl) * ATTENUATION);
}
