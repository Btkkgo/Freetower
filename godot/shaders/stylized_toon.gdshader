shader_type spatial;
render_mode diffuse_toon, specular_disabled;

uniform vec4 base_color : source_color = vec4(0.45, 0.66, 0.35, 1.0);
uniform float roughness = 0.86;
uniform float rim_strength = 0.06;

void fragment() {
	ALBEDO = base_color.rgb;
	ROUGHNESS = roughness;
	float rim = pow(1.0 - max(dot(normalize(NORMAL), normalize(VIEW)), 0.0), 2.2);
	EMISSION = base_color.rgb * rim * rim_strength;
}
