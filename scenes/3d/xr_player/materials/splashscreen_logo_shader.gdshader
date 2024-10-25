shader_type spatial;
render_mode unshaded;

uniform sampler2D logo : source_color, filter_linear_mipmap, repeat_disable;


void fragment() {
	vec4 logo_t = texture(logo, UV);
	ALBEDO = logo_t.rgb;
	ALPHA = logo_t.a;
}
