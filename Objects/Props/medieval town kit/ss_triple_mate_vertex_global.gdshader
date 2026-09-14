shader_type spatial;
render_mode blend_mix, cull_back, diffuse_lambert, specular_schlick_ggx;

global uniform float Opacity_Layers : hint_range(0.0, 1.0) = 1.0;

group_uniforms BASE;
uniform vec2 UV_Scale_Base = vec2(1.0);
uniform vec2 UV_Offset_Base = vec2(0.0);
uniform sampler2D TextureColor_Base : source_color;
uniform sampler2D TextureORM_Base : hint_default_black;
uniform sampler2D TextureNormal_Base : hint_normal;
uniform sampler2D TextureEmission : hint_default_black;

group_uniforms A;
uniform vec2 UV_Scale_A = vec2(1.0);
uniform vec2 UV_Offset_A = vec2(0.0);
uniform sampler2D TextureColor_A : source_color;
uniform sampler2D TextureORM_A : hint_default_black;
uniform sampler2D TextureNormal_A : hint_normal;
uniform sampler2D TextureEmission_A : hint_default_black;
global uniform float Opacity_A : hint_range(0.0, 1.0) = 1.0;

group_uniforms B;
uniform vec2 UV_Scale_B = vec2(1.0);
uniform vec2 UV_Offset_B = vec2(0.0);
uniform sampler2D TextureColor_B : source_color;
uniform sampler2D TextureORM_B : hint_default_black;
uniform sampler2D TextureNormal_B : hint_normal;
uniform sampler2D TextureEmission_B : hint_default_black;
global uniform float Opacity_B : hint_range(0.0, 1.0) = 1.0;

group_uniforms C;
uniform vec2 UV_Scale_C = vec2(1.0);
uniform vec2 UV_Offset_C = vec2(0.0);
uniform sampler2D TextureColor_C : source_color;
uniform sampler2D TextureORM_C : hint_default_black;
uniform sampler2D TextureNormal_C : hint_normal;
uniform sampler2D TextureEmission_C : hint_default_black;
global uniform float Opacity_C : hint_range(0.0, 1.0) = 1.0;

group_uniforms Settings;
// UPDATED: Range now allows negative numbers for inverted normals
uniform float NormalIntensity : hint_range(-16.0, 16.0) = 1.0;
uniform float AlphaScissor : hint_range(0.0, 1.0) = 0.5;

group_uniforms Wetness;
uniform float WetnessDarkening : hint_range(0.0, 1.0) = 0.6; 
uniform float WetnessRoughness : hint_range(0.0, 1.0) = 0.05;
global uniform float wetness : hint_range(0.0, 1.0) = 1.0; 

vec3 blend_normals(vec3 base_norm, vec3 top_norm, float weight) {
	vec3 n1 = base_norm * 2.0 - 1.0;
	vec3 n2 = top_norm * 2.0 - 1.0;
	
	n2 = mix(vec3(0.0, 0.0, 1.0), n2, weight);
	
	vec3 blended = vec3(n1.xy + n2.xy, n1.z);
	blended = normalize(blended);
	
	return blended * 0.5 + 0.5;
}

void fragment() {
	
	vec2 uv_base = (UV * UV_Scale_Base) + UV_Offset_Base;
	vec2 uv_a = (UV * UV_Scale_A) + UV_Offset_A;
	vec2 uv_b = (UV * UV_Scale_B) + UV_Offset_B;
	vec2 uv_c = (UV * UV_Scale_C) + UV_Offset_C;
	
	vec4 base_color_tex = texture(TextureColor_Base, uv_base);
	vec3 albedo_base = base_color_tex.rgb;
	float alpha_base = base_color_tex.a;
	
	vec3 orm_base    = texture(TextureORM_Base, uv_base).rgb;
	vec3 norm_base   = texture(TextureNormal_Base, uv_base).rgb;
	vec3 emission_base = texture(TextureEmission, uv_base).rgb;
	
	vec3 albedo_a = texture(TextureColor_A, uv_a).rgb;
	vec3 orm_a    = texture(TextureORM_A, uv_a).rgb;
	vec3 norm_a   = texture(TextureNormal_A, uv_a).rgb;
	vec3 emission_a = texture(TextureEmission_A, uv_a).rgb;
	
	vec3 albedo_b = texture(TextureColor_B, uv_b).rgb;
	vec3 orm_b    = texture(TextureORM_B, uv_b).rgb;
	vec3 norm_b   = texture(TextureNormal_B, uv_b).rgb;
	vec3 emission_b = texture(TextureEmission_B, uv_b).rgb;
	
	vec3 albedo_c = texture(TextureColor_C, uv_c).rgb;
	vec3 orm_c    = texture(TextureORM_C, uv_c).rgb;
	vec3 norm_c   = texture(TextureNormal_C, uv_c).rgb;
	vec3 emission_c = texture(TextureEmission_C, uv_c).rgb;
	
	float weight_a     = COLOR.r *Opacity_A;
	float weight_b     = COLOR.g *Opacity_B;
	float weight_c     = COLOR.b *Opacity_C;
	float wetness_mask = COLOR.a; 
	
	vec3 final_albedo = mix(albedo_base, albedo_a, weight_a);
	final_albedo = mix(final_albedo, albedo_b, weight_b);
	final_albedo = mix(final_albedo, albedo_c, weight_c);
	
	vec3 final_orm = mix(orm_base, orm_a, weight_a);
	final_orm = mix(final_orm, orm_b, weight_b);
	final_orm = mix(final_orm, orm_c, weight_c);
	
	vec3 final_emission = mix(emission_base, emission_a, weight_a);
	final_emission = mix(final_emission, emission_b, weight_b);
	final_emission = mix(final_emission, emission_c, weight_c);
	
	// BLEND NORMALS
	vec3 final_normal = blend_normals(norm_base, norm_a, weight_a);
	final_normal = blend_normals(final_normal, norm_b, weight_b);
	
	// but..  Layer C uses a standard mix to completely overwrite underlying normals
	final_normal = mix(final_normal, norm_c, weight_c);
	
	// WETNESS PASS
	final_albedo = mix(  final_albedo,final_albedo * WetnessDarkening, wetness_mask*wetness);
	
	float final_roughness = final_orm.g;
	final_roughness = mix(final_roughness, WetnessRoughness,  wetness_mask*wetness);
	
	ALBEDO = mix(albedo_base,final_albedo,Opacity_Layers);
	ALPHA = alpha_base;
	ALPHA_SCISSOR_THRESHOLD = AlphaScissor;
	ROUGHNESS = mix(final_orm.g,final_roughness,Opacity_Layers);
	METALLIC = final_orm.b; 
	NORMAL_MAP = final_normal;
	NORMAL_MAP_DEPTH = NormalIntensity;
	EMISSION = final_emission;
}