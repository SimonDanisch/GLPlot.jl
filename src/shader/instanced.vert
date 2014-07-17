#version 410
//#extension GL_ARB_draw_instanced : enable
in vec2 offset;
out vec3 N;
out vec3 V;
out vec4 color_out;

uniform sampler2D zposition;
uniform sampler2D normal_vector;
uniform sampler2D color;

uniform mat4 view, projection;
uniform mat3 normalmatrix;

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
  return abs(range.x - range.z) / range.y;
}
float maptogridcoordinates(int index, vec3 range)
{
  return range.x + float((index % int(rangewidth(range) - range.x )));
}
void main(){
    ivec2 texsize = ivec2(200,200);
    vec2 uv = getuv(texsize, gl_InstanceID, offset);
    vec2 xy = stretch(uv, vec2(0,0), vec2(1,1));
    float z = texture(zposition, uv).r;
    vec3 xyz = vec3(xy, z);

    color_out = texture(color, uv);
    N = normalize(normalmatrix * texture(normal_vector, uv).rgb);
    V = vec3(view  * vec4(xyz, 1.0));

    gl_Position = projection * view *  getmodelmatrix(xyz, vec3(1)) * vec4(0,0,0, 1.0);
}