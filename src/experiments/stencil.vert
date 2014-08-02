{{GLSL_VERSION}}

{{in}} vec3 vertex;


uniform mat4 view, projection;

void main(){

   	gl_Position = projection * view * vec4(vertex, 1.0);
}