shader_type spatial;
render_mode cull_disabled, diffuse_toon, specular_disabled;

uniform vec4 base_color : source_color = vec4(0.48, 0.72, 0.34, 1.0);
uniform float wind_strength = 0.10;
uniform float wind_speed = 1.8;

void vertex() {
	float phase = TIME * wind_speed + (MODEL_MATRIX[3].x + MODEL_MATRIX[3].z) * 0.2;
	float sway = sin(phase + VERTEX.y * 2.0) * wind_strength * VERTEX.y;
	VERTEX.x += sway;
	VERTEX.z += cos(phase * 0.8 + VERTEX.y) * wind_strength * 0.45 * VERTEX.y;
}

void fragment() {
	ALBEDO = base_color.rgb;
	ROUGHNESS = 0.92;
}
