shader_type canvas_item;

// Screen and noise texture inputs
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D noise_texture : repeat_enable;

// Array containing the live intensity levels for all 8 fixed slices
uniform float directional_intensities[8];

// Configuration parameters for the visual behavior
uniform float distortion_radius : hint_range(0.0, 2.0) = 0.8;
uniform float animation_speed = 3.0;
uniform float wave_coordinate_scale = 4.0;
uniform vec3 wave_glow_color : source_color = vec3(1.0, 1.0, 1.0);

// Hardcoded clockwise anchors matching your original layout
const vec2 DIRECTIONAL_ANCHORS[8] = vec2[](
    vec2(1.0, 0.5),  // 0: RIGHT
    vec2(1.0, 1.0),  // 1: BOTTOM_RIGHT
    vec2(0.5, 1.0),  // 2: BOTTOM (BACK)
    vec2(0.0, 1.0),  // 3: BOTTOM_LEFT
    vec2(0.0, 0.5),  // 4: LEFT
    vec2(0.0, 0.0),  // 5: TOP_LEFT
    vec2(0.5, 0.0),  // 6: TOP (FRONT)
    vec2(1.0, 0.0)   // 7: TOP_RIGHT
);

float calculate_aspect_ratio(vec2 pixel_size) {
    return pixel_size.y / pixel_size.x;
}

vec2 calculate_sector_warp(vec2 current_uv, vec2 anchor_uv, float intensity, float noise_val, float aspect_ratio) {
    vec2 difference_vector = anchor_uv - current_uv;
    difference_vector.x *= aspect_ratio; // Prevents widescreen distortion stretching
    
    float distance_to_anchor = length(difference_vector);
    float falloff_weight = smoothstep(distortion_radius, 0.0, distance_to_anchor);
    
    float radial_wave = sin(distance_to_anchor * 12.0 - TIME * animation_speed);
    float distortion_factor = (radial_wave * 0.03) + (noise_val * 0.02);
    
    vec2 pull_direction = normalize(anchor_uv - current_uv);
    return pull_direction * distortion_factor * falloff_weight * intensity;
}

float calculate_sector_tint(vec2 current_uv, vec2 anchor_uv, float intensity, float aspect_ratio) {
    vec2 difference_vector = anchor_uv - current_uv;
    difference_vector.x *= aspect_ratio;
    
    return smoothstep(distortion_radius, 0.0, length(difference_vector)) * intensity;
}

vec3 calculate_sector_wavy_energy(vec2 current_uv, vec2 anchor_uv, float intensity, float current_time, float aspect_ratio) {
    vec2 difference_vector = current_uv - anchor_uv;
    vec2 warped_coordinates = difference_vector * wave_coordinate_scale;
    warped_coordinates.x *= aspect_ratio;

    for (int iteration_index = 1; iteration_index < 6; iteration_index++) {
        float iteration_factor = float(iteration_index);
        warped_coordinates.x += 0.6 / iteration_factor * cos(iteration_factor * 2.5 * warped_coordinates.y + current_time);
        warped_coordinates.y += 0.6 / iteration_factor * cos(iteration_factor * 1.5 * warped_coordinates.x + current_time);
    }
    
    float wave_denominator = abs(sin(current_time - warped_coordinates.y - warped_coordinates.x)) + 0.01;
    float glow_intensity = 0.04 / wave_denominator; // Keeps the lines subtle
    
    vec2 aspect_corrected_diff = difference_vector;
    aspect_corrected_diff.x *= aspect_ratio;
    float falloff_weight = smoothstep(distortion_radius, 0.0, length(aspect_corrected_diff));
    
    return wave_glow_color * glow_intensity * falloff_weight * intensity;
}

void fragment() {
    float aspect_ratio = calculate_aspect_ratio(SCREEN_PIXEL_SIZE);
    vec2 moving_noise_uv = UV + vec2(TIME * 0.1, TIME * -0.15);
    float noise_value = texture(noise_texture, moving_noise_uv).r;
    
    vec2 accumulated_displacement = vec2(0.0);
    float accumulated_tint_weight = 0.0;
    vec3 accumulated_wavy_energy = vec3(0.0);
    
    for (int sector_index = 0; sector_index < 8; sector_index++) {
        float current_intensity = directional_intensities[sector_index];
        
        if (current_intensity <= 0.001) {
            continue;
        }
        
        vec2 target_anchor = DIRECTIONAL_ANCHORS[sector_index];
        
        accumulated_displacement += calculate_sector_warp(SCREEN_UV, target_anchor, current_intensity, noise_value, aspect_ratio);
        accumulated_tint_weight = max(accumulated_tint_weight, calculate_sector_tint(SCREEN_UV, target_anchor, current_intensity, aspect_ratio));
        accumulated_wavy_energy = max(accumulated_wavy_energy, calculate_sector_wavy_energy(SCREEN_UV, target_anchor, current_intensity, TIME, aspect_ratio));
    }
    
    accumulated_tint_weight = clamp(accumulated_tint_weight, 0.0, 1.0);
    vec3 warped_screen_color = texture(screen_texture, SCREEN_UV + accumulated_displacement).rgb;
    
    vec3 neutral_vignette_tint = vec3(0.08); // Monochrome dark edges
    vec3 base_composition = mix(warped_screen_color, neutral_vignette_tint, accumulated_tint_weight * 0.6);
    
    COLOR = vec4(base_composition + accumulated_wavy_energy, 1.0);
}