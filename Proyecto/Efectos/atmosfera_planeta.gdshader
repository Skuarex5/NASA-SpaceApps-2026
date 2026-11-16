shader_type spatial;
render_mode unshaded, blend_add, cull_back, depth_draw_never;

uniform vec3 color_atmosfera : source_color = vec3(0.2, 0.5, 0.8);

void fragment() {
	float borde = pow(1.0 - max(dot(normalize(NORMAL), normalize(VIEW)), 0.0), 3.0);
	ALBEDO = color_atmosfera * 0.7;
	ALPHA = borde * 0.32;
}
