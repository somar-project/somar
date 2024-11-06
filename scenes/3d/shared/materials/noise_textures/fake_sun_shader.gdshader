shader_type spatial;
render_mode unshaded, blend_add;

uniform vec3 albedo_color : source_color;
uniform sampler2D fake_sun_texture;


void fragment() {
	vec4 fake_sun_t = texture(fake_sun_texture, UV);
	ALBEDO = fake_sun_t.rgb * albedo_color;
	FOG.a = 0.0;
}
