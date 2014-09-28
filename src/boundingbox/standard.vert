{{GLSL_VERSION}}

{{in}} vec3 vertex;

{{out}} vec3 V;

void main(){

	V = vertex;       
   	gl_Position = vec4(0);
}