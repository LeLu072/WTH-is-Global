shader_type spatial;
render_mode blend_add, unshaded, depth_draw_never, cull_disabled;

global uniform vec4  energy_color    : source_color = vec4(0.0, 0.8, 1.0, 1.0);
uniform float fresnel_power : hint_range(0.1, 10.0) = 2.0;

group_uniforms Scanlines;
uniform float scanline_count : hint_range(0.0, 200.0) = 50.0;
uniform float scanline_speed : hint_range(-10.0, 10.0) = 5.0;

group_uniforms Glitch;
uniform float glitch_speed      : hint_range(0.0, 10.0) = 3.0;
uniform float glitch_intensity  : hint_range(0.0, 0.2) = 0.02;
uniform float glitch_block_size : hint_range(0.1, 10.0) = 5.0;

varying vec3 local_pos;

// Simple pseudo-random function for the glitch
float hash(float n) {
	return fract(sin(n) * 43758.5453);
}

void vertex() {
	local_pos = VERTEX;
	
	float glitch_time = floor(TIME * glitch_speed);
	float block = floor(VERTEX.y * glitch_block_size);
	float noise = hash(block + glitch_time);
	
	if (noise > 0.8) {
		VERTEX.x += (hash(noise) - 0.5) * glitch_intensity;
		VERTEX.z += (hash(noise + 1.0) - 0.5) * glitch_intensity;
	}
}

void fragment() {
	float dot_product = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float fresnel = pow(1.0 - dot_product, fresnel_power);
	
	float scanlines = sin((local_pos.y * scanline_count) - (TIME * scanline_speed));
	scanlines = smoothstep(0.0, 0.5, scanlines); 
	float intensity = (fresnel + scanlines * 0.3) * energy_color.a;
	
	ALBEDO = energy_color.rgb;
	EMISSION = energy_color.rgb * intensity * 2.0; 
	ALPHA = clamp(intensity, 0.0, 1.0);
}