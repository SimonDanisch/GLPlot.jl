{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}

{{vertex_type}} vertex;
{{normal_vector_type}} normal_vector; // normal might not be an uniform, whereas the other will be allways uniforms
{{offset_type}} offset;	//offset for texture look up. Needed to get neighbouring vertexes, when rendering the surface


uniform vec3 xrange;	
uniform vec3 yrange; 	
uniform {{zposition_type}} zposition;	
		
uniform {{xscale_type}} xscale;	
uniform {{yscale_type}} yscale;		
uniform {{zscale_type}} zscale;		
uniform {{color_type}} color;


uniform mat3 normalmatrix;
uniform mat4 projection, view;

{{out}} vec3 N;
{{out}} vec3 V;
{{out}} vec4 out_color;

{{instance_functions}}

void main(){

	vec3  xyz, scale, normal;

	xyz.x 	= maptogridcoordinates(gl_InstanceID, xrange);
	xyz.y 	= maptogridcoordinates(gl_InstanceID, yrange);
	xyz.z 	= {{zposition_calculation}}
	
	scale.x = {{xscale_calculation}}
	scale.y = {{yscale_calculation}}
	scale.z = {{zscale_calculation}}

    out_color = {{color_calculation}}

    normal = {{normal_vector_calculation}}

    N = normalize(normalmatrix * normal);
    V = vec3(view  * vec4(xyz, 1.0));

    gl_Position = projection * view *  getmodelmatrix(xyz, scale) * {{vertex_calculation};

}