shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;

uniform float potencia : hint_range(0.0, 1.0) = 0.0;
uniform float turbo : hint_range(0.0, 1.0) = 0.0;
uniform bool envoltura = false;

float ruido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	vec4 n = vec4(dot(i, vec2(127.1, 311.7))) + vec4(0.0, 127.1, 311.7, 438.8);
	vec4 r = fract(sin(n) * 43758.5453);
	return mix(mix(r.x, r.y, f.x), mix(r.z, r.w, f.x), f.y);
}

void vertex() {
	float ondulacion = sin(UV.y * 35.0 - TIME * 24.0 + UV.x * 6.28318);
	VERTEX.xy *= 1.0 + ondulacion * 0.045 * UV.y * potencia;
}

void fragment() {
	float t = clamp(UV.y, 0.0, 0.9999);
	float flujo = ruido(UV * vec2(9.0, 18.0) - vec2(0.0, TIME * (7.0 + turbo * 4.0)));
	float onda = clamp(0.5 + 0.5 * sin(t * 48.0 - TIME * 4.0), 0.0, 1.0);
	float bandas = onda * onda * onda * onda * onda;
	float densidad = pow(max(1.0 - t, 0.0001), 1.15) * (0.4 + 0.6 * flujo) * (0.85 + bandas * 0.3);
	vec3 color = mix(vec3(0.8, 0.92, 1.0), vec3(0.06, 0.28, 1.0), smoothstep(0.0, 0.75, t));
	if (envoltura) {
		color = mix(vec3(0.18, 0.52, 1.0), vec3(0.3, 0.12, 0.65), t);
		densidad *= 0.32;
	}
	ALBEDO = color * (2.5 + turbo * 1.5) * densidad;
	EMISSION = ALBEDO;
	ALPHA = clamp(densidad * potencia * (0.65 + turbo * 0.2), 0.0, 0.85);
}
