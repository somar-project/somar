shader_type spatial;
render_mode unshaded, blend_mix, depth_prepass_alpha;

uniform sampler2D sunrays_texture;
uniform sampler2D sunrays_mask_texture;
uniform float opacity : hint_range(0.0, 1.0) = 1.0;
uniform float speed : hint_range(0.0, 1.0) = 0.5;
uniform float rotation_speed : hint_range(0.0, 1.0) = 0.5;

uniform vec2 uv1_scale = vec2(1.0);
uniform vec2 uv1_offset = vec2(0.0);


void vertex() {
	vec2 uv1_o = uv1_offset.xy;
	uv1_o.x += (TIME * rotation_speed);
	UV = UV * uv1_scale + uv1_o;
}

float avg(vec4 color) {
    return (color.r + color.g + color.b)/3.0;
}

void fragment() {
	//vec2 custom_uv = UV + (TIME * speed);
	//vec4 sunrays_t = texture(sunrays_texture, UV);
	
	
	vec4 sunrays_mask_t = texture(sunrays_mask_texture, UV);
	
	vec4 water1 = texture(sunrays_texture, UV + TIME * 0.02 * speed - 0.1);
	vec4 water2 = texture(sunrays_texture, UV.xy + TIME * speed * vec2(-0.02, -0.02) + 0.1);
	
	// Average the colors of the water layers (convert from 1 channel to 4 channel
	water1.rgb = vec3(avg(water1));
	water2.rgb = vec3(avg(water2));

    // Output to screen
    vec4 final_color = (water1 + water2);
	
	ALBEDO = final_color.rgb;
	ALPHA = opacity * final_color.r * sunrays_mask_t.r;
}
