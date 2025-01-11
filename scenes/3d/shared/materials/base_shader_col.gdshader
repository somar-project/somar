shader_type spatial;

uniform vec3 albedo_color : source_color = vec3(1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;

uniform float specular : hint_range(0.0, 1.0) = 0.5;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float roughness : hint_range(0.0, 1.0) = 1.0;


void fragment() {
	vec4 albedo_t = texture(albedo_texture, UV);

	SPECULAR = specular;
	METALLIC = metallic;
	ROUGHNESS = roughness;

	ALBEDO = albedo_color * albedo_t.rgb;
}
