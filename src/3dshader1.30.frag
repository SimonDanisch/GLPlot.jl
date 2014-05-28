#version 130
in vec3 xyz;
out vec4 colourV;

uniform vec3 camPosition;

void main(){
	float distance = length(xyz - camPosition) / 1000.0;
	vec4 color1 = vec4(1.0,0.0,0.0,1.0);
	vec4 color2 = vec4(1.0,1.0,0.0,1.0);
	colourV = mix(color1, color2, xyz.y / 500.0);
}
