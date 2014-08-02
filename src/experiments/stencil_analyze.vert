{{GLSL_VERSION}}

{{in}} vec2 vertex;

uniform usampler2D stencil;
uniform int groups;

vec2 getuv(ivec2 texdim, int index)
{
  float x = float(texdim.x);
  float y = float(texdim.y);
  float i = float(index);

  float u = float((index % texdim.x)) / x;
  float v = (i / y) / y;
  return vec2(u,v);
}

void main(){
	vec2 uv 	= getuv(textureSize(stencil, 0), gl_InstanceID);
	uint value 	= texture(stencil, uv).r;
   	gl_Position = ((value / groups) * 2) - 1;
}