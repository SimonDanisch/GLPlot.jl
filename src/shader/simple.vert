{{GLSL_VERSION}}

{{in}} vec3 vertex;
{{out}} vec4 vertpos;

uniform mat4 projectionview;

void main(){
   vertpos      = projectionview * vec4(vertex, 1.0);
   gl_Position  = vertpos;
}