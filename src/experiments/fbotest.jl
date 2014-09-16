using ModernGL, GLAbstraction, GLWindow, GLFW, Reactive, ImmutableArrays, Images, GLText, Quaternions
using GLPlot

window  = createdisplay()

cam     = PerspectiveCamera(window.inputs, Vec3(1,0,0), Vec3(0))
cam2    = OrthographicCamera(window.inputs)

sourcedir = Pkg.dir()*"/GLPlot/src/"
shaderdir = sourcedir*"shader/"


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
  Pkg.dir()*"/GLPlot/src/experiments/stencil_analyze.vert", Pkg.dir()*"/GLPlot/src/experiments/stencil_analyze.frag", 
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

clickedselection = foldl((IntSet(), Vector2(-1,-1)), selectiondata, window.inputs[:mousebuttonspressed]) do v0, selection, mousebuttonset
  if !isempty(mousebuttonset) # mousebutton 0==left clicked + and over text
    (mousebuttonset, Vector2(int(selection[1])...))
  else
    v0
  end
end
ocam  = OrthographicCamera(window.inputs[:window_size], Input(1f0), Input(Vec2(0)), Input(Vector2(0.0)))



addchar(s::String, char::Union(String, Char), i::Integer) = addchar(utf8(s), utf8(string(char)), int(i))
function addchar(s::UTF8String, char::UTF8String, i::Integer)
  if i == 0
    return char * s
  elseif i == length(s)
    return s * char
  elseif i > length(s) || i < 0
    return s
  end
  I       = chr2ind(s, i)
  startI  = nextind(s, I)
  return s[1:I] *char* s[startI:end]
end


function GLPlot.toopengl{T <: String}(textinput::Input{T};
          start=Vec3(0), scale=Vec2(1/500), color=Vec4(0,0,1,1), backgroundcolor=Vec4(0), 
          lineheight=Vec3(0,0,0), advance=Vec3(0,0,0), rotation=Quaternion(1f0,0f0,0f0,0f0), textrotation=Quaternion(1f0,0f0,0f0,0f0),
          camera=GLPlot.ocamera
        )
  text          = textinput.value
  font          = getfont()
  fontprops     = font.props[1] .* scale

  if lineheight == Vec3(0)
    newline_dir = -Vec3(0, fontprops[2], 0)
  else
    newline_dir = -lineheight
  end
  if advance == Vec3(0)
    advance_dir = Vec3(fontprops[1], 0,0)
  else
    advance_dir = advance
  end


  offset, ctext   = textwithoffset(text, start, rotation*advance_dir, rotation*newline_dir)

  parameters      = [(GL_TEXTURE_WRAP_S,  GL_CLAMP_TO_EDGE), (GL_TEXTURE_MIN_FILTER, GL_NEAREST)]
  texttex         = Texture(ctext, parameters=parameters)
  offsettex       = Texture(offset, parameters=parameters)
  view = [
    "GLSL_EXTENSIONS"     => "#extension GL_ARB_draw_instanced : enable",
    "offset_calculation"  => "texelFetch(offset, index, 0).rgb;",
  ]
  if !isa(color, Vec4)
    view["color_calculation"] = "texelFetch(color, index, 0);"
    color = Texture(color, parameters=parameters)
  end
  data = merge([
    :index_offset       => convert(GLint, 0),
      :rotation         => Vec4(textrotation.s, textrotation.v1, textrotation.v2, textrotation.v3),
      :text             => texttex,
      :offset           => offsettex,
      :scale            => scale,
      :color            => color,
      :backgroundcolor  => backgroundcolor,
      :projectionview   => camera.projectionview
  ], font.data)


  program = TemplateProgram(
    Pkg.dir()*"/GLText/src/textShader.vert", Pkg.dir()*"/GLText/src/textShader.frag", 
    view=view, attributes=data, fragdatalocation=[(0, "fragment_color"),(1, "fragment_groupid")]
  )
  obj = instancedobject(data, program, length(text))
  prerender!(obj, enabletransparency)
####################################################################

  # selection[1] <- Vector2(ObjectID, Index) for mouseposition

  # Filter events for only the one, when you select text
  textselection = lift(x -> x[2][2], filter((x)-> length(x[1]) == 1 && first(x[1]) == 0 && x[2][1] == obj.id, (IntSet(), Vector2(-1,-1)), clickedselection))

  testinput = foldl((utf8(text), textselection.value, textselection.value), window.inputs[:unicodeinput], textselection) do v0, unicode_char, selection1
    text0, selection0, selection10 = v0
    if selection10 != selection1 # if selection chaned, just update the selection
      (text0, selection1, selection1)
    else # else unicode input must have occured

      text1  = addchar(text0, unicode_char, selection0)
      offset2, ctext2 = textwithoffset(text1, start, rotation*advance_dir, rotation*newline_dir)

      if size(texttex) != size(ctext2)
        gluniform(program.uniformloc[:text]..., texttex)
        glTexImage1D(texturetype(texttex), 0, texttex.internalformat, size(ctext2, 1), 0, texttex.format, texttex.pixeltype, ctext2)
      end
      if size(offsettex) != size(offset2)
        gluniform(program.uniformloc[:offset]..., offsettex)
        glTexImage1D(texturetype(offsettex), 0, offsettex.internalformat, size(offset2, 1), 0, offsettex.format, offsettex.pixeltype, offset2)
      end
      update!(texttex, ctext2)
      update!(offsettex, offset2)
      obj.postRenderFunctions[renderinstanced] = (obj.vertexarray, length(text1))
      (text1, selection0 + 1, selection1)
    end
  end
  obj, lift(x->x[1], testinput)
end

function GLPlot.toopengl{T <: Union(Real, Matrix, ImmutableArrays.ImmutableArray, Vector)}(numberinput::Input{T};
          start=Vec3(0), scale=Vec2(1/500), color=Vec4(0,0,1,1), backgroundcolor=Vec4(0), 
          lineheight=Vec3(0,0,0), advance=Vec3(0,0,0), rotation=Quaternion(1f0,0f0,0f0,0f0), textrotation=Quaternion(1f0,0f0,0f0,0f0),
          camera=GLPlot.ocamera,
          maxlenght=10, maxdigits=5
        )
  numbers = numberinput.value
  Base.stride(x::Real, i) = 1
  resultstring = ""
  linebreak = stride(numbers, 2)
  for (i, elem) in enumerate(numbers)
    tmp = string(elem)
    if length(tmp) > maxdigits
      tmp = tmp[1:maxdigits]
    else
      tmp = rpad(tmp, maxdigits, typeof(elem) <: FloatingPoint ? "0": " ")
    end
    resultstring *= tmp

    if i % linebreak == 0 && i!=length(numbers)
      resultstring *= "\n"
    end
  end
####################################################################
  toopengl(resultstring, start=start, scale=scale, color=color, backgroundcolor=backgroundcolor, 
          lineheight=lineheight, advance=advance, rotation=rotation, textrotation=textrotation,
          camera=camera)
end


obj  = toopengl(Input(eye(Matrix4x4{Int})))
obj2  = toopengl(color, camera=ocam)





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
