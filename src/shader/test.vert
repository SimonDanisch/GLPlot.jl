#version 130

#extension GL_ARB_draw_instanced : enable

in vec2 offset;	//offset for texture look up. Needed to get neighbouring vertexes, when rendering the surface

uniform vec3 xrange;	
uniform vec3 yrange; 	
uniform float zposition;	
		
uniform float xscale;	
uniform float yscale;		
uniform sampler2D zscale;		
uniform vec4 color;


uniform sampler2D normal_vector; // normal might not be an uniform, whereas the other will be allways uniforms
uniform mat3 normalmatrix;
uniform mat4 projection, view;

out vec3 N;
out vec3 V;
out vec4 out_color;

mat4 getmodelmatrix(vec3 xyz, vec3 scale)
{
   return mat4(
      vec4(scale.x, 0, 0, 0),
      vec4(0, scale.x, 0, 0),
      vec4(0, 0, scale.x, 0),
      vec4(xyz, 1));
}

vec2 getuv(ivec2 texdim, int index)
{
  float x = float(texdim.x);
  float y = float(texdim.y);
  float i = float(index);

  float u = float((index % texdim.x)) / x;
  float v = (i / y) / y;
  return vec2(u,v);
}
vec2 getuv(vec2 texdim, int index, vec2 offset)
{
  float u = float((index % int(texdim.x)));
  float v = float((index / int(texdim.y)));
  return (vec2(u,v) + offset) / texdim;
}
vec2 stretch(vec2 uv, vec2 from, vec2 to)
 {
   return from + (uv * (to - from));
 }
vec3 getxy(vec3 uv, vec3 from, vec3 to)
 {
   return from + (uv * (to - from));
 }

float rangewidth(vec3 range)
{
  return abs(range.x - range.z)/range.y;
}
float maptogridcoordinates(int index, vec3 range)
{
  return range.x + float((index % int(rangewidth(range) - range.x )));
}

void main(){

	vec3  xyz, scale, normal;

	xyz.x 	= maptogridcoordinates(gl_InstanceID, xrange);
	xyz.y 	= maptogridcoordinates(gl_InstanceID, yrange);
	xyz.z 	= zposition;
	
	scale.x = xscale;
	scale.y = yscale;
	scale.z = texture(zscale, xyz.xy / vec2(rangewidth(xrange), rangewidth(yrange))).r;

    out_color = color;

    normal = 

    N = normalize(normalmatrix * normal);
    V = vec3(view  * vec4(xyz, 1.0));

    gl_Position = projection * view *  getmodelmatrix(xyz, scale) * vec4(0,0,0, 1.0);

}