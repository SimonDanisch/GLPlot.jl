{{GLSL_VERSION}}

flat {{in}} uint fragvalue;

{{out}} uint fragment_color;
void main(){
  fragment_color = uint(fragvalue);
}
