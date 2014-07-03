global blinn_phong = "
vec3 blinn_phong(vec3 N, vec3 V, vec3 L, )
{
    // material properties
    // you might want to put this into a bunch or uniforms
    vec3 Ka = vec3(1.0, 1.0, 1.0);
    vec3 Kd = vec3(1.0, 1.0, 1.0);
    vec3 Ks = vec3(1.0, 1.0, 1.0);
    float shininess = 50.0;

    // diffuse coefficient
    float diff_coeff = max(dot(L,N),0.0);

    // specular coefficient
    vec3 H = normalize(L+V);
    float spec_coeff = pow(max(dot(H,N), 0.0), shininess);
    if (diff_coeff <= 0.0) 
        spec_coeff = 0.0;

    // final lighting model
    return  Ka * gl_LightSource[light].ambient.rgb + 
            Kd * gl_LightSource[light].diffuse.rgb  * diff_coeff + 
            Ks * gl_LightSource[light].specular.rgb * spec_coeff ;
}
"