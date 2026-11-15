
shader_type canvas_item;
render_mode unshaded;

uniform sampler2D pantalla : hint_screen_texture, repeat_disable, filter_nearest;

uniform vec2 resolucion = vec2(1024.0, 576.0);
uniform float niveles_color : hint_range(4.0, 64.0, 1.0) = 24.0;
uniform float dithering : hint_range(0.0, 1.0) = 0.35;
uniform float vineta : hint_range(0.0, 1.0) = 0.25;

void fragment() {
    // Pixelado
    vec2 pixel = floor(SCREEN_UV * resolucion);
    vec2 uv = (pixel + 0.5) / resolucion;

    vec3 color = texture(pantalla, uv).rgb;

    // Tramado retro simple de 2x2
    float patron = mod(pixel.x + pixel.y, 2.0) - 0.5;

    // Reduccion de colores y dithering
    color = floor(color * niveles_color + patron * dithering)
            / niveles_color;

    // Oscurecer las esquinas
    vec2 centro = SCREEN_UV * 2.0 - 1.0;
    color *= 1.0 - dot(centro, centro) * vineta * 0.25;

    COLOR = vec4(clamp(color, 0.0, 1.0), 1.0);
}
