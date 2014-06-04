#version 130

in vec3 position;
out vec3 uvw;

uniform mat4 mvp;
uniform vec3 scaleUVW;

void main()
{
    uvw = position + scaleUVW;
    gl_Position =  mvp * vec4(position, 1.0);
}
