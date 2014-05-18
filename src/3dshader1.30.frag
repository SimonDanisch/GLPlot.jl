#version 130
in float o_z;
out vec4 colourV;

uniform int white;
void main(){
	if(white == 0)
	{
		colourV = vec4(o_z / 20.0, o_z / 20.0, 0.9, 1.0);
	}
	else
	{
		colourV = vec4(1.0, 1.0, 1.0, 1.0);
	}
}
