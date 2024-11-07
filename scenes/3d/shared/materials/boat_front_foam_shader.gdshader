shader_type spatial;
render_mode blend_add, unshaded;

uniform sampler2D albedo_texture;
uniform float speed : hint_range(0.0, 10.0) = 1.0;
uniform float opacity : hint_range(0.0, 1.0) = 1.0;
global uniform float water_surface_height;

varying vec3 world_vertex;
varying vec2 new_uv;


void vertex() {
	world_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	new_uv = UV;
	new_uv.x -= TIME * speed;
}

void fragment() {
	vec4 albedo_t = texture(albedo_texture, new_uv);
	
	FOG.a = 0.5;
	ALBEDO = albedo_t.rgb * opacity;
	ALPHA = 1.0 * (water_surface_height - world_vertex.y);
	ALPHA_SCISSOR_THRESHOLD = 0.0;
}
