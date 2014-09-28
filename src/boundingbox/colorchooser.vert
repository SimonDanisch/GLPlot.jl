{{GLSL_VERSION}}


{{in}} vec3 vertex;
{{in}} vec2 uv;


uniform mat4 projection, view;

void main(){
	V = vec4(vertex, 1.0)
   	gl_Position = vec4(0,0,0,0);
}