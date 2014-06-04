#version 130

uniform sampler3D volume_tex;

in vec3 delta_dir;
in vec3 UVW;

out vec4 colour_output;

uniform float stepsize;

void main()
{
    
    vec4 col_acc = vec4(0,0,0,0); // The dest color
    float alpha_acc = 0.0;                // The  dest alpha for blending
    vec4 color_sample; // The src color 
    float alpha_sample; // The src alpha
    vec3 uvw = UVW;
    for(int i = 0; i < 450; i++)
    {
      color_sample = texture3D(volume_tex, uvw);
      color_sample = vec4(color_sample.r, 0, 0, color_sample.r);
      //  why multiply the stepsize?
      alpha_sample = color_sample.a*stepsize;
      // why multply 3?
      col_acc   += (1.0 - alpha_acc) * color_sample * alpha_sample*3.0;
      alpha_acc += alpha_sample;
      uvw += delta_dir;
      if(!all(lessThanEqual(uvw, vec3(1,1,1))) || alpha_acc > 1.0) 
        break; // terminate if opacity > 1 or the ray is outside the volume
    }
    colour_output = col_acc;
}
