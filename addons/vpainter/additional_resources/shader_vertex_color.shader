/*----------------------
VERTEX COLOR SHADER v1.0:
------------------------
The shader is used to visualize the vertex colors of a given mesh.
You can use "show_r", "show_g" and "show_b" to isolate specific channels for preview.
------------------------
------------------------*/

shader_type spatial;

uniform bool show_r;
uniform bool show_g;
uniform bool show_b;

varying vec4 col;

void vertex(){
	col = vec4(0.0,0.0,0.0,0.0);
	if(show_r){
	    col.r = COLOR.r;
	}
	if(show_g){
		col.g = COLOR.g;
	}
	if(show_b){
		col.b = COLOR.b;
	}
}

void fragment(){
	ALBEDO = col.rgb;
}