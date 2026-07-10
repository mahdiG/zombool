shader_type spatial;

render_mode unshaded;

uniform sampler2D noise;
uniform vec3 main_color: source_color;
uniform vec3 secondary_color: source_color;
uniform float dissolve_amount: hint_range(0.0, 1.0) = 0.5;


void fragment() {
	float noise_value = texture(noise, UV).r;
	ALBEDO.rgb = mix(main_color, secondary_color, step(noise_value, dissolve_amount));
}