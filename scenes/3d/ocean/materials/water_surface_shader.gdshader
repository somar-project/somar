shader_type spatial;
render_mode unshaded, blend_add;

uniform vec4 albedo_color : source_color = vec4(1.0);
uniform sampler2D water_layer_0;
uniform sampler2D water_surface_mask;
uniform float opacity : hint_range(0.0, 1.0, 0.05) = 0.5;
uniform float scale : hint_range(0.0, 2.0, 0.01) = 0.8;


float avg(vec4 color) {
    return (color.r + color.g + color.b)/3.0;
}

void fragment() {
    // Flow Speed, increase to make the water flow faster.
    float speed = 1.0;
    
    // Normalized pixel coordinates (from 0 to 1)
    vec2 scaledUv = UV * scale;

    // Water layers, layered on top of eachother to produce the reflective effect
    // Add 0.1 to both uv vectors to avoid the layers stacking perfectly and creating a huge unnatural highlight
    vec4 water1 = texture(water_layer_0, scaledUv + TIME * 0.02 * speed - 0.1);
    vec4 water2 = texture(water_layer_0, scaledUv.xy + TIME * speed * vec2(-0.02, -0.02) + 0.1);
	
	vec4 water_mask = texture(water_surface_mask, UV);
    
    // Average the colors of the water layers (convert from 1 channel to 4 channel
    water1.rgb = vec3(avg(water1));
    water2.rgb = vec3(avg(water2));

    // Output to screen
    vec4 final_color = (water1 + water2) * albedo_color;
	
	ALBEDO = final_color.rgb;
	ALPHA = opacity * water_mask.r;
}