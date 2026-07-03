shader_type spatial;
render_mode unshaded;

// --- Uniforms exposed to Godot Inspector ---
group_uniforms DisplacementSettings;
uniform sampler2D noise_texture : hint_default_white, repeat_enable;
uniform float displacement_strength : hint_range(0.0, 2.0) = 0.3;
uniform float animation_speed : hint_range(0.0, 5.0) = 1.5;

group_uniforms ColorSettings;
uniform vec4 flame_core_color : source_color = vec4(1.0, 0.9, 0.5, 1.0); // Brightest center
uniform vec4 flame_inner_color : source_color = vec4(1.0, 0.4, 0.0, 1.0); // Main fire body
uniform vec4 flame_outer_color : source_color = vec4(0.9, 0.1, 0.0, 1.0); // Darker edge rim
uniform float glow_intensity : hint_range(1.0, 5.0) = 2.0;

group_uniforms ToonThresholds;
uniform float inner_fire_threshold : hint_range(0.0, 1.0) = 0.35;
uniform float outer_rim_threshold : hint_range(0.0, 1.0) = 0.70;

void vertex() {
	// Generate shifting UV coordinates over time to move the noise texture
	vec2 moving_uv = UV;
	moving_uv.y -= TIME * animation_speed; // Pan upward like real smoke/fire
	moving_uv.x += sin(TIME * 0.5) * 0.1;  // Add a slight horizontal sway
	
	// Fetch the noise value (using the red channel as a scalar)
	float noise_value = texture(noise_texture, moving_uv).r;
	
	// Push the vertices outward along their normal vectors based on the noise
	// Subtracting 0.5 centers the displacement so the orb doesn't just expand
	float final_displacement = (noise_value - 0.5) * displacement_strength;
	VERTEX += NORMAL * final_displacement;
}

void fragment() {
	// Base Fresnel calculation (0.0 at the center facing the camera, 1.0 at the grazing edges)
	float fresnel_dot = 1.0 - dot(NORMAL, VIEW);
	
	// Default fallback color is the bright core center
	vec3 final_color = flame_core_color.rgb;
	
	// If the fresnel value passes the first threshold, snap completely to the inner fire color
	float pass_inner = step(inner_fire_threshold, fresnel_dot);
	final_color = mix(final_color, flame_inner_color.rgb, pass_inner);
	
	// If the fresnel value passes the outer threshold, snap completely to the dark outer rim
	float pass_outer = step(outer_rim_threshold, fresnel_dot);
	final_color = mix(final_color, flame_outer_color.rgb, pass_outer);
	
	// Output crisp, un-shaded color values to keep the 2D illustration style intact
	EMISSION = final_color * glow_intensity;
	ALBEDO = final_color;
}