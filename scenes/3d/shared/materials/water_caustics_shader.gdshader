shader_type spatial;
render_mode unshaded;

uniform vec3 albedo_color : source_color = vec3(1.0);
uniform sampler2D cellular_movement_noise_texture;
uniform float intensity : hint_range(1.0, 100.0) = 50.0;

uniform float scale : hint_range(0.01, 10.0) = 1.0;
uniform float speed : hint_range(0.0, 1.0) = 0.5;

varying vec3 world_pos;
varying vec3 model_normal;
varying vec2 custom_uv;


float normalize_range(vec2 from, vec2 to, float value){
	float old_range = from.y - from.x;
	float new_range = to.y - to.x;

	float new_val = (((value - from.x) * new_range) / old_range) + to.x;
	return new_val;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz * scale;
	model_normal = normalize((MODEL_NORMAL_MATRIX * NORMAL).xyz);

	custom_uv = world_pos.xz;
	custom_uv.x += (TIME * speed);
	custom_uv.y += (TIME * -speed + 0.1);
}

void fragment() {
	vec4 movement_noise_t = texture(cellular_movement_noise_texture, world_pos.xz);

	vec2 new_uv = custom_uv;
	new_uv.x += movement_noise_t.g;
	new_uv.y -= movement_noise_t.g;

	vec4 cellular_noise_t = texture(cellular_movement_noise_texture, new_uv);

	float color = min(0.999, cellular_noise_t.r);
	color = log(0.9985) / log(color);
	color *= intensity * min((sin(TIME) / 2.0) + 1.1, 1.0);

	ALBEDO = albedo_color;

	float world_y_nrm = normalize_range(
		vec2(-0.75, 1.0),
		vec2(0.0, 1.0),
		model_normal.y
	);
	ALPHA = color * world_y_nrm;
}
