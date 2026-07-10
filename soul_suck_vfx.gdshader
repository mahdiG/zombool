shader_type canvas_item;

// Screen and noise texture inputs
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D noise_texture : repeat_enable;

// Array containing the live intensity levels for all 8 slices (passed from GDScript)
uniform float directional_intensities[8];

// Configuration parameters
uniform float distortion_radius : hint_range(0.0, 2.0) = 0.6;
uniform float animation_speed = 3.0;

// Wavy energy configuration
uniform vec3 wave_glow_color : source_color = vec3(1.0, 1.0, 1.0); // Now controllable via inspector
uniform float wave_coordinate_scale = 4.0; // Reduced density for subtlety

const vec2 DIRECTIONAL_ANCHORS[8] = vec2[](
    vec2(1.0, 0.5), vec2(1.0, 1.0), vec2(0.5, 1.0), vec2(0.0, 1.0), 
    vec2(0.0, 0.5), vec2(0.0, 0.0), vec2(0.5, 0.0), vec2(1.0, 0.0)
);

vec2 calculate_sector_warp(vec2 current_uv, vec2 anchor_uv, float intensity, float noise_val) {
    if (intensity <= 0.001) return vec2(0.0);

    vec2 vector_to_anchor = anchor_uv - current_uv;
    float distance_to_anchor = length(vector_to_anchor);
    float falloff_weight = smoothstep(distortion_radius, 0.0, distance_to_anchor);
    
    float radial_wave = sin(distance_to_anchor * 12.0 - TIME * animation_speed);
    float distortion_factor = (radial_wave * 0.03) + (noise_val * 0.02);
    
    vec2 pull_direction = normalize(vector_to_anchor);
    return pull_direction * distortion_factor * falloff_weight * intensity;
}

float calculate_sector_tint(vec2 current_uv, vec2 anchor_uv, float intensity) {
    if (intensity <= 0.001) return 0.0;
    float distance_to_anchor = length(anchor_uv - current_uv);
    return smoothstep(distortion_radius, 0.0, distance_to_anchor) * intensity;
}

vec3 calculate_sector_wavy_energy(vec2 current_uv, vec2 anchor_uv, float intensity, float current_time) {
    if (intensity <= 0.001) return vec3(0.0);

    vec2 vector_to_anchor = current_uv - anchor_uv;
    vec2 warped_coordinates = vector_to_anchor * wave_coordinate_scale;

    // Iterative domain warping
    for (int iteration_index = 1; iteration_index < 6; iteration_index++) { // Fewer iterations = smoother
        float iteration_factor = float(iteration_index);
        warped_coordinates.x += 0.6 / iteration_factor * cos(iteration_factor * 2.5 * warped_coordinates.y + current_time);
        warped_coordinates.y += 0.6 / iteration_factor * cos(iteration_factor * 1.5 * warped_coordinates.x + current_time);
    }
    
    float wave_denominator = abs(sin(current_time - warped_coordinates.y - warped_coordinates.x)) + 0.01;
    float glow_intensity = 0.05 / wave_denominator; // Reduced intensity for subtlety
    
    // Circular gradient mask: Keep center clear, show effect at edges
    float distance_from_center = length(current_uv - vec2(0.5));
    float center_mask = smoothstep(0.1, 0.6, distance_from_center);
    
    float falloff_weight = smoothstep(distortion_radius, 0.0, length(anchor_uv - current_uv));
    
    return wave_glow_color * glow_intensity * falloff_weight * center_mask * intensity;
}

void fragment() {
    vec2 moving_noise_uv = UV + vec2(TIME * 0.1, TIME * -0.15);
    float noise_value = texture(noise_texture, moving_noise_uv).r;
    
    vec2 accumulated_displacement = vec2(0.0);
    float accumulated_tint_weight = 0.0;
    vec3 accumulated_wavy_energy = vec3(0.0);
    
    for (int sector_index = 0; sector_index < 8; sector_index++) {
        float current_intensity = directional_intensities[sector_index];
        vec2 target_anchor = DIRECTIONAL_ANCHORS[sector_index];
        
        accumulated_displacement += calculate_sector_warp(SCREEN_UV, target_anchor, current_intensity, noise_value);
        accumulated_tint_weight += calculate_sector_tint(SCREEN_UV, target_anchor, current_intensity);
        accumulated_wavy_energy += calculate_sector_wavy_energy(SCREEN_UV, target_anchor, current_intensity, TIME);
    }
    
    accumulated_tint_weight = clamp(accumulated_tint_weight, 0.0, 1.0);
    
    vec3 warped_screen_color = texture(screen_texture, SCREEN_UV + accumulated_displacement).rgb;
    
    // Changed to neutral gray to maintain monochrome look
    vec3 neutral_tint = vec3(0.1); 
    vec3 base_composition = mix(warped_screen_color, neutral_tint, accumulated_tint_weight * 0.65);
    
    COLOR = vec4(base_composition + accumulated_wavy_energy, 1.0);
}