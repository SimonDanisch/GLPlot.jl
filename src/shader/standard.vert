{{GLSL_VERSION}}

{{in}} vec3 vertex;
{{in}} vec3 normal;

{{out}} vec3 N;
{{out}} vec3 V;
{{out}} vec4 vert_color;

uniform mat4 view, projection, model;
uniform mat3 normalmatrix;

void main(){

	V = vec3(view  * vec4(vertex,1.0));       
   	N = normalize(normalmatrix * normal);
   	vert_color = vec4(1,0,0,1);
   	gl_Position = projection * view * model * vec4(vertex, 1.0);
}