#version 130

in vec3 position;

out vec3 vposition;

uniform mat4 mvp;

void main()
{
    vposition   = position; 
    gl_Position = mvp * vec4(position, 1.0); 
}