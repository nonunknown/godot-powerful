/*----------------------
HEIGHTBLEND SHADER v1.0:
------------------------
The shader uses 3 textures per material:
	* M: A mask texture. R channel contains the height information, G channel contains the rougness information and B channel contains the metal information.
	* C: RGB color/albedo information.
	* N: Normalmap information.
------------------------
------------------------*/
shader_type spatial;

uniform float uv_scale:hint_range(0.01, 100.0) = 1;

uniform sampler2D m1;
uniform sampler2D c1:hint_albedo;
uniform sampler2D n1:hint_normal;

uniform sampler2D m2;
uniform sampler2D c2:hint_albedo;
uniform sampler2D n2:hint_normal;

uniform sampler2D m3;
uniform sampler2D c3:hint_albedo;
uniform sampler2D n3:hint_normal;

uniform sampler2D m4;
uniform sampler2D c4:hint_albedo;
uniform sampler2D n4:hint_normal;

uniform float blend_softness1:hint_range(0.01, 1.0) = 0.025;
uniform float blend_softness2:hint_range(0.01, 1.0) = 0.025;
uniform float blend_softness3:hint_range(0.01, 1.0) = 0.025;


vec3 heightblend(vec3 input1, float height1, vec3 input2, float height2, float softness){
	float height_start = max(height1, height2) - softness;
	float level1 = max(height1 - height_start, 0);
	float level2 = max(height2 - height_start, 0);

	return ((input1 * level1) + (input2 * level2)) / (level1 + level2);
}

vec3 heightlerp(vec3 input1, float height1, vec3 input2, float height2,float softness, float t ){
	t = clamp(t, 0.0 , 1.0);
    return heightblend(input1, height1 * (1.0 - t), input2, height2 * t, softness);
}

void fragment(){
	vec3 mask1 = texture(m1, UV * uv_scale).rgb;
	vec3 mask2 = texture(m2, UV * uv_scale).rgb;
	vec3 mask3 = texture(m3, UV * uv_scale).rgb;
	vec3 mask4 = texture(m4, UV * uv_scale).rgb;

	vec3 col1 = texture(c1, UV * uv_scale).rgb;
	vec3 col2 = texture(c2, UV * uv_scale).rgb;
	vec3 col3 = texture(c3, UV * uv_scale).rgb;
	vec3 col4 = texture(c4, UV * uv_scale).rgb;

	vec3 nor1 = texture(n1, UV * uv_scale).rgb;
	vec3 nor2 = texture(n2, UV * uv_scale).rgb;
	vec3 nor3 = texture(n3, UV * uv_scale).rgb;
	vec3 nor4 = texture(n4, UV * uv_scale).rgb;
	
	vec3 m_blend1 = heightlerp(mask1.rgb, mask1.r, mask2.rgb, mask2.r, blend_softness1, COLOR.r);
	vec3 m_blend2 = heightlerp(m_blend1.rgb, m_blend1.r, mask3.rgb, mask3.r, blend_softness2, COLOR.g);
	vec3 m_blend3 = heightlerp(m_blend2.rgb, m_blend2.r, mask4.rgb, mask4.r, blend_softness3, COLOR.b);
	
	vec3 c_blend1 = heightlerp(col1.rgb, mask1.r, col2.rgb, mask2.r, blend_softness1, COLOR.r);
	vec3 c_blend2 = heightlerp(c_blend1.rgb, m_blend1.r, col3.rgb, mask3.r, blend_softness2, COLOR.g);
	vec3 c_blend3 = heightlerp(c_blend2.rgb, m_blend2.r, col4.rgb, mask4.r, blend_softness3, COLOR.b);

	vec3 n_blend1 = heightlerp(nor1.rgb, mask1.r, nor2.rgb, mask2.r, blend_softness1, COLOR.r);
	vec3 n_blend2 = heightlerp(n_blend1.rgb, m_blend1.r, nor3.rgb, mask3.r, blend_softness2, COLOR.g);
	vec3 n_blend3 = heightlerp(n_blend2.rgb, m_blend2.r, nor4.rgb, mask4.r, blend_softness3, COLOR.b);
	
	ALBEDO = c_blend3.rgb;
	NORMALMAP = n_blend3.rgb;
	ROUGHNESS = m_blend3.g;
	METALLIC = m_blend3.b;
}