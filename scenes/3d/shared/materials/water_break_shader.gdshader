shader_type spatial;
render_mode blend_add, cull_front;

uniform sampler2D albedo_texture;

varying vec2 new_uv;


void vertex() {
	new_uv = UV;
	new_uv.y -= TIME * 2.0;
}

void fragment() {
	vec4 albedo_t = texture(albedo_texture, new_uv);
	ALBEDO = albedo_t.rgb * 10.0;
	FOG.a = 0.9;
}
