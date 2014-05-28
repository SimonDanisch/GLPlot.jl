uniform sampler2D tex;
uniform sampler3D volume_tex;
uniform float stepsize;
out vec4 colourV;

void main()
{
    vec2 texc = ((gl_TexCoord[2].xy/gl_TexCoord[2].w) + 1) / 2;
    vec4 start = gl_TexCoord[0];
    vec4 back_position = texture2D(tex, texc);
    vec3 dir = vec3(0.0);
    dir.x = back_position.x - start.x;
    dir.y = back_position.y - start.y;
    dir.z = back_position.z - start.z;
    float len = length(dir.xyz); // the length from front to back is calculated and used to terminate the ray
    vec3 norm_dir = normalize(dir);
    float delta = stepsize;
    vec3 delta_dir = norm_dir * delta;
    float delta_dir_len = length(delta_dir);
    vec3 vect = start.xyz;
    vec4 col_acc = vec4(0,0,0,0); // The dest color
    float alpha_acc = 0.0;                // The  dest alpha for blending
    float length_acc = 0.0;
    vec4 color_sample; // The src color 
    float alpha_sample; // The src alpha

    for(int i = 0; i < 450; i++)
    {
      color_sample = texture3D(volume_tex,vect);
      //  why multiply the stepsize?
      alpha_sample = color_sample.a*stepsize;
      // why multply 3?
      col_acc   += (1.0 - alpha_acc) * color_sample * alpha_sample*3 ;
      alpha_acc += alpha_sample;
      vect += delta_dir;
      length_acc += delta_dir_len;
      if(length_acc >= len || alpha_acc > 1.0) 
        break; // terminate if opacity > 1 or the ray is outside the volume
    }

    colourV =  col_acc;
}