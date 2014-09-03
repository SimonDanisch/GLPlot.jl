{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}

{{vertex_type}} vertex;
{{normal_vector_type}} normal_vector; // normal might not be an uniform, whereas the other will be allways uniforms
{{offset_type}} offset;	//offset for texture look up. Needed to get neighbouring vertexes, when rendering the surface


{{xrange_type}} xrange;	
{{yrange_type}} yrange; 	
{{z_type}} z;	
		
{{xscale_type}} xscale;	
{{yscale_type}} yscale;		
{{zscale_type}} zscale;		
{{color_type}} color;

uniform vec2 texdimension;

uniform mat3 normalmatrix;
uniform mat4 modelmatrix;
uniform mat4 projection, view;

{{out}} vec3 N;
{{out}} vec3 V;
{{out}} vec4 vert_color;

{{instance_functions}} //It's rather a bad idea, but I outsourced the functions to another file

vec3 getnormal(sampler2D zvalues, vec2 uv)
{
	const vec2 size = vec2(2.0,0.0);
	const ivec3 off = ivec3(-1,0,1);

    vec4 wave = texture(zvalues, uv);
    float s11 = wave.x;
    float s01 = textureOffset(zvalues, uv, off.xy).x;
    float s21 = textureOffset(zvalues, uv, off.zy).x;
    float s10 = textureOffset(zvalues, uv, off.yx).x;
    float s12 = textureOffset(zvalues, uv, off.yz).x;
    vec3 va = normalize(vec3(size.xy,s21-s01));
    vec3 vb = normalize(vec3(size.yx,s12-s10));
    return cross(va,vb);
}
vec3 getnormal(float zvalues, vec2 uv)
{
    return normal_vector;
}

vec2 getcoordinate(sampler2D xvalues, sampler2D yvalues, vec2 uv)
{
	return vec2(texture(xvalues, uv).x, texture(yvalues, uv).x);
}
vec2 getcoordinate(vec2 xrange, vec2 yrange, vec2 uv)
{
	vec2 from = vec2(xrange.x, yrange.x);
	vec2 to   = vec2(xrange.y, yrange.y);
	return from + (uv * (to - from));
}
void main(){

	vec3  xyz, scale, normal, vert;
	vec2 uv = getuv(texdimension, gl_InstanceID, offset);
	xyz.xy 	= getcoordinate(xrange, yrange, uv);
	xyz.z 	= {{z_calculation}}
	
	scale.x = {{xscale_calculation}}
	scale.y = {{yscale_calculation}}
	scale.z = {{zscale_calculation}}

    vert_color = {{color_calculation}}

    normal = getnormal(z, uv);

    N = normalize(normalmatrix * normal);
    V = vec3(view  * vec4(xyz, 1.0));
    vert = {{vertex_calculation}}
    gl_Position = projection * view * modelmatrix * getmodelmatrix(xyz, scale) * vec4((vert.xyz - vec3(0.5,0.5,0)), 1.0);

}