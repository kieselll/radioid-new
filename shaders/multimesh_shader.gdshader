shader_type canvas_item;
render_mode blend_mix, unshaded;

varying vec4 region;
uniform vec4 selection_color : source_color;

void vertex() {
    region = INSTANCE_CUSTOM;
}

void fragment() {
    vec2 uv = region.xy + UV * region.zw;
    vec4 tex = texture(TEXTURE, uv);

    tex *= vec4(1.35,1.35,1.35,0.5) * selection_color;

    COLOR = tex;
}
