shader_type spatial;
//render_mode unshaded;

uniform float time_scale : hint_range(0.0, 10.0) = 1.0;
uniform float time_scale_2 : hint_range(0.0, 10.0) = 1.0;
uniform float yaw : hint_range(0.0, 100.0) = 0.01;
uniform float roll : hint_range(0.0, 100.0) = 0.01;
uniform float scale : hint_range(0.0, 100.0) = 0.01;
uniform float fish_length = 1.0;
uniform float mask_black : hint_range(0.0, 1.0) = 0.0;
uniform float mask_white : hint_range(0.0, 1.0) = 1.0;


void vertex() {
	float time = (TIME * (0.5 + INSTANCE_CUSTOM.y) * time_scale) + (6.28318 * INSTANCE_CUSTOM.x);
	
	float body = (VERTEX.y + (fish_length / 2.0)) / fish_length; //for a fish centered at (0, 0) with a length of 2
	float mask = smoothstep(mask_black, mask_white, body);
	
	vec3 vertex_pos = VERTEX;
	vertex_pos += (
		sin(
			(time + (vertex_pos.y * yaw) + (vertex_pos.z * roll))
		) * scale * mask
	) * vec3(1, 0, 0);
	
	//float time = ((TIME * 1.5) * time_scale) + 6.28318;
	
	
	VERTEX = vertex_pos;
	
	VERTEX.x += sin(time) * time_scale_2;
	VERTEX.y += cos(time) * time_scale_2;
	VERTEX.z -= sin(time) * 2.0 * time_scale_2;
	
	COLOR = vec4(mask, mask, mask, 1.0);
}

void fragment() {
	ALBEDO = COLOR.rgb;
}
