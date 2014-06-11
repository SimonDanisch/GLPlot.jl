#version 130

uniform sampler3D volume_tex;
uniform float stepsize;

in vec3 normed_dir;
in vec3 uvw;

out vec4 colour_output;

uniform vec3 camposition;

void main()
{
    vec3  normed_dir    = normalize(uvw - camposition) * stepsize;
    vec4  colorsample   = vec4(0.0);
    float alphasample   = 0.0;
    vec4  coloraccu     = vec4(0.0);
    float alphaaccu     = 0.0;
    vec3  start         = uvw;
    float maximum       = 0;
    float alpha_acc     = 0.0;  
    float alpha_sample; // The src alpha
    for(int i = 0; i < 10000; i++)
    {
      colorsample = texture(volume_tex, start);

        
        if(colorsample.r > coloraccu.r)
        {
          coloraccu = vec4(colorsample.r,colorsample.r,colorsample.r, 1);
        }
         
        /*
                colorsample = vec4(colorsample.r);
        alpha_sample = colorsample.a*stepsize;
        // why multply 3?
        coloraccu += (1.0 - alpha_acc) * colorsample * alpha_sample*3;
        alpha_acc += alpha_sample;
             
      */
      start += normed_dir;

      if(coloraccu.r >= 0.999 || start.x <= 0 || start.x >= 1 || start.y <= 0 || start.y >= 1 || start.z <= 0 || start.z >= 1)
      {
        break;
      }
    }
    colour_output = vec4(coloraccu.rgb , smoothstep(0.0, 0.1, coloraccu.r));
    //colour_output = coloraccu;

    //colour_output =vec4(smoothstep(0.0, 0.4, coloraccu.r),  smoothstep(0.4, 0.7, coloraccu.r), smoothstep(0.7, 0.8, coloraccu.r), smoothstep(0.4, 0.5, coloraccu.r));
    //colour_output =vec4(normed_dir, 1);
}
