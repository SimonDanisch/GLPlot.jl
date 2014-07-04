#extension GL_ARB_draw_instanced : enable
in vec2 offset;
out vec3 N;
out vec3 vert;
out vec4 color;

uniform sampler2D ztex;
uniform sampler2D colortex;

uniform mat4 view, projection;
uniform mat3 normalmatrix;

mat4 getmodelmatrix(vec3 xyz, float xscale, float yscale, float zscale)
{
   return mat4(
      vec4(xscale, 0, 0, 0),
      vec4(0, yscale, 0, 0),
      vec4(0, 0, zscale, 0),
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
vec2 getxy(vec2 uv, vec2 from, vec2 to)
 {
   return from + (uv * (to - from));
 }
vec3 getxy(vec3 uv, vec3 from, vec3 to)
 {
   return from + (uv * (to - from));
 }
void main(){
    ivec2 texsize = textureSize(ztex, 0);
    vec2 uv = getuv(texsize, gl_InstanceID, offset);
    vec2 xy = getxy(uv, vec2(0,0), vec2(1,1));
    vec4 zdata = texture(ztex, uv);
    vec3 xyz = vec3(xy, zdata.x);

    color = texture(colortex, uv);

    N = normalize(normalmatrix * zdata.yzw);
    //N = zdata.yzw;

    vert = vec3(view  * vec4(xyz, 1.0));

    gl_Position = projection * view *  getmodelmatrix(xyz, 1.0, 1.0, 1.0) * vec4(0,0,0, 1.0);
}