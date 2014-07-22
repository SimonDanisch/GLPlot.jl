{{GLSL_VERSION}}

{{in}} vec2 uv_frag;
{{out}} vec4 frag_color;

uniform sampler2D image;

void main(){
  frag_color = texture(image, uv_frag);
}
