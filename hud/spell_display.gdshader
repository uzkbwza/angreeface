shader_type canvas_item;

uniform vec4 color : source_color;

void fragment() {
	COLOR.rgb = color.rgb;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
