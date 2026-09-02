shader_type spatial;
render_mode blend_mix, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec4 water_color : source_color = vec4(0.08, 0.55, 0.68, 0.94);
uniform vec4 edge_color : source_color = vec4(0.38, 0.88, 0.82, 1.0);
uniform float wave_strength = 0.035;
uniform float wave_scale = 0.18;
uniform float wave_speed = 0.65;
uniform float edge_strength = 0.5;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float phase = world_position.x * wave_scale + world_position.z * wave_scale * 0.7 + TIME * wave_speed;
	VERTEX.y += (sin(phase) + cos(phase * 1.7)) * wave_strength;
}

void fragment() {
	float fresnel = pow(1.0 - max(dot(normalize(NORMAL), normalize(VIEW)), 0.0), 3.0);
	ALBEDO = mix(water_color.rgb, edge_color.rgb, fresnel * edge_strength);
	ROUGHNESS = 0.18;
	ALPHA = water_color.a;
}
