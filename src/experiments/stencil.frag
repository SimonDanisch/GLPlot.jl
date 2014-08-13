{{GLSL_VERSION}}

uniform vec3 color;
{{out}} uvec2 fragment_id;
{{out}} vec4 fragment_color;
void main(){

	fragment_id 	= uvec2(1);
  	fragment_color 	= vec4(color,1);
}
