{{GLSL_VERSION}}

{{in}} vec3 vertex;
{{in}} vec3 normal;
{{in}} vec2 uv;

// data for fragment shader
{{out}} vec3 o_normal;
{{out}} vec3 o_toLight;
{{out}} vec3 o_toCamera;
{{out}} vec2 o_texcoords;

uniform mat4 projection, view, model;
uniform mat3 normalmatrix;
uniform vec3 light[4];
uniform vec3 camera_position;


const int position = 3;

void main(){

    vec4 worldPosition  = model * vec4(vertex, 1);

    // normal in world space
    o_normal = normalize(normalmatrix * normal);

    // direction to light
    o_toLight    = normalize(light[position] - worldPosition.xyz);

    // direction to camera
    o_toCamera   = normalize(camera_position - worldPosition.xyz);

    // texture coordinates to fragment shader
    o_texcoords  = uv;

    // screen space coordinates of the vertex
    gl_Position  = projection * view * worldPosition;
}