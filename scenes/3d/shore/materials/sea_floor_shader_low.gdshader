shader_type spatial;

uniform vec4 albedo : source_color;
uniform vec4 border_color : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_mask;

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

	vec3 alb = albedo.rgb * albedo_tex.rgb;

	ALBEDO = mix(alb, border_color.rgb, mask_tex.rgb);

	METALLIC = metallic;
	SPECULAR = specular;
	ROUGHNESS = roughness;
}
