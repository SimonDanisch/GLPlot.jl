#version 130

in vec3 position;
out vec3 vposition;

uniform mat4 mvp;

void main()
{
    gl_Position = mvp*position;
    //gl_FrontColor = gl_Color;
    gl_TexCoord[2] = gl_Position;
    gl_TexCoord[0] = gl_MultiTexCoord1;
    gl_TexCoord[1] = gl_Color;
}
