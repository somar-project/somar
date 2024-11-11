shader_type spatial;
render_mode unshaded;

uniform sampler2D albedo_texture : source_color;
uniform vec3 fresnel_color : source_color = vec3(1.0);
uniform float fresnel_amount = 4.0;
uniform float fresnel_intensity = 4.0;


vec3 fresnel_glow(float amount, float intensity, vec3 color, vec3 normal, vec3 view)
{
	return pow((1.0 - dot(normalize(normal), normalize(view))), amount) * color * intensity;
}

void fragment() {
	vec4 albedo_t = texture(albedo_texture, UV);
	vec3 basic_fresnel = fresnel_glow(fresnel_amount, fresnel_intensity, fresnel_color, NORMAL, VIEW);
	ALBEDO = albedo_t.rgb + basic_fresnel;
	//ALBEDO = albedo_t.rgb;
}