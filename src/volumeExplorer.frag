#version 130

uniform sampler3D volume_tex;
in vec3 uvw;
out vec4 colour_output;


void main()
{
      colour_output = texture(volume_tex, uvw);
}
