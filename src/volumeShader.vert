#version 130

in vec3 position;
in vec3 uvw;
out vec3 UVW;

uniform mat4 mvp;

void main()
{
    gl_Position =  mvp * vec4(position, 1.0);
    //gl_FrontColor = gl_Color;
    UVW = uvw;
}
