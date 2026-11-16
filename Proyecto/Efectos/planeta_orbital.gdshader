shader_type spatial;

uniform vec3 color_oscuro : source_color = vec3(0.1, 0.2, 0.3);
uniform vec3 color_claro : source_color = vec3(0.4, 0.6, 0.7);
uniform vec3 color_nubes : source_color = vec3(0.8);
uniform float semilla = 1.0;
uniform float cobertura : hint_range(0.0, 1.0) = 0.35;
uniform float brillo = 0.0;
varying vec3 posicion;

float ruido(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float n = dot(i, vec3(1.0, 57.0, 113.0));
	vec4 a = fract(sin(n + vec4(0.0, 1.0, 57.0, 58.0)) * 43758.5453);
	vec4 b = fract(sin(n + 113.0 + vec4(0.0, 1.0, 57.0, 58.0)) * 43758.5453);
	vec4 c = mix(a, b, f.z);
	return mix(mix(c.x, c.y, f.x), mix(c.z, c.w, f.x), f.y);
}

float relieve(vec3 p) {
	return ruido(p) * 0.55 + ruido(p * 2.1) * 0.27 + ruido(p * 4.3) * 0.12 + ruido(p * 9.0) * 0.06;
}

void vertex() { posicion = normalize(VERTEX); }

void fragment() {
	vec3 p = normalize(posicion);
	float terreno = relieve(p * 4.0 + semilla);
	float detalle = ruido(p * 85.0 + semilla);
	vec3 superficie = mix(color_oscuro, color_claro, smoothstep(0.3, 0.72, terreno));
	superficie *= mix(0.86, 1.12, detalle);
	vec3 viento = vec3(TIME * 0.002, 0.0, TIME * 0.001);
	float nubes = smoothstep(1.0 - cobertura, 1.1 - cobertura, relieve(p * 7.0 + viento + semilla * 3.0));
	ALBEDO = mix(superficie, color_nubes, nubes * 0.8);
	ROUGHNESS = 0.78;
	SPECULAR = 0.3;
	EMISSION = color_claro * smoothstep(0.72, 0.9, terreno) * brillo;
}
