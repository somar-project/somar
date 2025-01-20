shader_type spatial;
render_mode depth_prepass_alpha;

uniform vec3 albedo_color : source_color = vec3(1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;

uniform float alpha_scissor_threshold : hint_range(0.0, 1.0) = 0.5;
uniform float specular : hint_range(0.0, 1.0) = 0.5;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float roughness : hint_range(0.0, 1.0) = 1.0;


void fragment() {
	vec4 albedo_t = texture(albedo_texture, UV);

	SPECULAR = specular;
	METALLIC = metallic;
	ROUGHNESS = roughness;

	ALBEDO = albedo_color * albedo_t.rgb;
	ALPHA = albedo_t.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_scissor_threshold;
}
