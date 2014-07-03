uniform sampler2D frontface1;
uniform sampler2D backface1;

uniform sampler2D backface2;
uniform sampler2D frontface2;


uniform sampler3D volume_tex;

uniform float stepsize;
uniform vec3 light_position;
in vec4 vertpos;
//in vec3 frag_uvw;

vec3 gennormal(vec3 uvw, vec3 gradient_delta)
{
    vec3 a,b;
    a.x = texture(volume_tex, uvw -vec3(gradient_delta.x,0.0,0.0) ).r;
    b.x = texture(volume_tex, uvw +vec3(gradient_delta.x,0.0,0.0) ).r;
    a.y = texture(volume_tex, uvw -vec3(0.0,gradient_delta.y,0.0) ).r;
    b.y = texture(volume_tex, uvw +vec3(0.0,gradient_delta.y,0.0) ).r;
    a.z = texture(volume_tex, uvw -vec3(0.0,0.0,gradient_delta.z) ).r;
    b.z = texture(volume_tex, uvw +vec3(0.0,0.0,gradient_delta.z) ).r;
    return normalize(a - b);
}
vec3 blinn_phong(vec3 N, vec3 V, vec3 L, vec3 diffuse)
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
            Kd * diffuse  * diff_coeff +
            Ks * vec3(0.7, 0.7, 0.9) * spec_coeff ;
}

out vec4 fragment_color;

void main()
{
    vec2 texc            = ((vertpos.xy / vertpos.w) + 1) / 2;

    vec4 back1           = texture(backface1, texc);
    vec4 back2           = texture(backface2, texc);


    vec4 front1          = texture(frontface1, texc);
    vec4 front2          = texture(frontface2, texc);

    vec3  coloraccu     = vec3(0);

    vec3 front = vec3(0);
    vec3 back = vec3(0);

    bool dontskip = true;
    if(back2.a < 1.0)
    {
      front = vec3(front1);
    }
    else if(
      (length(back2 - back1) > 0.001) &&
      ((length(front2 - front1) <= 0.001)) &&
      ((length(back2 - front1) >= -0.001))
    ){
      front = vec3(back2);
    }
    else if(
      (length(back2 - back1) <= 0.001) &&
       ((length(front2 - front1) <= 0.001))
    )
    {
      dontskip = false;
    }else
    {
      front = vec3(front1);
    }

    if(dontskip)
    {
      if(back2.a < 1.0 )
      {
        back = vec3(back1);
      }
      else if(
        ((length(front2 - back1) >= -0.001)) &&
        ((length(front2 - front1) >= 0.001))
      ){
        back = vec3(front2);
      }
      else if(
        (length(back2 - back1) <= 0.001) &&
         ((length(front2 - front1) <= 0.001))
      )
      {
        back = vec3(1);
      }else
      {
        back = vec3(back1);
      }

      vec3 dir            = vec3(back - front);
      float lengthdir     = length(dir);
      vec3  stepsize_dir  = normalize(dir) * stepsize;
      vec3  colorsample   = vec3(0.0);
      float alphasample   = 0.0;

      float alphaaccu     = 0.0;
      vec3  start         = front;
      float alpha_acc     = 0.0;
      float length_acc    = 0.0;
      float alpha_sample;

      for(int i; i < 10000; i++)
      {
        if(alpha_sample >= 1.0 || length_acc >= lengthdir)
        {
          break;
        }
        colorsample = texture(volume_tex, start).rgb;
        if(abs(colorsample.r - 0.2) < 0.01)
        {
          vec3 N = gennormal(start, vec3(stepsize));
          vec3 L =  normalize(light_position - start);
          colorsample = blinn_phong(N, start, L, vec3(0,0,1));
          alpha_sample = colorsample.r*stepsize;
          coloraccu += (1.0 - alpha_acc) * colorsample * alpha_sample*3;
          alpha_acc += alpha_sample;
          break;
        }
        start        += stepsize_dir;
        length_acc   += stepsize;
      }
    }



    fragment_color = vec4(coloraccu, 1.0);
}
