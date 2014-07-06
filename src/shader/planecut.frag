in vec3 uvw;
out vec4 fragment_color;

uniform sampler3D volume_tex;

void main(){
  fragment_color = texture(volume_tex, uvw);
}