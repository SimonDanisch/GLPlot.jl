using ModernGL, GLAbstraction, GLWindow, GLFW, Reactive, ImmutableArrays, Images, GLText, Quaternions, Color
using GLPlot

window  = createdisplay(w=1920, h=1080)
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
color     = Texture(GLfloat, 4, window.inputs[:window_size].value[3:4], format=GL_RGBA, internalformat=GL_RGBA8)
stencil   = Texture(GLushort, 2, div(window.inputs[:window_size].value[3:4], 4), format=GL_RG_INTEGER, internalformat=GL_RG16UI, parameters=parameters)
glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, color.id, 0)
glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT1, GL_TEXTURE_2D, stencil.id, 0)

rboDepthStencil = GLuint[0]
OrthographicPixelCamera
glGenRenderbuffers(1, rboDepthStencil);
glBindRenderbuffer(GL_RENDERBUFFER, rboDepthStencil[1])
glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24, window.inputs[:window_size].value[3:4]...)
glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, rboDepthStencil[1])

group_amount = Input(int32(2))

analyzefb = glGenFramebuffers()
glBindFramebuffer(GL_FRAMEBUFFER, analyzefb)
analyzetex = Texture(GLushort, 2, [group_amount.value+1, 1], format=GL_RG_INTEGER, internalformat=GL_RG16UI, parameters=parameters)
glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, analyzetex.id, 0)


mousepos = lift(x-> Vec2(x...), window.inputs[:mouseposition])

data = [
  :dummy            => GLBuffer(GLfloat[0],1),
  :index            => indexbuffer(GLuint[0]),
  :stencil          => stencil,
  :groups           => group_amount,
  :mouseposition    => mousepos
]
glsl_view = [
  "GLSL_EXTENSIONS"     => "#extension GL_ARB_draw_instanced : enable"
]

analyzeshader = TemplateProgram(
  joinpath(shaderdir, "stencil_analyze.vert"), joinpath(shaderdir, "stencil_analyze.frag"), 
  view=glsl_view,fragdatalocation=[(0, "fragment_color")]
)
analyzeRO = instancedobject(data, analyzeshader, prod(window.inputs[:window_size].value[3:4]), GL_POINTS)


const framebufferdata = lift(group_amount) do x
  [Vector2{GLushort}(zero(GLushort), zero(GLushort)) for i=1:x+1, j=1:1]
end

selectiondata = lift(window.inputs[:mouseposition], framebufferdata) do x, data
    glBindTexture(GL_TEXTURE_2D, analyzetex.id)
    glGetTexImage(GL_TEXTURE_2D, 0, analyzetex.format, analyzetex.pixeltype, data)
    data
end

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
    
    last(result)[:model] = translationmatrix(translate) * scalematrix(Vec3(200f0, 200f0, 1))
    translate += Vec3(0,10f0,0)
  end
  push!(result, toopengl(labels, scale=Vec2(1f0), camera=ocam2))
end

testdict = [
  :loley  => Input(AlphaColorValue(RGB(1f0,0f0,0f0), 1f0)),
  :trol   => Input("trololol, lolol, lololoool"),
  :ruufl  => Input(eye(Matrix4x4{Float32})),
]

obj     = toopengl(testdict)
obj2    = toopengl(color, camera=ocam)





function renderloop()

  glBindFramebuffer(GL_FRAMEBUFFER, fb)
  glDrawBuffers(2, [GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1])
  glClearColor(0,0,0,0)
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
  render(obj)

  glBindFramebuffer(GL_FRAMEBUFFER, analyzefb)
  glDrawBuffer(GL_COLOR_ATTACHMENT0)
  glDisable(GL_DEPTH_TEST)
  glDisable(GL_CULL_FACE)
  glClear(GL_COLOR_BUFFER_BIT)
  glViewport(0, 0, group_amount.value, 1)
  render(analyzeRO)

  glBindFramebuffer(GL_FRAMEBUFFER, 0)
  glViewport(0,0, window.inputs[:window_size].value[3:4]...)

  glClearColor(1,1,1,1)
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
  render(obj2)

end


glClearColor(0,0,0,1)

const query = GLuint[1]
const elapsed_time = GLuint64[1]
const done = GLint[0]

while !GLFW.WindowShouldClose(window.glfwWindow)
  yield() # this is needed for react to work
  glGenQueries(1, query)
  glBeginQuery(GL_TIME_ELAPSED, query[1])
    renderloop()
  glEndQuery(GL_TIME_ELAPSED)
  while (done[1] != 1)
    glGetQueryObjectiv(query[1],
            GL_QUERY_RESULT_AVAILABLE,
            done)
  end 
  glGetQueryObjectui64v(query[1], GL_QUERY_RESULT, elapsed_time)
  println("Time Elapsed: ", elapsed_time[1] / 1000000.0, "ms")
  GLFW.SwapBuffers(window.glfwWindow)
  GLFW.PollEvents()
end
GLFW.Terminate()
