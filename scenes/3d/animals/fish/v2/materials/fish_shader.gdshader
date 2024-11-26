shader_type spatial;
render_mode shadows_disabled;

uniform vec3 albedo_color : source_color = vec3(1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;

uniform float specular : hint_range(0.0, 1.0) = 0.5;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float roughness : hint_range(0.0, 1.0) = 1.0;

uniform float time_scale : hint_range(0.0, 10.0) = 1.0;
uniform float time_scale_2 : hint_range(0.0, 10.0) = 1.0;
uniform float yaw : hint_range(0.0, 100.0) = 0.01;
uniform float roll : hint_range(0.0, 100.0) = 0.01;
uniform float scale : hint_range(0.0, 100.0) = 0.01;
uniform float fish_length = 1.0;
uniform float mask_black : hint_range(0.0, 1.0) = 0.0;
uniform float mask_white : hint_range(0.0, 1.0) = 1.0;
uniform float height_scale : hint_range(0.0, 2.0) = 1.0;
uniform float width_scale : hint_range(0.0, 2.0) = 1.0;
uniform float rotation : hint_range(0.0, 1.0) = 0.0;

vec3 rotate_vector_around_pivot(vec3 point, vec3 pivot, float rotation_rad) {
	float cos_theta = cos(rotation_rad);
	float sin_theta = sin(rotation_rad);

	float x = (cos_theta * (point.x - pivot.x) - sin_theta * (point.z - pivot.z) + pivot.x);
	float z = (sin_theta * (point.x - pivot.x) + cos_theta * (point.z - pivot.z) + pivot.z);

	return vec3(x, point.y, z);
}

void vertex() {
	float time = (TIME * (0.5 + INSTANCE_CUSTOM.w) * time_scale) + (6.28318 * INSTANCE_CUSTOM.w);
	
	float body = (VERTEX.z + (fish_length / 2.0)) / fish_length;
	float mask = smoothstep(mask_black, mask_white, 1.0 - body);
	
	VERTEX += (
		sin(
			(time + (VERTEX.z * roll) + (VERTEX.y * yaw))
		) * scale * mask
	) * vec3(1, 0, 0);
	
	float time_scale_2_mod = INSTANCE_CUSTOM.w * time_scale_2;
	VERTEX.x += sin(time) * time_scale_2_mod;
	VERTEX.y += cos(time) * time_scale_2_mod;
	VERTEX.z -= sin(time) * time_scale_2_mod;
	
	VERTEX.x += INSTANCE_CUSTOM.x * width_scale;
	VERTEX.y += INSTANCE_CUSTOM.y * height_scale;
	VERTEX = rotate_vector_around_pivot(VERTEX, vec3(0.0), ((2.0*PI) * rotation) + INSTANCE_CUSTOM.z);
}

void fragment() {
	vec4 albedo_t = texture(albedo_texture, UV);
	
	SPECULAR = specular;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	
	ALBEDO = albedo_color * albedo_t.rgb;
}
