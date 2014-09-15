{{GLSL_VERSION}}

flat {{in}} uvec2 fragvalue;

{{out}} uvec2 fragment_color;
void main(){
  fragment_color = uvec2(fragvalue);
}
