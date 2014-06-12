#version 130


in vec3 position;

out vec3 position_o;

uniform mat4 mvp;

void main()
{
    position_o 	= position;
    gl_Position = mvp * vec4(position, 1.0);
}
