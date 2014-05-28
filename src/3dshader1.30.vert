#version 130
in vec3 position;

out float o_z;
out vec3 xyz;

uniform mat4 mvp;

void main(){
	xyz = position;	

	gl_Position =  mvp * vec4(position, 1.0);
	o_z = position.z;
}
