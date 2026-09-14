shader_type spatial;

render_mode blend_add, unshaded, cull_disabled, depth_draw_never;

uniform vec4 ray_color : source_color = vec4(1.0, 0.9, 0.65, 1.0);
uniform float intensity : hint_range(0.0, 5.0) = 1.0;

// Noise texture to simulate dust or uneven light shafts
uniform sampler2D noise_texture : repeat_enable, filter_linear_mipmap;
uniform vec2 scroll_speed = vec2(0.0, -0.2);
uniform vec2 noise_scale = vec2(1.0, 1.0);

uniform float edge_fade_power : hint_range(0.1, 5.0) = 2.0;
uniform float height_fade_power : hint_range(0.1, 5.0) = 1.5;

// Proximity fade to prevent harsh clipping into the ground/objects
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;
uniform float proximity_fade_distance : hint_range(0.0, 5.0) = 1.0;

// Some extra stuff.. more artistic flexibility you know..
uniform sampler2D multiply_gradient2D_extra : repeat_disable, hint_default_white;


void fragment() {
	vec2 noise_uv = UV*noise_scale + TIME * scroll_speed;
	float noise_val = texture(noise_texture, noise_uv).r;
	
	float grad_vanish = texture(multiply_gradient2D_extra, UV).r;
	
	float edge_fade = pow(clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), edge_fade_power);
	
	float height_fade = pow(clamp(1.0 - UV.y, 0.0, 1.0), height_fade_power);
	
	// Proximity Fade 
	float depth = texture(depth_texture, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z;
	float depth_blend = clamp((linear_depth + VERTEX.z) / proximity_fade_distance, 0.0, 1.0);
	
	float final_alpha = noise_val * edge_fade * height_fade * depth_blend * ray_color.a * intensity;
	
	ALBEDO = ray_color.rgb;
	ALPHA = final_alpha * grad_vanish;
}