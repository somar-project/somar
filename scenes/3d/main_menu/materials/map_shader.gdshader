shader_type spatial;
render_mode unshaded;

uniform sampler2D map_texture : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D map_texture_mask;


void fragment() {
	vec4 map_t = texture(map_texture, UV);
	vec4 map_mask_t = texture(map_texture_mask, UV);
	
	ALBEDO = map_t.rgb;
	ALPHA = map_mask_t.r;
}
