#version 130

uniform sampler3D volume_tex;
uniform float stepsize;
uniform vec3 normalizer;

in vec3 position_o;

out vec4 colour_output;

uniform vec3 camposition;

void main()
{
    vec3  normed_dir    = normalize(position_o - camposition) * (normalizer * stepsize);
    vec4  colorsample   = vec4(0.0);
    float alphasample   = 0.0;
    vec4  coloraccu     = vec4(0.0);
    float alphaaccu     = 0.0;
    vec3  start         = position_o;
    float maximum       = 0;
    float alpha_acc     = 0.0;  
    float alpha_sample; // The src alpha
    int i = 0;
    for(i; i < 10000; i++)
    {
        colorsample = texture(volume_tex, start / normalizer);
        
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

      if(coloraccu.r >= 0.999 || start.x >= normalizer.x || start.y >= normalizer.y || start.z >= normalizer.z || start.x <= 0 || start.y <= 0 || start.z <= 0)
      {
        break;
      }
    }
    float r = smoothstep(0.3, 0.8, coloraccu.r);
    float g = smoothstep(0.6, 1.0, coloraccu.r);
    float b = smoothstep(0.0, 0.5, coloraccu.r);
    float a = smoothstep(0.0, 0.1, coloraccu.r);
    colour_output = vec4(r, g, b, a);
    //colour_output = vec4(start,1);

    //colour_output =vec4(smoothstep(0.0, 0.4, coloraccu.r),  smoothstep(0.4, 0.7, coloraccu.r), smoothstep(0.7, 0.8, coloraccu.r), smoothstep(0.4, 0.5, coloraccu.r));
    //colour_output =vec4(normed_dir, 1);
}
