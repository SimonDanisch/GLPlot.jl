{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}

{{in}} vec3 vertex;
{{in}} vec3 normal; // normal might not be an uniform, whereas the other will be allways uniforms
{{in}} vec2 uv; // normal might not be an uniform, whereas the other will be allways uniforms

uniform vec3 cube_from; 
uniform vec3 cube_to; 
uniform vec2 color_range; 

uniform sampler3D vectorfield;
uniform sampler1D colormap;

uniform mat4 projection, view, model;

uniform vec3 light[4];
const int position = 3;

// data for fragment shader
{{out}} vec3 o_normal;
{{out}} vec3 o_lightdir;
{{out}} vec3 o_vertex;
{{out}} vec2 o_uv;


vec3 stretch(vec3 uv, vec3 from, vec3 to)
 {
   return from + (uv * (to - from));
 }
vec2 stretch(vec2 uv, vec2 from, vec2 to)
 {
   return from + (uv * (to - from));
 }
 float stretch(float uv, float from, float to)
 {
   return from + (uv * (to - from));
 }

const vec3 up = vec3(0,0,1);

mat4 rotation(vec3 direction)
{
    mat4 viewMatrix = mat4(1.0);

    if(direction == up)
    {
        return viewMatrix;
    }
    viewMatrix[0] = vec4(normalize(direction), 0);
    viewMatrix[1] = vec4(normalize(cross(up, viewMatrix[0].xyz)), 0);
    viewMatrix[2] = vec4(normalize(cross(viewMatrix[0].xyz, viewMatrix[1].xyz)), 0);
    
    return viewMatrix;
}
mat4 getmodelmatrix(vec3 xyz, vec3 scale)
{
   return mat4(
      vec4(scale.x, 0, 0, 0),
      vec4(0, scale.y, 0, 0),
      vec4(0, 0, scale.z, 0),
      vec4(xyz, 1));
}

void render(vec3 vertex, vec3 normal, vec2 uv,  mat4 model)
{
    mat3 normalmatrix           = mat3(transpose(inverse(view*model))); // shoudl really be done on the cpu
    vec4 position_camspace      = view * model * vec4(vertex,  1);
    vec4 lightposition_camspace = view * vec4(light[position], 1);
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

    ivec3 cubesize    = textureSize(vectorfield, 0);
    ivec3 fieldindex  = ivec3(gl_InstanceID / (cubesize.y * cubesize.z), (gl_InstanceID / cubesize.z) % cubesize.y, gl_InstanceID % cubesize.z);
    vec3 uvw          = vec3(fieldindex) / vec3(cubesize);
    vec3 vectororigin = stretch(uvw, cube_from, cube_to);
    vec3 vector       = texelFetch(vectorfield, fieldindex, 0).xyz;
    float vlength     = length(vector);
    mat4 rotation_mat = rotation(vector);

    render(vertex, normal, uv, model*getmodelmatrix(vectororigin, vec3(0.003, 0.003, 0.003))*rotation_mat);
}