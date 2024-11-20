shader_type spatial;
render_mode cull_front, unshaded, blend_add;

uniform vec3 albedo_color : source_color = vec3(1.0);
uniform sampler2D trail_texture : repeat_enable;
uniform sampler2D trail_mask_texture : repeat_disable;
uniform sampler2D visibility_mask : repeat_disable;
uniform sampler2D noise_texture;
uniform float speed : hint_range(0.0, 1.0) = 0.5;
uniform float opacity : hint_range(0.0, 2.0) = 1.0;
uniform float mask_uv_x_offset : hint_range(0.0, 1.0) = 0.0;
uniform vec2 trail_texture_uv_scale = vec2(1.0);

varying vec2 new_uv;
varying vec2 new_mask_uv;


void vertex() {
	vec2 noise_uv = UV;
	noise_uv.x += TIME * speed * 0.2;
	vec4 noise_t = texture(noise_texture, noise_uv);
	
	new_mask_uv = UV;
	new_mask_uv.x += mask_uv_x_offset;
	
	new_uv = UV * trail_texture_uv_scale;
	new_uv.x -= TIME * trail_texture_uv_scale.x * speed;
	
	VERTEX.y += noise_t.r / 2.0;
	//VERTEX.x -= noise_t.r / 4.0;
}

void fragment() {
	vec4 trail_t = texture(trail_texture, new_uv);
	vec4 trail_t_a = texture(trail_mask_texture, UV);
	vec4 visibility_m = texture(visibility_mask, new_mask_uv);
	
	FOG.a = 0.8;
	ALBEDO = vec3((trail_t_a.r - (1.0 - trail_t.g)) * visibility_m.r * opacity) * albedo_color;
}
