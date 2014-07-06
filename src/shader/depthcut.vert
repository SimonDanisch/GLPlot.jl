in vec3 vertex;
uniform mat4 projectionview;
void main(){
   gl_Position  = projectionview * vec4(vertex, 1.0);
}