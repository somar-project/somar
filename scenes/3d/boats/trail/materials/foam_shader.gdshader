shader_type spatial;
render_mode unshaded, blend_add;

uniform vec3 albedo_color : source_color = vec3(1.0);
uniform sampler2D trail_texture : repeat_enable;
uniform float speed : hint_range(0.0, 1.0) = 0.5;
uniform float opacity : hint_range(0.0, 1.0) = 1.0;


void fragment() {
	vec2 new_uv = UV;
	new_uv += TIME * speed;

	vec4 trail_t = texture(trail_texture, new_uv);

	FOG.a = 0.8;
	ALBEDO = vec3(COLOR.r * opacity) * albedo_color * trail_t.r;
}
