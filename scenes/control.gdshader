shader_type canvas_item;

uniform float shadow_angle : hint_range(0.0, 360.0) = 135.0;
uniform float shadow_length : hint_range(0.0, 100.0) = 10.0;
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.4);

void fragment() {
	vec2 offset = vec2(cos(radians(shadow_angle)), sin(radians(shadow_angle)))
	              * (shadow_length / TEXTURE_PIXEL_SIZE.y);

	vec4 source_pixel = texture(TEXTURE, UV - offset); // <- тут проверяем источник тени
	vec4 this_pixel = texture(TEXTURE, UV);            // <- а тут обычный спрайт

	// если здесь прозрачный пиксель, но по направлению "против света" — непрозрачный, рисуем тень
	bool draw_shadow = this_pixel.a == 0.0 && source_pixel.a > 0.0;

	if (draw_shadow) {
		COLOR = vec4(shadow_color.rgb, source_pixel.a * shadow_color.a);
	} else {
		COLOR = this_pixel;
	}
}
