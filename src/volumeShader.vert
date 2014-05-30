#version 130

in vec3 position;
out vec3 xyz;

uniform mat4 mvp;

void main()
{
    xyz = mvp * position;
    uvw = 
    //gl_FrontColor = gl_Color;
    gl_TexCoord[2] = gl_Position;
    gl_TexCoord[0] = gl_MultiTexCoord1;
    gl_TexCoord[1] = gl_Color;
}
