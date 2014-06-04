#version 130

in vec3 position;
out vec4 xyz;
uniform mat4 mvp;

void main()
{
    gl_Position =  mvp * vec4(position, 1.0);
    xyz = gl_Position;
}
