#version 130

in vec3 position;
in vec3 uv;
out vec3 uvw;

uniform mat4 mvp;

void main()
{
    uvw = uv;
    gl_Position =  mvp * vec4(position, 1.0);
}
