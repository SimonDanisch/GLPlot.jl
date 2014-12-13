{{GLSL_VERSION}}
#extension GL_ARB_shading_language_420pack : enable

{{in}} vec3 o_normal;
{{in}} vec3 o_toLight;
{{in}} vec3 o_toCamera;
{{in}} vec2 o_texcoords;


bool textures_used;

const int diffuse = 0;
const int ambient = 1;
const int specular = 2;

const int bump = 3;
const int specular_exponent = 3;
const int position = 3;

uniform vec3 material[4];
uniform vec3 light[4];
uniform int tmaterialused[4];

vec4 tmaterial[4] = { 
    vec4(1),
    vec4(1),
    vec4(1),
    vec4(1),
};

uniform sampler2DArray texture_maps;

vec4[4] set_textures(int matu[4], vec2 uv)
{
    if(matu[diffuse] > -1)
    {
        tmaterial[diffuse] =  texture(texture_maps, vec3(uv, matu[diffuse]));
    }
    if(matu[ambient] > -1)
    {
        tmaterial[ambient] = texture(texture_maps, vec3(uv, matu[ambient]));
    }
    if(matu[specular] > -1)
    {
        tmaterial[specular] = texture(texture_maps, vec3(uv, matu[specular]));
    }
    if(matu[bump] > -1)
    {
        tmaterial[bump] = texture(texture_maps, vec3(uv, matu[bump]));
    }
    return tmaterial;
}


{{out}} vec4 fragment_color;

vec3 blinn_phong(vec3 N, vec3 V, vec3 L, vec3 light[4], vec3 mat[4], vec4 tmat[4])
{

    float diff_coeff = max(dot(L,N), 0.0);

    // specular coefficient
    vec3 H = normalize(L+V);
    
    float spec_coeff = pow(max(dot(H,N), 0.0), mat[specular_exponent].x);
    if (diff_coeff <= 0.0)
        spec_coeff = 0.0;

    // final lighting model
    return  light[ambient]  * mat[ambient]  * tmat[ambient].rgb +
            light[diffuse]  * mat[diffuse] * tmat[diffuse].rgb  * diff_coeff +
            light[specular] * mat[specular] * tmat[specular].rgb * spec_coeff;
}

void main(){
    vec3 L = normalize(o_toLight);
    vec3 V = normalize(o_toCamera);
    vec3 N = normalize(o_normal);

    vec4[4] tmat = set_textures(tmaterialused, vec2(o_texcoords.x, 1-o_texcoords.y));

    fragment_color = vec4(blinn_phong(N, V, L, light, material, tmat), 1);
}