using GLWindow, GLUtil, ModernGL, ImmutableArrays, GLFW, React, Images

framebuffdims = [1000,1000]
window = createwindow("Mesh Display", framebuffdims..., debugging = false)
cam = Cam(window.inputs, Vector3(1.5f0, 1.5f0, 1.0f0))

shaderdir = Pkg.dir()*"/GLPlot/src/shader/"


shader              = GLProgram(shaderdir*"simple.vert", shaderdir*"mip.frag")
uvwshader           = GLProgram(shaderdir*"uvwposition")


fb = glGenFramebuffers()
#=
lift(windowsize -> begin
    glBindTexture(frontface.texturetype, frontface.id)
    glTexImage(0, frontface.internalformat, windowsize..., 0, frontface.format, frontface.pixeltype, C_NULL)
end, window.inputs[:window_size])
=#


v, uvw, indexes = gencube(1f0, 1f0, 1f0)
cubedata = [
    :vertex         => GLBuffer(v, 3),
    :uvw            => GLBuffer(uvw, 3),
    :indexes        => GLBuffer(indexes, 1, buffertype = GL_ELEMENT_ARRAY_BUFFER),
    :projectionview => cam.projectionview
]


function genuvwcube(x,y,z)
    v, uvw, indexes = gencube(x,y,z)
    cubeobj = RenderObject([
      :vertex         => GLBuffer(v, 3),
      :uvw            => GLBuffer(v, 3),
      :indexes        => indexbuffer(indexes),
      :projectionview => cam.projectionview
    ], uvwshader)

    frontface = Texture(convert(Ptr{Float32}, C_NULL), 3, framebuffdims, GL_RGBA32F, GL_RGBA, (GLenum, GLenum)[])
    backface = Texture(convert(Ptr{Float32}, C_NULL), 3, framebuffdims, GL_RGBA32F, GL_RGBA, (GLenum, GLenum)[])
    rendersetup = () -> begin
        glBindFramebuffer(GL_FRAMEBUFFER, fb)
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, backface.id, 0)
        glClearColor(1,1,1,0)
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

        glDisable(GL_DEPTH_TEST)
        glEnable(GL_CULL_FACE)
        glCullFace(GL_FRONT)
        render(cubeobj.vertexarray)

        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, frontface.id, 0)
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

        glDisable(GL_DEPTH_TEST)
        glEnable(GL_CULL_FACE)
        glCullFace(GL_BACK)
        render(cubeobj.vertexarray)

        glBindFramebuffer(GL_FRAMEBUFFER, 0)
    end

    postrender!(cubeobj, rendersetup)

    cubeobj, frontface, backface

end

cube1,frontf1, backf1 = genuvwcube(1f0, 1f0, 1f0 )
cube2,frontf2, backf2 = genuvwcube(0.5f0, 1f0, 1f0)


delete!(cubedata, :uvw)

volume = float32(imread("C:/Users/Sim/Downloads/danisch.nrrd").data)
volume = map(x-> x >= 0f0 ? x : 0, volume)
max = maximum(volume)
min = minimum(volume)

volume = (volume .- min) ./ (max .- min)

cubedata[:frontface1]    = frontf1
cubedata[:backface1]     = backf1
cubedata[:backface2]     = backf2
cubedata[:frontface2]     = frontf2

cubedata[:volume_tex]   = Texture(volume, 1)
cubedata[:stepsize]     = 0.001f0
cube = RenderObject(cubedata, shader)
prerender!(cube, glDisable, GL_DEPTH_TEST, glEnable, GL_CULL_FACE, glCullFace, GL_BACK)
postrender!(cube, render, cube.vertexarray)

glClearColor(1,1,1,1)
glClearDepth(1)

while !GLFW.WindowShouldClose(window.glfwWindow)

    render(cube1)
    render(cube2)
    glClearColor(1,1,1,1)
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    enabletransparency()
    render(cube)

    GLFW.SwapBuffers(window.glfwWindow)
    GLFW.PollEvents()
    sleep(0.01)
end
GLFW.Terminate()
