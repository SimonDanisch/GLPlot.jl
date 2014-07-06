
out vec3 uvw;
in vec3 vertex;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;


void main(){

   	uvw = vec3(model * vec4(vertex, 1.0));
    gl_Position = projection * view * model * vec4(vertex, 1.0);
}