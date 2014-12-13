{{GLSL_VERSION}}

{{in}} vec2 uv_frag;
{{out}} vec4 frag_color;

uniform sampler2DArray image;

{{filterkernel_type}} filterkernel;


uniform vec2 normrange;
uniform float filternorm;


void main(){

	vec4 color = texture(image, vec3(uv_frag,1));
	frag_color = normrange.x + (color * (normrange.y - normrange.x));
}
 