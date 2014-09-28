using ModernGL, GLAbstraction, GLWindow, GLFW, Reactive, ImmutableArrays, Images, GLText, Quaternions, Color, FixedPointNumbers
using GLPlot
windowhints =[
  (GLFW.SAMPLES, 0), 
  (GLFW.DEPTH_BITS, 0), 
  (GLFW.ALPHA_BITS, 0), 
  (GLFW.STENCIL_BITS, 0),
  (GLFW.AUX_BUFFERS, 0)
]
window  = createdisplay(w=1920, h=1080, windowhints=windowhints, debugging=false)
cam     = PerspectiveCamera(window.inputs, Vec3(1,0,0), Vec3(0))
ocam    = OrthographicCamera(window.inputs[:window_size], Input(1f0), Input(Vec2(0)), Input(Vector2(1.0)))
ocam2   = OrthographicPixelCamera(window.inputs)

sourcedir = Pkg.dir("GLPlot", "src", "experiments")
shaderdir = sourcedir


include("glwidgets.jl")


fb = glGenFramebuffers()
glBindFramebuffer(GL_FRAMEBUFFER, fb)
parameters = [
        (GL_TEXTURE_WRAP_S,  GL_CLAMP_TO_EDGE),
        (GL_TEXTURE_WRAP_T,  GL_CLAMP_TO_EDGE),
        (GL_TEXTURE_MIN_FILTER, GL_NEAREST),
        (GL_TEXTURE_MAG_FILTER, GL_NEAREST)
    ]


framebuffsize = [window.inputs[:framebuffer_size].value]

color     = Texture(RGBA{Ufixed8}, framebuffsize, parameters=parameters)
stencil   = Texture(Vector2{GLushort}, framebuffsize, parameters=parameters)

glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, color.id, 0)
glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT1, GL_TEXTURE_2D, stencil.id, 0)

rboDepthStencil = GLuint[0]

glGenRenderbuffers(1, rboDepthStencil)
glBindRenderbuffer(GL_RENDERBUFFER, rboDepthStencil[1])
glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24, framebuffsize...)
glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, rboDepthStencil[1])

lift(window.inputs[:framebuffer_size]) do window_size
  resize!(color, window_size)
  resize!(stencil, window_size)
  glBindRenderbuffer(GL_RENDERBUFFER, rboDepthStencil[1])
  glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24, window_size...)
end


mousepos = lift(x-> Vec2(x...), window.inputs[:mouseposition])

selectiondata = Input(Vector2{GLushort}[Vector2{GLushort}(zero(GLushort), zero(GLushort))])
#lift(println, selectiondata)
clickedselection = foldl((IntSet(),  Vector2(-1,-1)), selectiondata, window.inputs[:mousebuttonspressed]) do v0, selection, mousebuttonset
  if !isempty(mousebuttonset) # mousebutton 0==left clicked + and over text
    (mousebuttonset, Vector2(int(selection[1])...))
  else
    v0
  end
end

function GLPlot.toopengl(dict::Dict{Symbol, Any})
  result = RenderObject[]
  translate = Vec3(0f0)
  labels = ""
  for (key, value) in dict
    labels *= string(key) * ": \n"

    push!(result, toopengl(value, camera=ocam2))
    
    last(result)[:model] = translationmatrix(translate) * scalematrix(Vec3(700f0, 700f0, 1))
    translate += Vec3(0,-200f0,0)
  end
  push!(result, toopengl(labels, scale=Vec2(1f0), camera=ocam2))
end

testdict = [
  :loley  => Input(AlphaColorValue(RGB(1f0,0f0,0f0), 1f0)),
  :trol   => Input("trololol, lolol, lololoool"),
  :ruufl  => Input(eye(Mat4)),
]

obj     = toopengl(testdict)


glClearColor(1,1,1,1)
const mousehover = Array(Vector2{GLushort},1)
function renderloop()
  window_size = window.inputs[:framebuffer_size].value
  glViewport(0,0, window_size...)
  glBindFramebuffer(GL_FRAMEBUFFER, fb)
  glDrawBuffers(2, [GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1])
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
  render(obj)

  mousex, mousey = int([window.inputs[:mouseposition].value])
  glReadBuffer(GL_COLOR_ATTACHMENT1)
  glReadPixels(mousex, mousey, 1,1, stencil.format, stencil.pixeltype, mousehover)
  @async push!(selectiondata, mousehover)

  glReadBuffer(GL_COLOR_ATTACHMENT0)
  glBindFramebuffer(GL_READ_FRAMEBUFFER, fb)
  glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0)
  glClear(GL_COLOR_BUFFER_BIT)
  glBlitFramebuffer(0,0, window_size..., 0, 0, window_size..., GL_COLOR_BUFFER_BIT, GL_NEAREST)
end



while !GLFW.WindowShouldClose(window.glfwWindow)
  yield() # this is needed for react to work

  renderloop()

  GLFW.SwapBuffers(window.glfwWindow)
  GLFW.PollEvents()
end
GLFW.Terminate()
