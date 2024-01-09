shader_type canvas_item;

uniform bool enabled = false;
uniform vec4 remove_color : source_color = vec4(1.);
uniform float dist = 0.03;

float color_dist(vec4 color1, vec4 color2) {
	return distance(color1, color2);
}

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	if (enabled && color_dist(col, remove_color) < dist) {
		COLOR = vec4(0.);
	}
}
