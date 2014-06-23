using GLWindow, GLUtil, ModernGL, ImmutableArrays, GLFW, React, Images

framebuffdims = [1000,1000]
global const window = createwindow("Mesh Display", framebuffdims..., debugging = false )
const cam = Cam(window.inputs, Vector3(1.5f0, 1.5f0, 1.0f0))

const frontfacevert = "
#version $(GLWindow.GLSL_VERSION)
in vec3 vertex;
in vec3 uvw;
out vec3 frag_uvw;
uniform mat4 projectionview;

void main(){
   frag_uvw = uvw;
   gl_Position = projectionview * vec4(vertex, 1.0);
}

"
const frontfacefrag = "
#version $(GLWindow.GLSL_VERSION)

out vec4 fragment_color;
in vec3 frag_uvw;

void main(){
   fragment_color = vec4(frag_uvw, 1.0);
}
"

const vert = "
#version $(GLWindow.GLSL_VERSION)
in vec3 vertex;
out vec4 vertpos;
out vec3 frag_uvw;
in vec3 uvw;
uniform mat4 projectionview;
void main(){
    frag_uvw = uvw;
   vertpos = projectionview * vec4(vertex, 1.0);
   gl_Position = vertpos;
}

"


global const volumeMIPfrag = "
#version $(GLWindow.GLSL_VERSION)

uniform sampler2D frontface;
uniform sampler3D volume_tex;

uniform float stepsize;

in vec4 vertpos;
in vec3 frag_uvw;

out vec4 fragment_color;

void main()
{
    vec2 texc           = ((vertpos.xy / vertpos.w) + 1) / 2;
    vec3 back           = vec3(texture(frontface, texc));
    vec3 dir            = vec3(back - frag_uvw);
    float lengthdir     = length(dir);
    vec3  normed_dir    = normalize(dir) * stepsize;
    vec4  colorsample   = vec4(0.0);
    float alphasample   = 0.0;
    vec4  coloraccu     = vec4(0.0);
    float alphaaccu     = 0.0;
    vec3  start         = frag_uvw;
    float maximum       = 0;
    float alpha_acc     = 0.0;  
    float length_acc    = 0.0;  
    float alpha_sample; 
    int i = 0;
    for(i; i < 10000; i++)
    {
        colorsample = texture(volume_tex, start);
        
        if(colorsample.r > coloraccu.r)
        {
          coloraccu = vec4(colorsample.r,colorsample.r,colorsample.r, 1);
        }
        start += normed_dir;
        length_acc += length(normed_dir);
        if(coloraccu.r >= 0.999 || length_acc >= lengthdir)
        {
           break;
        }
    }
    float r = smoothstep(0.3, 0.8, coloraccu.r);
    float g = smoothstep(0.6, 1.0, coloraccu.r);
    float b = smoothstep(0.0, 1.0, coloraccu.r);
    float a = smoothstep(0.01, 1.0, coloraccu.r);
    fragment_color = vec4(coloraccu.r, coloraccu.r, coloraccu.r, a);
}
"

const vert2 = "
#version $(GLWindow.GLSL_VERSION)
in vec3 vertex;
uniform mat4 projectionview;
out vec3 frag_uvw;
void main(){
   frag_uvw = vertex / vec3(1, 1.4, 1.9);
   gl_Position = projectionview * vec4(vertex, 1.0);
}

"
const frag2 = "
#version $(GLWindow.GLSL_VERSION)
in vec3 frag_uvw;
out vec4 fragment_color;

void main(){
   fragment_color = vec4(frag_uvw, 1.0);
}
"
const frontfaceshader = GLProgram(frontfacevert, frontfacefrag, "frontface")
const shader2 = GLProgram(vert2, frag2, "normal")

fb = glGenFramebuffers()
glBindFramebuffer(GL_FRAMEBUFFER, fb)
frontFace = Texture(convert(Ptr{Float32}, C_NULL), 4, framebuffdims, internalformat = GL_RGBA8, format=GL_RGBA)

glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, frontFace.id, 0)
println(GLENUM(glCheckFramebufferStatus(GL_FRAMEBUFFER)))

glBindFramebuffer(GL_FRAMEBUFFER, 0)


const shader = GLProgram(vert, volumeMIPfrag, "volume")
const frontfaceshader = GLProgram(frontfacevert, frontfacefrag, "frontface")

volume      = imread("../example/danisch.nrrd")
println(size(volume))
x,y,z       = volume.properties["pixelspacing"]
pspacing    = [float64(x), float64(y), float64(z)]
volume      = map(x-> x < 0 ? 0 : x, volume.data)
max         = maximum(volume)
min         = minimum(volume)
volume      = float32((volume .- min) ./ (max - min))
spacing     = float32(pspacing .* Float64[size(volume)...] * 2000.0)


#v, uvw, indexes = gencube(spacing...)
v, uvw, indexes = gencube(1f0, 1f0, 1f0)
cubedata = [
    :vertex         => GLBuffer(v, 3),
    :uvw            => GLBuffer(uvw, 3),
    :indexes        => GLBuffer(indexes, 1, bufferType = GL_ELEMENT_ARRAY_BUFFER),
    :projectionview => cam.projectionview,
]


cubeFrontfaced = RenderObject(cubedata, frontfaceshader)
prerender!(cubeFrontfaced, glEnable, GL_CULL_FACE, glCullFace, GL_FRONT)



cubedata[:frontface]    = frontFace
cubedata[:volume_tex]   = Texture(convert(Ptr{Float32}, pointer(volume)), 1, [size(volume)...])
cubedata[:stepsize]     = 0.001f0
cube = RenderObject(cubedata, shader)
prerender!(cube, glEnable, GL_CULL_FACE, glCullFace, GL_BACK)


v, uv,indexes = genquad(Vector3(-1f0,-1f0,0f0), Vector3(2f0,2f0,0f0), Vector3(0f0,2f0,2f0))
plane = RenderObject(
    [
        :vertex         => GLBuffer(v, 3),
        :indexes        => GLBuffer(indexes, 1, bufferType = GL_ELEMENT_ARRAY_BUFFER),
        :projectionview => cam.projectionview
    ]
    , shader2)

glClearColor(0,0,0,0)

while !GLFW.WindowShouldClose(window.glfwWindow)
    glBindFramebuffer(GL_FRAMEBUFFER, fb)
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

    render(cubeFrontfaced)
    glEnable(GL_DEPTH_TEST)
    render(plane)

    glBindFramebuffer(GL_FRAMEBUFFER, 0)

    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    render(cube)

    GLFW.SwapBuffers(window.glfwWindow)
    GLFW.PollEvents()
end
GLFW.Terminate()