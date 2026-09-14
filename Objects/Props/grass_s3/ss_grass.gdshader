shader_type spatial;
render_mode cull_disabled,diffuse_toon;

global uniform vec2 wind_direction; 

uniform sampler2D albedo_texture : source_color;
uniform vec3 albedo_color : source_color = vec3(1.0, 1.0, 1.0);
uniform float alpha_scissor_threshold : hint_range(0.0, 1.0) = 0.5;

// Wind & Noise Control
//uniform vec2 noise_scale = vec2(1.0,1.0);
global uniform sampler2D wind_noise;
uniform float wind_speed_weight = 1.0;
uniform float wind_strength_weight = 0.5;
uniform float noise_scale = 0.1;

global uniform float wind_speed ;
global uniform float wind_strength ;

// NEW: Mask texture to control bending intensity
uniform sampler2D sway_mask : hint_default_black, repeat_disable; 
// Using hint_default_black ensures that if you forget to assign a texture, 
// the grass won't randomly fly away.

void vertex() {
    vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    
    vec2 noise_uv = (world_pos.xz * noise_scale) - (wind_direction * (wind_speed_weight*wind_speed) * TIME);
    float noise_val = texture(wind_noise, noise_uv).r;
    
    vec3 sway = vec3(wind_direction.x, 0.0, wind_direction.y) * noise_val * (wind_strength*wind_strength_weight);
    
    // NEW: Sample the mask texture using the mesh's UV.
    // White pixels (1.0) will sway fully, black pixels (0.0) stay planted.
    float height_mask = texture(sway_mask, UV).r;
    
    VERTEX += sway * height_mask;
    VERTEX.y -= length(sway) * height_mask * 0.5;
}

void fragment() {
	vec4 tex = texture(albedo_texture, UV);
	
	
	
	ALBEDO = tex.rgb * albedo_color ;
	ALPHA = tex.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_scissor_threshold;
}