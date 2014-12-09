{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}

{{in}} vec3 vertex;
{{in}} vec3 normal_vector; // normal might not be an uniform, whereas the other will be allways uniforms

uniform vec3 cube_from; 
uniform vec3 cube_to; 
uniform vec2 color_range; 

uniform sampler3D vectorfield;
uniform sampler1D colormap;

uniform mat3 normalmatrix;
uniform mat4 modelmatrix;
uniform mat4 projection, view;

{{out}} vec3 N;
{{out}} vec3 V;
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
mat3 rotation(vec3 direction)
{
    vec3 up = vec3(0,1,0);
    if(direction == up)
    {
        return mat3(1.0);
    }
    vec3 xaxis = normalize(cross(up, direction));
    vec3 yaxis = normalize(cross(direction, xaxis));
    mat3 rotation_mat = mat3(0.0);
    rotation_mat[0] = normalize(direction);
    rotation_mat[2] = normalize(cross(direction, up));
    rotation_mat[1] = normalize(cross(rotation_mat[2], direction));
    return rotation_mat;
}

void main(){
    ivec3 cubesize    = textureSize(vectorfield, 0);
    ivec3 fieldindex  = ivec3(gl_InstanceID / (cubesize.y * cubesize.z), (gl_InstanceID / cubesize.z) % cubesize.y, gl_InstanceID % cubesize.z);
    vec3 uvw          = vec3(fieldindex) / vec3(cubesize);
    vec3 vectororigin = stretch(uvw, cube_from, cube_to);
    vec3 vector       = texelFetch(vectorfield, fieldindex, 0).xyz;
    float vlength     = length(vector);
    mat3 rotation_mat = rotation(vector);


    N           = normalize(normalmatrix * normal_vector);

    vert_color  = texture(colormap, vlength);
    vec3 xyz    = vec3(view * modelmatrix * vec4(((rotation_mat*(vertex*vec3(0.005,0.005,0.05)))+vectororigin), 1));
    V           = xyz;

    gl_Position = projection * vec4(xyz,1);
}