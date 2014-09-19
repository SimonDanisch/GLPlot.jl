using ModernGL, GLAbstraction, GLWindow, GLFW, Reactive, ImmutableArrays, Images, GLText, Quaternions, Color
using GLPlot

window  = createdisplay()

cam     = PerspectiveCamera(window.inputs, Vec3(1,0,0), Vec3(0))
cam2    = OrthographicCamera(window.inputs)

sourcedir = Pkg.dir("GLPlot", "src", "experiments")
shaderdir = Pkg.dir("GLPlot", "src", "experiments")
println(sourcedir)
fb = glGenFramebuffers()
glBindFramebuffer(GL_FRAMEBUFFER, fb)

parameters = [
        (GL_TEXTURE_WRAP_S,  GL_CLAMP_TO_EDGE),
        (GL_TEXTURE_WRAP_T,  GL_CLAMP_TO_EDGE),
        (GL_TEXTURE_MIN_FILTER, GL_NEAREST),
        (GL_TEXTURE_MAG_FILTER, GL_NEAREST)
    ]
color     = Texture(GLfloat, 4, window.inputs[:window_size].value[3:4], format=GL_RGBA, internalformat=GL_RGBA8)
stencil   = Texture(GLushort, 2, window.inputs[:window_size].value[3:4], format=GL_RG_INTEGER, internalformat=GL_RG16UI, parameters=parameters)
glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, color.id, 0)
glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT1, GL_TEXTURE_2D, stencil.id, 0)

rboDepthStencil = GLuint[0]

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
ocam  = OrthographicCamera(window.inputs[:window_size], Input(1f0), Input(Vec2(0)), Input(Vector2(0.0)))




defaultsliderticks(x::FloatingPoint) = x/10.0
defaultsliderticks(x::Integer) = div(x,10) == 0 ? 1 : div(x,10)

function GLPlot.toopengl{T <: Union(Real, Matrix, ImmutableArrays.ImmutableArray, Vector)}(numberinput::Input{T};
          start=Vec3(0), scale=Vec2(1/500), color=Vec4(0,0,1,1), backgroundcolor=Vec4(0), 
          lineheight=Vec3(0,0,0), advance=Vec3(0,0,0), rotation=Quaternion(1f0,0f0,0f0,0f0), textrotation=Quaternion(1f0,0f0,0f0,0f0),
          camera=GLPlot.ocamera,
          maxlenght=10, maxdigits=5
        )
  # handle real values 
  Base.stride(x::Real, i) = 1
  # remove f0
  makestring(x::Integer)        = string(int(x))
  makestring(x::FloatingPoint)  = string(float64(x))

  numbers = numberinput.value
  resultstring = ""
  linebreak = stride(numbers, 2)
  maxlength = 0
  for (i, elem) in enumerate(numbers)
    tmp = makestring(elem)
    len = length(tmp)
    maxlength = maxlength > len ? maxlength : len

    if len > maxdigits
      tmp = tmp[1:maxdigits]
    end
    resultstring *= tmp
    if i % linebreak == 0 && i!=length(numbers)
      resultstring *= "\n"
    end
  end
####################################################################
  obj = toopengl(resultstring, start=start, scale=scale, color=color, backgroundcolor=backgroundcolor, 
          lineheight=lineheight, advance=advance, rotation=rotation, textrotation=textrotation,
          camera=camera)

  textgpu   = obj[:text]
  offsetgpu = obj[:offset]
  textgpu[1:end, 1:end] = 0
  offsetgpu[1:end, 1:end] = Vec3(0)

  #=
  testinput = lift(window.inputs[:scroll_y], selectiondata) do scroll, selection
    text0, selection0, selection10 = v0

  	update!(textgpu, ctext2)
  	obj.postRenderFunctions[renderinstanced] = (obj.vertexarray, length(text1))
	(text1, selection0 + 1, selection1)
  end
  =#
  obj
end






obj  	= toopengl(Input(Vector3(float32(8))))
obj2  = toopengl(color,camera=ocam)





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
  glViewport(0,0,window.inputs[:window_size].value[3:4]...)

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
