shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

varying vec3 posicion_roca;

float ruido(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	vec4 n = vec4(dot(i, vec3(1.0, 57.0, 113.0))) + vec4(0.0, 1.0, 57.0, 58.0);
	vec4 a = fract(sin(n) * 43758.5453);
	vec4 b = fract(sin(n + 113.0) * 43758.5453);
	vec4 c = mix(a, b, f.z);
	return mix(mix(c.x, c.y, f.x), mix(c.z, c.w, f.x), f.y);
}

void vertex() {
	posicion_roca = VERTEX;
}

void fragment() {
	float mineral = ruido(posicion_roca * 5.0);
	float grano = ruido(posicion_roca * 95.0);
	vec3 oscura = vec3(0.12, 0.105, 0.09);
	vec3 clara = vec3(0.34, 0.30, 0.25);
	ALBEDO = mix(oscura, clara, mineral) * mix(0.8, 1.1, grano);
	ROUGHNESS = mix(0.85, 1.0, grano);
	SPECULAR = 0.18;
}
