shader_type canvas_item;

uniform vec4 color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float radius : hint_range(0.0, 0.5) = 0.4;

void fragment() {
	// Calculate the distance from the center (0.5, 0.5) of the UV coordinates
	float circle = distance(UV, vec2(0.5));
	// smoothstep creates a soft or hard edge based on the feather value
	float alpha = step(circle, radius);
	
	COLOR = color;
	COLOR.a *= alpha;
}