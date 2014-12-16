{{GLSL_VERSION}}
#extension GL_ARB_shading_language_420pack : enable

{{in}} vec3 o_normal;
{{in}} vec3 o_lightdir;
{{in}} vec3 o_vertex;
{{in}} vec2 o_uv;


const int diffuse = 0;
const int ambient = 1;
const int specular = 2;

const int bump = 3;
const int specular_exponent = 3;
const int position = 3;

uniform vec3 material[4];
uniform vec3 light[4];
uniform int textures_used[4];



uniform sampler2DArray texture_maps;

vec4[4] set_textures(int matu[4], vec2 uv)
{
    vec4 tmaterial[4] = { 
    vec4(0),
    vec4(0),
    vec4(0),
    vec4(0),
};
    if(matu[diffuse] >= 0)
    {
        tmaterial[diffuse] =  texture(texture_maps, vec3(uv, matu[diffuse]));
    }
    if(matu[ambient] >= 0)
    {
        tmaterial[ambient] = texture(texture_maps, vec3(uv, matu[ambient]));
    }
    if(matu[specular] >= 0)
    {
        tmaterial[specular] = texture(texture_maps, vec3(uv, matu[specular]));
    }
    if(matu[bump] >= 0)
    {
        tmaterial[bump] = texture(texture_maps, vec3(uv, matu[bump]));
    }
    return tmaterial;
}


{{out}} vec4 fragment_color;

vec3 blinn_phong(vec3 N, vec3 V, vec3 L, vec3 light[4], vec3 mat[4])
{

    float diff_coeff = max(dot(L,N), 0.0);

    // specular coefficient
    vec3 H = normalize(L+V);
    
    float spec_coeff = pow(max(dot(H,N), 0.0), mat[specular_exponent].x);
    if (diff_coeff <= 0.0)
        spec_coeff = 0.0;

    // final lighting model
    return  light[ambient]  * mat[ambient]  +
            light[diffuse]  * mat[diffuse]  * diff_coeff +
            light[specular] * mat[specular] * spec_coeff;
}

vec3 diffuse_lighting(vec3 L, vec3 N, vec3 Ld, vec3 Kd)
{
    return Ld * Kd * max( dot(L, N), 0.0);
}

void main(){

    vec3 spec = vec3(0.0);
    vec3 L = normalize(o_lightdir);
    vec3 V = normalize(o_vertex);
    vec3 N = normalize(o_normal);
   
    fragment_color = vec4(blinn_phong(N, V, L, light, material),1);
}