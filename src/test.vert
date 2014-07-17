#version 420



uniform vec3 vertex;
uniform sampler2D normal_vector; // normal might not be an uniform, whereas the other will be allways uniforms
in vec2 offset;	//offset for texture look up. Needed to get neighbouring vertexes, when rendering the surface


uniform vec3 xrange;	
uniform vec3 yrange; 	
uniform sampler2D z;	
		
uniform float xscale;	
uniform float yscale;		
uniform float zscale;		
uniform vec4 color;


uniform mat3 normalmatrix;
uniform mat4 projection, view;

out vec3 N;
out vec3 V;
out vec4 vert_color;

mat4 getmodelmatrix(vec3 xyz, vec3 scale)
{
   return mat4(
      vec4(scale.x, 0, 0, 0),
      vec4(0, scale.y, 0, 0),
      vec4(0, 0, scale.z, 0),
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

	vec3  xyz, scale, normal, vert;
	vec2 uv;
	uv 		= getuv(vec2(xrange.y, yrange.y), gl_InstanceID, offset);
	xyz.xy 	= stretch(uv, vec2(xrange.x, yrange.x), vec2(xrange.z, yrange.z));
	xyz.z 	= texture(z, uv).r;
	
	scale.x = xscale;
	scale.y = yscale;
	scale.z = zscale;

    vert_color = color;

    normal = texture(normal_vector, uv).rgb;

    N = normalize(normalmatrix * normal);
    V = vec3(view  * vec4(xyz, 1.0));
    vert = vertex;
    gl_Position = projection * view * getmodelmatrix(xyz, scale) * vec4(vert.xyz, 1.0);

}