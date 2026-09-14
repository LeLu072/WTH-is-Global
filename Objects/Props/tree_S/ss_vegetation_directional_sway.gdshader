shader_type spatial;
render_mode blend_mix,  cull_disabled, diffuse_toon, specular_schlick_ggx;

uniform sampler2D TextureColor : source_color;
uniform sampler2D TextureNormal : hint_normal;
uniform sampler2D TextureRoughness : source_color;
uniform float Specularity :hint_range(0.0, 1.0, 0.01) = 0.5;
uniform float NormalIntensity = 0.0;
uniform float AlphaScissor : hint_range(0.0, 1.0) = 0.5;

uniform float wind_speed_weight = 1.0;
uniform float wind_strength_weight = 1.0;

global uniform float wind_speed = 2.0; // you need to create this global parameter bro
global uniform float wind_strength = 0.5;  // you need to create this global parameter bro
global uniform vec2 wind_direction = vec2(1.0, 0.0); // X and Z direction.. and yes, you need to create this global parameter bro

uniform float Fake_SSS_Intensity = 1.0;
uniform float MixSSSTexture :hint_range(0.0, 1.0, 0.01) = 0.0;
uniform sampler2D FakeSSS_texture : source_color, hint_default_black;
uniform sampler2D FakeSSSColorAndBaias : source_color, hint_default_black, repeat_disable;


void vertex() {
	float time_offset = fma(TIME, (wind_speed*wind_speed_weight) , VERTEX.g);
	float sway_wave = sin(time_offset);
	float master_sway = sway_wave * (wind_strength*wind_strength_weight) * COLOR.r;
	vec3 sway_offset = vec3(
		master_sway * wind_direction.x, 
		0.0, 
		master_sway * wind_direction.y
	);
	
	VERTEX += sway_offset;
}


void fragment() {
	vec4 albedo_tex = texture(TextureColor, UV);
	vec4 normal_tex = texture(TextureNormal, UV);
	float roughness_tex = texture(TextureRoughness, UV).r;
	vec4 sss_tex = texture(FakeSSS_texture, UV);
	
	//  FAKE SSS MATH... using fresnel + normal
	vec3 view_normal_offset = fma(VIEW, vec3(-0.2), NORMAL);
	vec3 custom_normal = view_normal_offset + vec3(normal_tex.rg, 0.0);
	float fresnel = 1.0 - clamp(dot(custom_normal, VIEW), 0.0, 1.0);
	
	vec4 sss_color_bias = texture(FakeSSSColorAndBaias, vec2(fresnel));
	    
	// Lets decide if using SSS Texture or just Fresnel(gradient) .. or mix..
	vec3 sss_from_texture = sss_tex.rgb * sss_color_bias.r;
	vec3 sss_from_gradient = sss_color_bias.rgb;
	vec3 final_sss = mix(sss_from_gradient, sss_from_texture, MixSSSTexture);
	    
	ALBEDO = albedo_tex.rgb + (final_sss*Fake_SSS_Intensity);
	ALPHA = albedo_tex.a;
	ALPHA_SCISSOR_THRESHOLD = AlphaScissor;
	ROUGHNESS = roughness_tex;
	NORMAL_MAP = normal_tex.rgb;
	NORMAL_MAP_DEPTH = NormalIntensity;
	SPECULAR = Specularity;
}