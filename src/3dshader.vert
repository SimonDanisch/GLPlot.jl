#version 110
attribute vec3 position;

varying float o_z;


uniform mat4 mvp;

void main(){
	gl_Position = mvp * vec4(position, 1.0);	
	o_z = position.z;
}
