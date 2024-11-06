shader_type spatial;
render_mode unshaded, blend_add;

uniform vec4 albedo_color : source_color = vec4(1.0);
uniform sampler2D water_layer_0;
uniform float opacity : hint_range(0.0, 1.0, 0.05) = 0.5;
uniform float scale : hint_range(0.0, 10.0, 0.01) = 0.8;
uniform float speed : hint_range(0.0, 2.0) = 1.0;

varying vec2 scaled_uv_0;
varying vec2 scaled_uv_1;


float avg(vec4 color) {
    return (color.r + color.g + color.b)/3.0;
}

void vertex() {
	vec2 scaled_uv = UV * scale;
	scaled_uv_0 = scaled_uv + TIME * 0.02 * speed - 0.1;
	scaled_uv_1 = scaled_uv + TIME * speed * vec2(-0.02, -0.02) + 0.1;
}

void fragment() {
    // Water layers, layered on top of eachother to produce the reflective effect
    // Add 0.1 to both uv vectors to avoid the layers stacking perfectly and creating a huge unnatural highlight
    vec4 water1 = texture(water_layer_0, scaled_uv_0);
    vec4 water2 = texture(water_layer_0, scaled_uv_1);
	
	vec4 water_mask = texture(water_layer_0, UV);
    
    // Average the colors of the water layers (convert from 1 channel to 4 channel
    water1.rgb = vec3(avg(water1));
    water2.rgb = vec3(avg(water2));

    // Output to screen
    vec4 final_color = (water1 + water2) * albedo_color;
	
	ALBEDO = final_color.rgb;
	ALPHA = opacity * water_mask.a;
}