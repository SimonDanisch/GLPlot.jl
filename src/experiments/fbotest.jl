using ModernGL, GLAbstraction, GLWindow, GLFW, React, ImmutableArrays, Images
using GLPlot

window  = createwindow("test", 1000, 800, windowhints=[(GLFW.SAMPLES, 0)])
cam     = PerspectiveCamera(window.inputs, Vec3(3.0, 1, 0), Vec3(0.5))
initplotting()

function setup()
  sourcedir = Pkg.dir()*"/GLPlot/src/"
  shaderdir = sourcedir*"shader/"

  shader = TemplateProgram("stencil.vert", "stencil.frag", fragdatalocation=[(0, "fragment_color")])
  const vertexes, uv, normals, indexes = gencubenormals(Vec3(0,0,0), Vec3(1, 0, 0), Vec3(0, 1, 0), Vec3(0,0,1))
  obj = RenderObject([
    :vertex         => GLBuffer(vertexes),
    :index          => indexbuffer(indexes),
    :projection     => cam.projection,
    :view           => cam.view,
  ], shader)

  prerender!(obj, glEnable, GL_DEPTH_TEST)
  postrender!(obj, render, obj.vertexarray)
  obj
end


fb = glGenFramebuffers()
glBindFramebuffer(GL_FRAMEBUFFER, fb)

parameters = [
        (GL_TEXTURE_WRAP_S,  GL_CLAMP_TO_EDGE),
        (GL_TEXTURE_WRAP_T,  GL_CLAMP_TO_EDGE),
        (GL_TEXTURE_MIN_FILTER, GL_NEAREST),
        (GL_TEXTURE_MAG_FILTER, GL_NEAREST)
    ]
#detph   = Texture(GLfloat, 1, window.inputs[:window_size].value, format=GL_DEPTH_COMPONENT, internalformat=GL_DEPTH_COMPONENT32F)
stencil = Texture(GLushort, 1, window.inputs[:window_size].value, format=GL_RED_INTEGER, internalformat=GL_R16UI, parameters=parameters)
glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, stencil.id, 0)

rboDepthStencil = GLuint[0]

glGenRenderbuffers(1, rboDepthStencil);
glBindRenderbuffer(GL_RENDERBUFFER, rboDepthStencil[1])
glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24, window.inputs[:window_size].value...)
glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, rboDepthStencil[1])
println(GLENUM(glCheckFramebufferStatus(GL_FRAMEBUFFER)).name)

obj = setup()
mp = window.inputs[:mouseposition]

function renderloop()
  glBindFramebuffer(GL_FRAMEBUFFER, fb)
  glDrawBuffer(GL_COLOR_ATTACHMENT0) 
  glClearColor(0,0,0,0)
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
  render(obj)
  
  glBindFramebuffer(GL_FRAMEBUFFER, 0)
  glClearColor(1,1,1,1)
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
  render(obj)

end



glClearColor(0,0,0,1)
#@async begin
  while !GLFW.WindowShouldClose(window.glfwWindow)
    renderloop()
    yield() # this is needed for react to work
    sleep(0.1)
    GLFW.SwapBuffers(window.glfwWindow)
    GLFW.PollEvents()
  end
  GLFW.Terminate()
#end
