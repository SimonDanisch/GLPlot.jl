varying float o_z;

uniform int white;
void main(){
	if(white == 0)
	{
		gl_FragColor = vec4(o_z / 20.0, o_z / 20.0, 0.9, 1.0);
	}
	else
	{
		gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
	}
}