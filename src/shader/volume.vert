{{GLSL_VERSION}}

{{in}} vec3 vertex;
{{out}} vec3 frag_vert;

uniform mat4 projection, view;

void main()
{
    gl_Position = projection * view * vec4(vertex, 1.0);
    frag_vert = (vec4(vertex, 1.0)).xyz;
}