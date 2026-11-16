shader_type spatial;
render_mode cull_disabled;
uniform vec4 cloth_color : source_color = vec4(0.12, 0.16, 0.19, 1.0);
uniform float wind_strength : hint_range(0.0, 0.08) = 0.025;

void vertex() {
	// UV.y = 0 at the upper seam: the shoulders remain pinned.
	float loose = UV.y * UV.y;
	VERTEX.z += sin(TIME * 2.1 + VERTEX.x * 7.0 + UV.y * 3.0) * wind_strength * loose;
}

void fragment() {
	float weave = sin(UV.x * 220.0) * sin(UV.y * 260.0);
	ALBEDO = cloth_color.rgb * (0.97 + 0.03 * weave);
	ROUGHNESS = 0.96;
}
