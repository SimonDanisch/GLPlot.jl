#version 130

in vec3 tangent;
in vec3 binormal;
in vec3 normal;
in vec3 vertex;

uniform vec3    lightdirection;  // Light direction in eye coordinates
uniform vec3    viewposition;

uniform mat4    mvp;
uniform mat4    normalmatrix;

out vec3 N, L, H, R, T, B, xyz;

void main()
{
    vec3 V, eyeDir;
    vec4 pos;
    xyz    = vertex / 500.0;
    pos    = mvp * vec4(vertex, 1.0);
    eyeDir = pos.xyz;

    N = normalize(normalmatrix * vec4(normal, 0.0)).xyz;
    L = normalize(lightdirection);
    V = normalize((mvp * vec4(viewposition, 1.0)).xyz - pos.xyz);
    H = normalize(L + V);
    R = normalize(reflect(eyeDir, N));
    T = normalize(normalmatrix * vec4(tangent, 0.0)).xyz;
    B = normalize(normalmatrix * vec4(binormal, 0.0)).xyz;

    gl_Position = pos;
}