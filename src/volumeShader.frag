#version 130

uniform sampler3D volume_tex;
in vec3 UVW;
uniform float scrollX;
uniform float scrollY;
uniform float scrollZ;

out vec4 outputColor;
void main()
{
    outputColor = texture(volume_tex, vec3(UVW.xy,0.5));
}