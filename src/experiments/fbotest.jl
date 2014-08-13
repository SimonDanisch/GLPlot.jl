using ModernGL, GLAbstraction, GLWindow, GLFW, React, ImmutableArrays, Images, GLText, Quaternions
using GLPlot
using ProfileView

window  = createwindow("test", 1000, 800, windowhints=[(GLFW.SAMPLES, 0)], debugging=false)
cam     = PerspectiveCamera(window.inputs, Vec3(1,0,0), Vec3(0))
cam2    = OrthographicCamera(window.inputs)
initplotting()
sourcedir = Pkg.dir()*"/GLPlot/src/"
shaderdir = sourcedir*"shader/"

function setup(color )
  toopengl("asdljasdlkjaskldjaksd")
end

fb = glGenFramebuffers()
glBindFramebuffer(GL_FRAMEBUFFER, fb)

parameters = [
        (GL_TEXTURE_WRAP_S,  GL_CLAMP_TO_EDGE),
        (GL_TEXTURE_WRAP_T,  GL_CLAMP_TO_EDGE),
        (GL_TEXTURE_MIN_FILTER, GL_NEAREST),
        (GL_TEXTURE_MAG_FILTER, GL_NEAREST)
    ]
color   = Texture(GLfloat, 3, window.inputs[:window_size].value, format=GL_RGB, internalformat=GL_RGB8)
stencil = Texture(GLushort, 2, window.inputs[:window_size].value, format=GL_RG_INTEGER, internalformat=GL_RG16UI, parameters=parameters)
glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, color.id, 0)
glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT1, GL_TEXTURE_2D, stencil.id, 0)

rboDepthStencil = GLuint[0]

glGenRenderbuffers(1, rboDepthStencil);
glBindRenderbuffer(GL_RENDERBUFFER, rboDepthStencil[1])
glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24, window.inputs[:window_size].value...)
glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, rboDepthStencil[1])


analyzefb = glGenFramebuffers()
glBindFramebuffer(GL_FRAMEBUFFER, analyzefb)
analyzetex = Texture(GLushort, 1, [3,1], format=GL_RED_INTEGER, internalformat=GL_R16UI, parameters=parameters)
println(analyzetex)
glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, analyzetex.id, 0)




data = [
  :dummy            => GLBuffer(GLfloat[0],1),
  :index            => indexbuffer(GLuint[0]),
  :stencil          => stencil,
  :groups           => int32(2),
  :mouseposition    => lift(x-> Vec2(x...), window.inputs[:mouseposition])
]
glsl_view = [
  "GLSL_EXTENSIONS"     => "#extension GL_ARB_draw_instanced : enable"
]
analyzeRO = instancedobject(data, TemplateProgram(Pkg.dir()*"/GLPlot/src/experiments/stencil_analyze.vert", Pkg.dir()*"/GLPlot/src/experiments/stencil_analyze.frag", view=glsl_view,fragdatalocation=[(0, "fragment_color")]),
  prod(window.inputs[:window_size].value), GL_POINTS)
cubecolor = lift(x-> begin
  data = Vector2{GLushort}[Vector2{GLushort}(convert(GLushort, 0), convert(GLushort, 0)) for i=1:3, j=1:1]
  glBindTexture(GL_TEXTURE_2D, analyzetex.id)
  glGetTexImage(GL_TEXTURE_2D, 0, analyzetex.format, analyzetex.pixeltype, data)
  data[1]
    
end,  window.inputs[:mouseposition])

lift(println, cubecolor)


obj = setup(cubecolor)
obj2 = toopengl(stencil, normrange=Vec2(0,40))




function renderloop()
  glBindFramebuffer(GL_FRAMEBUFFER, fb)
  glDrawBuffers(2, [GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1])
  glClearColor(1,1,1,0)
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
  render(obj)

  glBindFramebuffer(GL_FRAMEBUFFER, analyzefb)
  glDrawBuffer(GL_COLOR_ATTACHMENT0)
  glDisable(GL_DEPTH_TEST)
  glDisable(GL_CULL_FACE)
  glClear(GL_COLOR_BUFFER_BIT)
  glViewport(0,0,3,1)
  render(analyzeRO)

  glBindFramebuffer(GL_FRAMEBUFFER, 0)
  glViewport(0,0,window.inputs[:window_size].value...)

  glClearColor(1,1,1,1)
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
  render(obj2)

end


glClearColor(0,0,0,1)

while !GLFW.WindowShouldClose(window.glfwWindow)

  renderloop()
  yield() # this is needed for react to work
  GLFW.SwapBuffers(window.glfwWindow)
  GLFW.PollEvents()
end
GLFW.Terminate()
