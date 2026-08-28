shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float lod : hint_range(0.0, 5) = 0.0;

void fragment() {
    vec4 color = texture(SCREEN_TEXTURE, SCREEN_UV, lod);
    vec4 sprite_color = texture(TEXTURE, UV);
    COLOR = vec4(1.0 - color.rgb, sprite_color.a);
}
