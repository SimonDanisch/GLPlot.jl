{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}

{{vertex_type}} vertex;
{{normal_vector_type}} normal_vector; // normal might not be an uniform, whereas the other will be allways uniforms
{{offset_type}} offset;	//offset for texture look up. Needed to get neighbouring vertexes, when rendering the surface


uniform vec3 xrange;	
uniform vec3 yrange; 	
{{z_type}} z;	
		
{{xscale_type}} xscale;	
{{yscale_type}} yscale;		
{{zscale_type}} zscale;		
{{color_type}} color;


uniform mat3 normalmatrix;
uniform mat4 projection, view;

{{out}} vec3 N;
{{out}} vec3 V;
{{out}} vec4 vert_color;

{{instance_functions}} //It's rather a bad idea, but I outsourced the functions to another file

void main(){

	vec3  xyz, scale, normal, vert;
	vec2 uv;
	uv 		= getuv(vec2(xrange.y, yrange.y), gl_InstanceID, offset);
	xyz.xy 	= stretch(uv, vec2(xrange.x, yrange.x), vec2(xrange.z, yrange.z));
	xyz.z 	= {{z_calculation}}
	
	scale.x = {{xscale_calculation}}
	scale.y = {{yscale_calculation}}
	scale.z = {{zscale_calculation}}

    vert_color = {{color_calculation}}

    normal = {{normal_vector_calculation}}

    N = normalize(normalmatrix * normal);
    V = vec3(view  * vec4(xyz, 1.0));
    vert = {{vertex_calculation}}
    gl_Position = projection * view * getmodelmatrix(xyz, scale) * vec4(vert.xyz, 1.0);

}