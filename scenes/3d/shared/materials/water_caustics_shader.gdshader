shader_type spatial;
render_mode unshaded;

uniform sampler2D cellular_noise_texture;
uniform sampler2D movement_noise;
uniform float intensity : hint_range(1.0, 100.0) = 50.0;

uniform float scale : hint_range(0.01, 10.0) = 1.0;
uniform float speed : hint_range(0.0, 1.0) = 0.5;

varying vec3 world_pos;
varying vec2 custom_uv;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz * scale;
	
	custom_uv = world_pos.xz;
	custom_uv.x += (TIME * speed);
	custom_uv.y += (TIME * -speed + 0.1);
}

void fragment() {
	vec4 movement_noise_t = texture(movement_noise, world_pos.xz);
	
	vec2 new_uv = custom_uv;
	new_uv.x += movement_noise_t.r;
	new_uv.y -= movement_noise_t.r;
	
	vec4 cellular_noise_t = texture(cellular_noise_texture, new_uv);
	
	float color = min(0.999, cellular_noise_t.r);
	color = log(0.999) / log(color);
	color *= intensity * min((sin(TIME) / 2.0) + 1.1, 1.0);
	
	ALBEDO = cellular_noise_t.rgb;
	ALPHA = color;
}
