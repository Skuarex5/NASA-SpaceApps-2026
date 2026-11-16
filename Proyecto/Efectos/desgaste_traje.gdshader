shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, diffuse_burley, specular_schlick_ggx;

uniform float suciedad : hint_range(0.0, 1.0) = 0.85;
uniform float desgaste : hint_range(0.0, 1.0) = 0.35;
uniform vec4 color_polvo : source_color = vec4(0.34, 0.28, 0.20, 1.0);
uniform vec4 color_roce : source_color = vec4(0.52, 0.50, 0.44, 1.0);
// VERTEX ya incluye la escala del esqueleto cuando llega al shader.
uniform float escala_modelo = 1.0;
varying vec3 punto_traje;
varying vec3 normal_traje;

float ruido(vec3 p) {
	vec3 celda = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	vec4 n = vec4(dot(celda, vec3(1.0, 57.0, 113.0))) + vec4(0.0, 1.0, 57.0, 58.0);
	vec4 valores = mix(fract(sin(n) * 43758.5453), fract(sin(n + 113.0) * 43758.5453), f.z);
	return mix(mix(valores.x, valores.y, f.x), mix(valores.z, valores.w, f.x), f.y);
}

void vertex() {
	punto_traje = VERTEX * escala_modelo;
	normal_traje = NORMAL;
	// Separacion minima del acabado para evitar parpadeo con la superficie base.
	VERTEX += NORMAL * (0.00015 / escala_modelo);
}

void fragment() {
	vec3 p = punto_traje + vec3(2.3, 0.0, 4.7);
	float manchas = ruido(p * 11.0) * 0.65 + ruido(p * 29.0) * 0.25 + ruido(p * 73.0) * 0.1;
	float polvo = smoothstep(0.34, 0.70, manchas);
	float botas = 1.0 - smoothstep(0.05, 0.30, punto_traje.y);
	float recovecos = smoothstep(0.1, 0.8, -normal_traje.y);
	float deposito = clamp(polvo * 0.90 + botas * 0.26 + recovecos * 0.12, 0.0, 1.0);
	float rayas = smoothstep(0.73, 0.88, ruido(p * vec3(210.0, 17.0, 150.0)));
	rayas *= smoothstep(0.40, 0.65, ruido(p * 22.0));
	float rozaduras = smoothstep(0.67, 0.85, ruido(p * 94.0)) * smoothstep(0.43, 0.70, manchas);
	float abrasion = clamp((rayas * 0.9 + rozaduras * 0.7) * desgaste, 0.0, 1.0);
	float opacidad_polvo = deposito * suciedad;
	float grano = ruido(p * 260.0);
	ALBEDO = mix(color_polvo.rgb * mix(0.65, 1.15, grano), color_roce.rgb, abrasion / max(opacidad_polvo + abrasion, 0.001));
	ROUGHNESS = mix(0.97, 0.65, abrasion);
	SPECULAR = 0.22;
	ALPHA = clamp(opacidad_polvo + abrasion, 0.0, 0.94);
}
