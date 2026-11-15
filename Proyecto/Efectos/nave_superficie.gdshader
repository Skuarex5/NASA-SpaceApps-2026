shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform sampler2D color_base : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D metal : hint_default_white, filter_linear_mipmap_anisotropic;
uniform sampler2D rugosidad : hint_default_white, filter_linear_mipmap_anisotropic;
uniform sampler2D normales : hint_normal, filter_linear_mipmap_anisotropic;
uniform sampler2D oclusion : hint_default_white, filter_linear_mipmap_anisotropic;
uniform sampler2D luces : source_color, filter_linear_mipmap_anisotropic;
uniform float intensidad_relieve : hint_range(0.0, 2.0) = 0.8;
uniform float intensidad_emision : hint_range(0.0, 5.0) = 1.8;
uniform float microdesgaste : hint_range(0.0, 0.3) = 0.08;

varying vec3 posicion_local;

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
	posicion_local = VERTEX;
}

void fragment() {
	float desgaste = ruido(posicion_local * 0.8);
	float grano = ruido(posicion_local * 48.0);
	ALBEDO = texture(color_base, UV).rgb * (1.0 - microdesgaste * (1.0 - desgaste));
	METALLIC = texture(metal, UV).r;
	ROUGHNESS = clamp(texture(rugosidad, UV).r * 0.9 + 0.12 + grano * microdesgaste, 0.18, 0.95);
	SPECULAR = 0.55;
	NORMAL_MAP = texture(normales, UV).rgb;
	NORMAL_MAP_DEPTH = intensidad_relieve;
	AO = mix(1.0, texture(oclusion, UV).r, 0.85);
	AO_LIGHT_AFFECT = 0.1;
	EMISSION = texture(luces, UV).rgb * intensidad_emision;
}
