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
    vec3 xaxis = normalize(cross(up, direction));
    vec3 yaxis = normalize(cross(direction, xaxis));
    mat3 rotation_mat;
    rotation_mat[0][0] = xaxis.x;
    rotation_mat[0][1] = yaxis.x;
    rotation_mat[0][2] = direction.x;

    rotation_mat[1][0] = xaxis.y;
    rotation_mat[1][1] = yaxis.y;
    rotation_mat[1][2] = direction.y;

    rotation_mat[2][0] = xaxis.z;
    rotation_mat[2][1] = yaxis.z;
    rotation_mat[2][2] = direction.z;
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

    vert_color  = texture(colormap, stretch(vlength, color_range.x, color_range.y));
    V           = vectororigin + vec3(view * modelmatrix * vec4(rotation_mat * vertex, 1));

    gl_Position = projection * vec4(V,1);
}