shader_type canvas_item;
uniform bool enabled;
uniform sampler2D Blend;  //Blending mode texture
uniform float Intensity : hint_range(0, 1) = 1.0;  //Default should be 1 but syntax doesn't allow it currently?

void fragment() {
	if (enabled){
		vec4 bgColor;
		vec4 Color = texture(TEXTURE, UV);
		vec4 blendColor;
	   	vec4 output = vec4(1,1,1,1);
	
		bgColor = texture( SCREEN_TEXTURE, SCREEN_UV);
	
		output.a = Color.a;
	
		blendColor = texture( Blend, vec2(bgColor.r, Color.r) );
		output.r = blendColor.r;
		blendColor = texture( Blend, vec2(bgColor.g, Color.g) );
		output.g = blendColor.g;
		blendColor = texture( Blend, vec2(bgColor.b, Color.b) );
		output.b = blendColor.b;
	
		output.rgb = mix(Color.rgb, output.rgb, Intensity);
		COLOR = output;
		
	} else {
		COLOR = texture(TEXTURE, UV);
	}
}