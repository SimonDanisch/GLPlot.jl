{{GLSL_VERSION}}

uniform sampler2D color;
uniform sampler2D depth;

{{in}} vec2 frag_uv;
{{out}} vec4 frag_color;

uniform int anti_aliasing_on;

void main(){
  if(anti_aliasing_on == 1)
  {
    float neighbourx   = 1.0/textureSize(depth, 0).x;
    float neighboury   = 1.0/textureSize(depth, 0).y;
    float threshold    = 0.00001;
    float currentval   = texture(depth, frag_uv).r;

    float top          = texture(depth, frag_uv + vec2(neighbourx,0)).r;
    float left         = texture(depth, frag_uv + vec2(0,neighboury)).r;
    float bottom       = texture(depth, frag_uv + vec2(-neighbourx,0)).r;
    float right        = texture(depth, frag_uv + vec2(0,-neighboury)).r;

    vec4  alias        = texture(color, frag_uv);

    vec4 currentc     = texture(color, frag_uv);
    vec4 topc         = texture(color, frag_uv + vec2(neighbourx,0));
    vec4 leftc        = texture(color, frag_uv + vec2(0,neighboury));
    vec4 bottomc      = texture(color, frag_uv + vec2(-neighbourx,0));
    vec4 rightc       = texture(color, frag_uv + vec2(0,-neighboury));
    
    if(((currentval - top) > threshold) && ((currentval - left) > threshold))
    {
      alias = vec4(mix(currentc.rgb, vec3(1,0,1), 0.5), 1);
      //alias = (alias + topc + leftc) / 3;
    }
    if(((currentval - left) > threshold) && ((currentval - bottom) > threshold))
    {
      alias = leftc;
      //alias = (alias + bottomc + leftc) / 3;
    }
    if(((currentval - bottom) > threshold) && ((currentval - right) > threshold))
    {
      alias = bottomc;
      //alias = (alias + bottomc + rightc) / 3;
    }
    if(((currentval - right) > threshold) && ((currentval - top) > threshold))
    {
      alias = vec4(mix(currentc.rgb, vec3(1,0,1), 0.6), 1);
      //alias = (alias + topc + rightc) / 3;
    }

    frag_color = alias;
  }else
  {
    frag_color = texture(color, frag_uv);
  }
  
}
 