{{GLSL_VERSION}}

{{in}} vec3 V;

{{out}} vec3 minbuffer;
{{out}} vec3 maxbuffer;

void main()
{
	minbuffer = -V;
	maxbuffer = V;
}