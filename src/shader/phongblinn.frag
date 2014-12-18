{{GLSL_VERSION}}
#extension GL_ARB_shading_language_420pack : enable

{{in}} vec3 o_normal;
{{in}} vec3 o_lightdir;
{{in}} vec3 o_vertex;
{{in}} vec2 o_uv;

{{out}} vec4 fragment_color;

struct Light
{
  vec3 diffuse;
  vec3 ambient;
  vec3 specular;
  vec3 position;
} tlight;

struct Material
{
  vec3 diffuse;
  vec3 ambient;
  vec3 specular;
  float position;
} thelight;

const int diffuse = 0;
const int ambient = 1;
const int specular = 2;

const int bump = 3;
const int specular_exponent = 3;
const int position = 3;

uniform vec3 material[4];
uniform vec3 light[4];
uniform float textures_used[4];



uniform sampler2DArray texture_maps;
uniform sampler2DArray diffuse_maps;
uniform sampler2DArray ambient_maps;
uniform sampler2DArray specular_maps;
uniform sampler2DArray bump_maps;



vec4[4] set_textures(float texused[4], vec3 mat[4], vec2 uv)
{
    vec4 merged_material[4] = { 
        vec4(mat[0],1),
        vec4(mat[1],1),
        vec4(mat[2],1),
        vec4(mat[3],1),
    };
    if(texused[diffuse]  >= 0)
        merged_material[diffuse] = texture(texture_maps, vec3(vec2(uv.x, 1-uv.y), texused[diffuse]));
    if(texused[ambient]  >= 0)
        merged_material[ambient] = texture(texture_maps, vec3(vec2(uv.x, 1-uv.y), texused[ambient]));
    if(texused[specular]  >= 0)
        merged_material[specular] = texture(texture_maps, vec3(vec2(uv.x, 1-uv.y), texused[specular]));
    //merged_material[bump]       = texused[bump] >= 0 ? texture(texture_maps, vec3(uv, texused[bump])) : vec4(mat[bump], 1);
    return merged_material;
}



vec4 blinn_phong(vec3 N, vec3 V, vec3 L, vec3 light[4], vec4 mat[4])
{
    float diff_coeff = max(dot(L,N), 0.0);

    // specular coefficient
    vec3 H = normalize(L+V);
    
    float spec_coeff = pow(max(dot(H,N), 0.0), mat[specular_exponent].x);
    if (diff_coeff <= 0.0)
        spec_coeff = 0.0;

    // final lighting model
    return  vec4(
            light[ambient]  * mat[ambient].rgb  +
            light[diffuse]  * mat[diffuse].rgb  * diff_coeff +
            light[specular] * mat[specular].rgb * spec_coeff, 
            1);
}

vec3 diffuse_lighting(vec3 L, vec3 N, vec3 Ld, vec3 Kd)
{
    return Ld * Kd * max( dot(L, N), 0.0);
}

void main(){

    vec3 L          = normalize(o_lightdir);
    vec3 V          = normalize(o_vertex);
    vec3 N          = normalize(o_normal);
    vec4 mat[4]     = set_textures(textures_used, material, o_uv);
    fragment_color  = blinn_phong(N, V, L, light, mat);
}