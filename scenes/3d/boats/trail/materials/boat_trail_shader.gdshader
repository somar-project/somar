shader_type spatial;
render_mode cull_front, unshaded, blend_add;

uniform vec3 albedo_color : source_color = vec3(1.0);
uniform sampler2D trail_texture : repeat_enable;
uniform sampler2D noise_texture;
uniform float speed : hint_range(0.0, 1.0) = 0.5;
uniform float opacity : hint_range(0.0, 1.0) = 1.0;


void vertex() {
	vec2 new_uv = UV;
	new_uv.x += TIME * speed * 0.2;
	vec4 noise_t = texture(noise_texture, new_uv);
	
	VERTEX.y += noise_t.r / 2.0;
}

void fragment() {
	vec2 new_uv = UV;
	new_uv.x -= TIME * speed;
	
	vec4 trail_t = texture(trail_texture, new_uv);
	vec4 trail_t_a = texture(trail_texture, UV);
	
	FOG.a = 0.8;
	ALBEDO = vec3((trail_t_a.a - (1.0 - trail_t.g)) * COLOR.r * opacity) * albedo_color;
}
