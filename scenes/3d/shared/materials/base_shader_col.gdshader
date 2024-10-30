shader_type spatial;

uniform vec3 albedo_color : source_color = vec3(1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;


void fragment() {
	vec4 albedo_t = texture(albedo_texture, UV);
	
	ALBEDO = albedo_color * albedo_t.rgb;
}
