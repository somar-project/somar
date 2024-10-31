shader_type spatial;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_mask;
uniform sampler2D shadow_map;

uniform float shadow_min_opacity : hint_range(0.0, 1.0) = 0.5;

uniform float roughness : hint_range(0.0, 1.0);
uniform float specular : hint_range(0.0, 1.0, 0.01);
uniform float metallic : hint_range(0.0, 1.0, 0.01);

uniform vec3 uv1_scale = vec3(1.0);
uniform vec3 uv1_offset = vec3(0.0);

void vertex() {
	UV = UV * uv1_scale.xy + uv1_offset.xy;
}

void fragment() {
	vec2 base_uv = UV;

	vec4 albedo_tex = texture(texture_albedo, base_uv);
	vec4 mask_tex = texture(texture_mask, UV2);
	
	float shadow_map_value = clamp(texture(shadow_map, UV2).r, shadow_min_opacity, 1.0);
	
	ALBEDO = albedo.rgb * albedo_tex.rgb * shadow_map_value;

	METALLIC = metallic;
	SPECULAR = specular;
	ROUGHNESS = roughness;
	
	ALPHA = mask_tex.r;
}
