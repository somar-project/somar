shader_type spatial;
render_mode unshaded, blend_add;

uniform sampler2D particles_texture : source_color, filter_linear_mipmap, repeat_disable;
uniform float opacity : hint_range(0.0, 1.0, 0.01) = 1.0;


void vertex() {
	// Billboard
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			MAIN_CAM_INV_VIEW_MATRIX[0],
			MAIN_CAM_INV_VIEW_MATRIX[1],
			MAIN_CAM_INV_VIEW_MATRIX[2],
			MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec4 particles_t = texture(particles_texture, UV);
	
	ALBEDO = particles_t.rgb * opacity;
	FOG.a = 0.9;
}
