{{GLSL_VERSION}}

{{in}} vec2 vertex;
{{in}} vec2 uv;

{{out}} vec2 frag_uv;

void main(){
	frag_uv 	= uv;
   	gl_Position = vec4(vertex,0,1);
}