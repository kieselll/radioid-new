shader_type canvas_item;
render_mode blend_mix, unshaded;

varying vec4 region;

void vertex() {
    region = INSTANCE_CUSTOM;
}

void fragment() {
    vec2 uv = region.xy + UV * region.zw;
    vec4 tex = texture(TEXTURE, uv);

    tex *= vec4(1.2,1.8,2.4,0.5);

    COLOR = tex;
}
