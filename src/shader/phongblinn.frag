//{{GLSL_VERSION}}
#version 130
in vec3 N;
in vec3 V;
uniform vec3 light_position;
in vec4 color;

out vec4 fragment_color;



vec3 blinn_phong(vec3 N, vec3 V, vec3 L)
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
    return  Ka * vec3(0.2) +
            Kd * vec3(0.9, 0.1, 0.1)  * diff_coeff +
            Ks * vec3(0.7, 0.7, 0.9) * spec_coeff ;
}


void main(){

  vec3 L = normalize(light_position - V);

  fragment_color = vec4(blinn_phong(N, V, L), 1.0);
}
