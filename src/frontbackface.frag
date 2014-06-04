#version 130
in vec4 xyz;
out vec4 color_output;
void main()
{
  color_output = xyz;
}