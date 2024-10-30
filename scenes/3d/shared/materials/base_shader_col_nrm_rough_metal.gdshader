shader_type spatial;

uniform vec3 albedo_color : source_color = vec3(1.0);

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_texture;
uniform sampler2D roughness_metalness_texture;

uniform float normal_map_scale : hint_range(-2.0, 2.0) = 1.0;
uniform float roughness_cale : hint_range(-2.0, 2.0) = 1.0;
uniform float metalness_scale : hint_range(-2.0, 2.0) = 1.0;
uniform float specular_scale : hint_range(-2.0, 2.0) = 1.0;


void fragment() {
	vec4 albedo_t = texture(albedo_texture, UV);
	vec4 normal_t = texture(normal_texture, UV);
	vec4 roughness_metalness_t = texture(roughness_metalness_texture, UV);

	ALBEDO = albedo_color * albedo_t.rgb;
	NORMAL_MAP = normal_t.rgb;
	ROUGHNESS = roughness_metalness_t.r * roughness_cale;
	METALLIC = roughness_metalness_t.g * metalness_scale;
	SPECULAR = specular_scale;
	NORMAL_MAP_DEPTH = normal_map_scale;
}
