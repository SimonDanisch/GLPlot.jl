#version 130

in vec3 position;
in vec3 uvw;
out vec3 UVW;
out vec3 xyz;

uniform mat4 mvp;

void main()
{
    gl_Position =  mvp * vec4(position, 1.0);
    xyz =  position;
    //gl_FrontColor = gl_Color;
    UVW = uvw;
}
