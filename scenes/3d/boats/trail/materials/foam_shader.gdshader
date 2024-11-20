shader_type spatial;
render_mode unshaded, blend_add;

uniform vec3 albedo_color : source_color = vec3(1.0);
uniform sampler2D trail_texture : repeat_enable;
uniform float speed : hint_range(0.0, 1.0) = 0.5;
uniform float opacity : hint_range(0.0, 1.0) = 1.0;
uniform float uv_scale : hint_range(0.0, 2.0) = 1.0;
uniform float circle_radius :hint_range(0.0, 1.0) = 0.5;

varying vec2 new_uv;
varying vec2 circle_uv;


void vertex() {
	// Billboard
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			MAIN_CAM_INV_VIEW_MATRIX[0],
			MAIN_CAM_INV_VIEW_MATRIX[1],
			MAIN_CAM_INV_VIEW_MATRIX[2],
			MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	
	new_uv = UV * uv_scale;
	new_uv += TIME * speed;
	
	circle_uv = UV + vec2(-0.5);
}

float circle(vec2 position, float radius, float feather)
{
	return smoothstep(radius, radius + feather, dot(position, position) * 4.0);
}

void fragment() {
	vec4 trail_t = texture(trail_texture, new_uv);

	FOG.a = 0.8;
	ALBEDO = (vec3(COLOR.r * opacity) * albedo_color * trail_t.r) * abs(vec3(circle(circle_uv, circle_radius, 0.005)) - 1.0);
}
