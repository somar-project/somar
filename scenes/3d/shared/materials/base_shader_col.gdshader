shader_type spatial;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;


void fragment() {
	vec4 albedo_t = texture(albedo_texture, UV);
	
	ALBEDO = albedo_t.rgb;
}
