shader_type spatial;

render_mode cull_front, unshaded;
uniform vec3 outline_color : source_color = vec3(0.26, 0.34, 0.40);
uniform float outline_width : hint_range(0.0, 2.5, 0.01) = 1.6;

varying vec3 vertex_pos;

void vertex() {
	VERTEX += NORMAL * (0.001 * outline_width);
	vertex_pos = VERTEX;
}

void fragment() {
	ALBEDO = outline_color;
}
