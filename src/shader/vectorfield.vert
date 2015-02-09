{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}

{{in}} vec3 vertex;
{{in}} vec3 normal_vector; // normal might not be an uniform, whereas the other will be allways uniforms

uniform vec3 cube_from; 
uniform vec3 cube_to; 
uniform vec2 color_range; 

uniform sampler3D vectorfield;
uniform sampler1D colormap;

uniform mat4 modelmatrix;
uniform mat4 projection, view;

uniform vec3 light_position;


{{out}} vec3 N;
{{out}} vec3 V;
{{out}} vec3 L;

{{out}} vec4 vert_color;



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
/*
mat3 lookat(vec3 eyePos)
{
    vec3 zaxis = normalize(eyePos);
    vec3 xaxis = normalize(cross(up, zaxis));
    vec3 yaxis = normalize(cross(zaxis, xaxis));

    mat3 viewMatrix = mat3(1.0);
    viewMatrix[0] = xaxis;
    viewMatrix[1] = yaxis;
    viewMatrix[2] = zaxis;
    mat3 translationmatrix = mat3(1.0);
    translationmatrix[]
    return viewMatrix * translationmatrix(-eyePos)
}
*/

void render(vec3 vertex, vec3 normal, mat4 model)
{
    mat4 modelview              = view * model;
    mat3 normalmatrix           = mat3(modelview); // shoudl really be done on the cpu
    vec4 position_camspace      = modelview * vec4(vertex,  1);
    vec4 lightposition_camspace = view * vec4(light_position, 1);
    // normal in world space
    N            = normalize(normalmatrix * normal);
    // direction to light
    L            = normalize(lightposition_camspace.xyz - position_camspace.xyz);
    // direction to camera
    V            = -position_camspace.xyz;
    // texture coordinates to fragment shader
    // screen space coordinates of the vertex
    gl_Position  = projection * position_camspace; 
}



void main(){
    ivec3 cubesize    = textureSize(vectorfield, 0);
    ivec3 fieldindex  = ivec3(gl_InstanceID / (cubesize.y * cubesize.z), (gl_InstanceID / cubesize.z) % cubesize.y, gl_InstanceID % cubesize.z);
    vec3 uvw          = vec3(fieldindex) / vec3(cubesize);
    vec3 vectororigin = stretch(uvw, cube_from, cube_to);
    vec3 vector       = texelFetch(vectorfield, fieldindex, 0).xyz;
    float vlength     = length(vector);
    mat4 rotation_mat = rotation(vector);
    vert_color        = texture(colormap, vlength);
    render(vertex, normal_vector, modelmatrix*getmodelmatrix(vectororigin, vec3(1))*rotation_mat);
}