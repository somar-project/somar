shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D logo : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D logo_back : source_color, filter_linear_mipmap, repeat_disable;

varying vec2 back_uv;


void vertex() {
	back_uv = (UV * vec2(-1.0, 1.0)) + vec2(1.0, 0.0);
}

void fragment() {
	vec4 logo_t = texture(logo, UV);
	vec4 logo_back_t = texture(logo_back, back_uv);

	if (FRONT_FACING) {
		ALBEDO = logo_t.rgb;
		ALPHA = logo_t.a;
	} else {
		ALBEDO = logo_back_t.rgb;
		ALPHA = logo_back_t.a;
	}
}
