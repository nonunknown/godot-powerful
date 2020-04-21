// This is a very basic splat shader with a single texture. Feel free to copy
// and modify it as needed for more specific needs.

shader_type spatial;

render_mode blend_mix;

// The albedo texture to use.
uniform sampler2D tex;

// TODO: More texture channels?

// This is for adjusting how far to taper the alpha up and down.
uniform float splat_height = 1;
varying vec3 original_vertex_position;

void vertex()
{
	// Do the usual projection+modelview calculation.
	POSITION = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	
	// Offset the output position towards the viewer by an epsilon value, so it
	// appears in front of whatever surface the splat is on.
	POSITION.z -= 0.0001;
	
	// Save the original object-space position so we can do alpha effects based
	// on it.
	original_vertex_position = VERTEX;
}

void fragment()
{
	// Sample texture and set albedo and alpha.
	vec4 texColor = texture(tex, UV);
	ALBEDO = texColor.rgb;
	ALPHA = texColor.a;

	// Texture import settings about clamping don't seem to work, so let's just
	// cut off the alpha if it goes out of range.
	if(UV.x < 0.0 || UV.y < 0.0 || UV.x > 1.0 || UV.y > 1.0) {
		ALPHA = 0.0;
	}
	
	// Taper alpha value off as we get away from the center (height-wise) of
	// the splat.
	float splat_height_taper_range = splat_height/2.0;
	ALPHA *= (splat_height_taper_range -
		abs(original_vertex_position.y)) / splat_height_taper_range;
}
