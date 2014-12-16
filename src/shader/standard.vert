{{GLSL_VERSION}}

{{in}} vec3 vertex;
{{in}} vec3 normal;
{{in}} vec2 uv;

// data for fragment shader
{{out}} vec3 o_normal;
{{out}} vec3 o_lightdir;
{{out}} vec3 o_vertex;
{{out}} vec2 o_uv;

uniform mat4 projection, view, model;
uniform mat3 normalmatrix;
uniform vec3 light[4];
uniform vec3 eyeposition;


const int position = 3;


void render(vec3 vertex, vec3 normal, vec2 uv,  mat4 model)
{
    vec4 position_camspace      = view * model * vec4(vertex, 1);
    vec4 lightposition_camspace = view * vec4(light[position],1);
    // normal in world space
    o_normal            = normalize(normalmatrix * normal);
    // direction to light
    o_lightdir          = normalize(lightposition_camspace.xyz - position_camspace.xyz);
    // direction to camera
    o_vertex            = -position_camspace.xyz;
    // texture coordinates to fragment shader
    o_uv                = uv;
    // screen space coordinates of the vertex
    gl_Position         = projection * position_camspace; 
}

void main(){
    render(vertex, normal, uv, model);
}