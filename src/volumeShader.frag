#version 130

uniform sampler3D volume_tex;
uniform float stepsize;
uniform vec3 camPosition;
uniform mat4 mvp;

in vec3 xyz;
in vec3 UVW;

out vec4 colour_output;
void main()
{
    vec3 dir =  ((xyz - (mvp * vec4(camPosition, 1)).xyz) - vec3(50,50,50) ) / vec3(300,300,300);
    vec3 norm_dir = normalize(dir);
    vec3 delta_dir = norm_dir * stepsize;
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
