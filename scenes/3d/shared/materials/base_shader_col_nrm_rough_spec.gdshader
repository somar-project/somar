shader_type spatial;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_texture;
uniform sampler2D roughness_specular_texture;

uniform float normal_map_scale : hint_range(-2.0, 2.0) = 1.0;
uniform float roughness_cale : hint_range(-2.0, 2.0) = 1.0;
uniform float specular_scale : hint_range(-2.0, 2.0) = 1.0;


void fragment() {
	vec4 albedo_t = texture(albedo_texture, UV);
	vec4 normal_t = texture(normal_texture, UV);
	vec4 roughness_specular_t = texture(roughness_specular_texture, UV);

	ALBEDO = albedo_t.rgb;
	NORMAL_MAP = normal_t.rgb;
	ROUGHNESS = roughness_specular_t.r * roughness_cale;
	SPECULAR = roughness_specular_t.g * specular_scale;
	NORMAL_MAP_DEPTH = normal_map_scale;
}
