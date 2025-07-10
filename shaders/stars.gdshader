shader_type canvas_item;

uniform vec2 resolution = vec2(400,400);
uniform sampler2D noise_texture : filter_linear, repeat_enable;
uniform float density = 20.0;

void fragment() {
	vec2 uv = UV;
	vec2 speed = vec2(2.0,sin(TIME*0.05)*0.1);
	uv.x *= resolution.x / resolution.y;
	vec2 displacement = (TIME * speed) * 0.01;
	float stars = 0.0;
	stars += step(0.1,pow(texture(noise_texture, uv + displacement).r, density));
	COLOR = vec4(vec3(stars), 1.0);
}
