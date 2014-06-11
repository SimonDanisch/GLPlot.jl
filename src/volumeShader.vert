#version 130

in vec3 position;
out vec3 uvw;

uniform mat4 mvp;

void main()
{
    uvw = position;
    gl_Position =  mvp * vec4(position, 1.0);
}
