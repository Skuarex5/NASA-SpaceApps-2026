shader_type spatial;

uniform vec3 color_oscuro : source_color = vec3(0.14, 0.14, 0.15);
uniform vec3 color_claro : source_color = vec3(0.42, 0.41, 0.39);
uniform float escala_grano = 9.0;
varying vec3 punto_local;

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
	punto_local = VERTEX;
}

void fragment() {
	float manchas = ruido(punto_local * 0.13);
	float grano = ruido(punto_local * escala_grano);
	ALBEDO = mix(color_oscuro, color_claro, manchas) * mix(0.8, 1.12, grano);
	ROUGHNESS = 0.92;
	SPECULAR = 0.16;
}
