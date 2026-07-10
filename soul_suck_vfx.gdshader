shader_type canvas_item;

// Screen and noise texture inputs
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D noise_texture : repeat_enable;

// Array containing the live intensity levels for all 8 slices (passed from GDScript)
uniform float directional_intensities[8];

// Configuration parameters for the visual behavior
uniform float distortion_radius : hint_range(0.0, 2.0) = 0.6;
uniform float animation_speed = 3.0;

// Hardcoded clockwise anchors starting from the Right side (Index 0) matching the screen perimeter
const vec2 DIRECTIONAL_ANCHORS[8] = vec2[](
    vec2(1.0, 0.5),  // 0: RIGHT
    vec2(1.0, 1.0),  // 1: BOTTOM_RIGHT
    vec2(0.5, 1.0),  // 2: BOTTOM
    vec2(0.0, 1.0),  // 3: BOTTOM_LEFT
    vec2(0.0, 0.5),  // 4: LEFT
    vec2(0.0, 0.0),  // 5: TOP_LEFT
    vec2(0.5, 0.0),  // 6: TOP
    vec2(1.0, 0.0)   // 7: TOP_RIGHT
);

// Function dedicated to calculating visual warp offsets for an individual directional sector
vec2 calculate_sector_warp(vec2 current_uv, vec2 anchor_uv, float intensity, float noise_val) {
    if (intensity <= 0.001) {
        return vec2(0.0);
    }

    vec2 vector_to_anchor = anchor_uv - current_uv;
    float distance_to_anchor = length(vector_to_anchor);
    
    // Smoothly drop effect strength further away from the sector anchor edge
    float falloff_weight = smoothstep(distortion_radius, 0.0, distance_to_anchor);
    
    // Rhythmic visual pulse traveling outward toward the edge
    float radial_wave = sin(distance_to_anchor * 12.0 - TIME * animation_speed);
    float distortion_factor = (radial_wave * 0.03) + (noise_val * 0.02);
    
    vec2 pull_direction = normalize(vector_to_anchor);
    return pull_direction * distortion_factor * falloff_weight * intensity;
}

// Function dedicated to calculating vignette shading for an individual directional sector
float calculate_sector_tint(vec2 current_uv, vec2 anchor_uv, float intensity) {
    if (intensity <= 0.001) {
        return 0.0;
    }
    float distance_to_anchor = length(anchor_uv - current_uv);
    return smoothstep(distortion_radius, 0.0, distance_to_anchor) * intensity;
}

void fragment() {
    // Collect a continuous scrolling noise pattern to give the vortex a supernatural smoke atmosphere
    vec2 moving_noise_uv = UV + vec2(TIME * 0.1, TIME * -0.15);
    float noise_value = texture(noise_texture, moving_noise_uv).r;
    
    vec2 accumulated_displacement = vec2(0.0);
    float accumulated_tint_weight = 0.0;
    
    // Single-pass processing of all 8 sectors combined
    for (int sector_index = 0; sector_index < 8; sector_index++) {
        float current_intensity = directional_intensities[sector_index];
        vec2 target_anchor = DIRECTIONAL_ANCHORS[sector_index];
        
        accumulated_displacement += calculate_sector_warp(SCREEN_UV, target_anchor, current_intensity, noise_value);
        accumulated_tint_weight += calculate_sector_tint(SCREEN_UV, target_anchor, current_intensity);
    }
    
    // Clamp values to prevent over-exposure artifact blowouts if multiple sectors overlap
    accumulated_tint_weight = clamp(accumulated_tint_weight, 0.0, 1.0);
    
    // Sample the screen coordinates exactly once using our summed up displacement map
    vec3 warped_screen_color = texture(screen_texture, SCREEN_UV + accumulated_displacement).rgb;
    
    // Ethereal dark ghostly tinting
    vec3 ghost_soul_tint = vec3(0.04, 0.1, 0.16);
    vec3 final_composition = mix(warped_screen_color, ghost_soul_tint, accumulated_tint_weight * 0.65);
    
    COLOR = vec4(final_composition, 1.0);
}