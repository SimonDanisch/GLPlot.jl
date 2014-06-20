const gridvert = """
#version $(GLWindow.GLSL_VERSION)

in vec3 vertexes;

out vec3 vposition;

uniform mat4 mvp;

void main()
{
    vposition   = vertexes; 
    gl_Position = mvp * vec4(vertexes, 1.0); 
}
"""
const gridfrag = """
#version $(GLWindow.GLSL_VERSION)
uniform vec4 bg_color;
uniform vec4 grid_color;
uniform vec3 grid_thickness;
uniform vec3 grid_size;


in vec3 vposition;

out vec4 fragment_color;

void main()
{
 	vec3  v  	= vec3(vposition.xyz) * grid_size;
    vec3  f  	= abs(fract(v) - 0.5);
    vec3  df 	= fwidth(v);
    vec3  g  	= smoothstep(-grid_thickness * df, +grid_thickness * df, f);
    float c  	= (1.0-g.x * g.y * g.z);
    fragment_color = mix(bg_color, vec4(vposition.xyz, 1), c);
}
"""

global const shader = GLProgram(gridvert, gridfrag, "grid shader")




gridPlanes = GLBuffer(Float32[
					    0, 0, 0, 		
					    1, 0, 0,
					    1, 1, 0,
					    0,  1, 0,

					    0, 1, 1, 
					    0,  0, 1,

					    1, 0, 1,
					    ], 3)

gridPlaneIndexes = GLBuffer(GLuint[
									0, 1, 2, 2, 3, 0,   #xy PLane
									0, 3, 4, 4, 5, 0,	#yz Plane
									0, 5, 6, 6, 1, 0 	#xz Plane
								  ], 1, bufferType = GL_ELEMENT_ARRAY_BUFFER)
global const axis = RenderObject(
[
	:vertexes 			=> gridPlanes,
	:indexes			=> gridPlaneIndexes,
	#:grid_color 		=> Float32[0.1,.1,.1, 1.0],
	:bg_color 			=> Float32[0.0,.0,.0,0.04],
	:grid_thickness  	=> Float32[1,1,1],
	:grid_size  		=> Float32[50,50,50],
	:mvp 				=> cam.projectionview
], shader)


prerender!(axis, glEnable, GL_DEPTH_TEST, glDepthFunc, GL_LEQUAL)

