in vec3 vertex;
out vec4 vertpos;
//out vec3 frag_uvw;
//in vec3 uvw;
uniform mat4 projectionview;
void main(){
   //frag_uvw     = uvw;
   vertpos      = projectionview * vec4(vertex, 1.0);
   gl_Position  = vertpos;
}