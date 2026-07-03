shader_type spatial;

uniform sampler2D noise;
uniform vec3 base_color : source_color;
uniform vec3 noise_color : source_color;



void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	float noise_amount = texture(noise, UV).r;
	// step returns 0 if noise_amount is less than 0.5 and return 1 if higher
	// NOTE: You can also do this from the fast noise texture settings
	// It takes a gradient which controls the noise. Then set the interpolation to constant
	//float noise_amount_cel_shaded = step(noise_amount, 0.5);
	
	// mix mixes base_color and noise_color based on noise_amount
	//ALBEDO.rgb = mix(base_color, noise_color, noise_amount_cel_shaded);
	ALBEDO.rgb = mix(base_color, noise_color, noise_amount);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
