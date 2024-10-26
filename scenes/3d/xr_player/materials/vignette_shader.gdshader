shader_type spatial;
render_mode unshaded, skip_vertex_transform, depth_test_disabled, cull_disabled;

uniform float outer_radius : hint_range(0.0, 5.0) = 1.0;
uniform float main_alpha : hint_range(0.0, 1.0) = 1.0;


void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
	POSITION.xy -= EYE_OFFSET.xy * 5.0;
}

void fragment() {
	vec2 xy = 2.0 * vec2(abs(UV.x-0.5), abs(UV.y-0.5));
	float v = ( sqrt( (xy.x * xy.x) + (xy.y * xy.y) ) / outer_radius );
	ALBEDO = vec3(0,0,0);
	ALPHA = v * main_alpha;
}