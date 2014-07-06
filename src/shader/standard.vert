in vec3 vertex;
in vec3 normal;

out vec3 N;
out vec3 V;

uniform mat4 view, projection;
uniform mat3 normalmatrix;

void main(){

	V = vec3(view  * vec4(vertex,1.0));       
   	N = normalize(normalmatrix * normal);

   	gl_Position = projection * view * vec4(vertex, 1.0);
}