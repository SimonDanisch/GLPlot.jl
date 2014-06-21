using GLWindow, GLUtil, ModernGL, Meshes, Events, ImmutableArrays, React, GLFW, Images
export gldisplay, createSampleMesh, createvolume, startplot


global const window = createwindow("Mesh Display", 1000, 1000 )
const cam = Cam(window.inputs, Vector3(1.5f0, 1.5f0, 1.0f0))


const vert = "
#version $(GLWindow.GLSL_VERSION)
in vec3 vertex;
uniform sampler2D ztex;
uniform vec2 texsize;
uniform mat4 projectionview;

void main(){

    float u = float((gl_InstanceID % int(texsize.x))) / texsize.x;
    float v = float((gl_InstanceID / int(texsize.y))) / texsize.y;
    float z = texture(ztex, vec2(u,v));
    gl_Position = projectionview * vec4(vertex + vec3(u, v, z), 1.0);
}

"
const frag = "
#version $(GLWindow.GLSL_VERSION)
out vec4 fragment_color;
void main(){

   fragment_color = vec4(1.0, 0.0, 0.1, 1.0);
}
"
function testrender(x)
    render(x.uniforms)
    glDrawElementsInstanced(GL_POINTS, 1, GL_UNSIGNED_INT, 0, 256*256)
end
texsize = Vector2(256)
const texdata = rand(Float32, texsize...)

const data = RenderObject([
    :vertex         => GLBuffer(Float32[0,0,0], 3),
    :ztex           => Texture(texdata, GL_TEXTURE_2D),
    :texsize        => convert(Vector2{Float32}, texsize),
    :projectionview => cam.projectionview
], GLProgram(vert, frag, "lol"))




gldisplay(:lol, testrender, data)
glClearColor(1,1,1,0)
renderloop(window)