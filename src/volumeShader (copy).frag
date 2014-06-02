#version 130

uniform sampler3D volume_tex;
uniform float stepsize;
uniform vec3 camPosition;
uniform vec3 xyz;
uniform vec3 uvw;


out vec4 color_output;
void main()
{
    
    vec3 dir = camPosition - xyz;
    float len = length(dir); // the length from front to back is calculated and used to terminate the ray
    vec3 norm_dir = normalize(dir);
    vec3 delta_dir = norm_dir * stepsize;
    vec4 col_acc = vec4(0,0,0,0); // The dest color
    float alpha_acc = 0.0;                // The  dest alpha for blending
    float length_acc = 0.0;
    vec4 color_sample; // The src color 
    float alpha_sample; // The src alpha

    for(int i = 0; i < 450; i++)
    {
      color_sample = texture3D(volume_tex, uvw);
      //  why multiply the stepsize?
      alpha_sample = color_sample.a*stepsize;
      // why multply 3?
      col_acc   += (1.0 - alpha_acc) * color_sample * alpha_sample*3.0;
      alpha_acc += alpha_sample;
      uvw += delta_dir;
      length_acc += stepsize;
      if(length_acc >=   || alpha_acc > 1.0) 
        break; // terminate if opacity > 1 or the ray is outside the volume
    }

    color_output =  col_acc;
}