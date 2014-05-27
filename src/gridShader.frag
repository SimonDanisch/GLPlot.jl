#version 130
uniform vec4 bg_color;
uniform vec4 grid_color;
uniform vec3 grid_size;
uniform vec3 grid_offset;
uniform vec3 grid_thickness;


in vec3 vposition;

out vec4 colourV;

void main()
{
 	vec3  v1  	= vec3(vposition.xyz) / 50.0;
 	vec3  v  	= vec3(vposition.xyz) / 10;
    vec3  f  	= abs(fract(v) - 0.5);
    vec3  f1  	= abs(fract(v1) - 0.5);
    vec3  df 	= fwidth(v);
    vec3  g  	= smoothstep(-grid_thickness, +grid_thickness, f);
    vec3  g1  	= smoothstep(-grid_thickness / 2.0, +grid_thickness / 2.0, f1);
    float c  	= (1.0-g.x * g.y * g.z);
    float c1  	= (1.0-g1.x * g1.y * g1.z);
    colourV  	= mix(bg_color, grid_color, c + c1);


}