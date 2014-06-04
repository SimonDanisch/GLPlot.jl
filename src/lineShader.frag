#version 130

out vec4 color_output;
uniform vec4 linecolor;
void main()
{
  color_output = linecolor;
}