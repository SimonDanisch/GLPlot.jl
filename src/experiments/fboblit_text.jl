using ModernGL, GLAbstraction, GLWindow, GLFW, Reactive, ImmutableArrays, Images, GLText, Quaternions, Color, FixedPointNumbers
using GLPlot

windowhints = [
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
parameters = [
        (GL_TEXTURE_WRAP_S,  GL_CLAMP_TO_EDGE),
        (GL_TEXTURE_WRAP_T,  GL_CLAMP_TO_EDGE ),

        (GL_TEXTURE_MIN_FILTER, GL_NEAREST),
        (GL_TEXTURE_MAG_FILTER, GL_NEAREST) 
]

fb = glGenFramebuffers()
glBindFramebuffer(GL_FRAMEBUFFER, fb)

framebuffsize = [window.inputs[:framebuffer_size].value]
println(framebuffsize)
color     = Texture(RGBA{Ufixed8},     framebuffsize, parameters=parameters)
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
rgba(r::Real, g::Real, b::Real, a::Real) = AlphaColorValue(RGB{Float32}(r,g,b), float32(a))
immutable GLGlyph{T <: Real} <: AbstractVector{T}
  glyph::T
end
Base.getindex(collection::GLGlyph, I::Integer) = I == 1 ? collection.glyph : error("Out of bounds")
Base.length{T}(::GLGlyph{T})                   = 1
Base.length{T}(::Type{GLGlyph{T}})             = 1
Base.eltype{T}(::GLGlyph{T})                   = T
Base.eltype{T}(::Type{GLGlyph{T}})             = T
Base.convert{T}(::Type{GLGlyph{T}}, x::Char)   = (int(x) >= 0 && int(x) <= 256) ? GLGlyph(convert(T, x)) : error("This char: ", x, " can't be converted to GLGlyph")


immutable Style{StyleValue}
end
Style(x::Symbol) = Style{x}()
mergedefault!{S}(style::Style{S}, styles, customdata) = merge!(Dict{Symbol, Any}(customdata), styles[S])

#################################################################################################################################
#Text Rendering:
TEXT_DEFAULTS = [
:Default => [
  :start            => Vec3(0),
  :offset           => Mat3x2(Vec3(getfont().props[1][1], 0, 0), Vec3(0, getfont().props[1][2], 0)), #Font advance + newline
  :color            => rgba(0,0,0,1),
  :backgroundcolor  => rgba(0,0,0,0),
  :model            => eye(Mat4),
]
]
# High Level text rendering for one line or multi line text, which is decided by searching for the occurence of '\n' in text
GLPlot.toopengl(text::String, style=Style(:Default); customization...)                 = toopengl(style, text, mergedefault!(style, TEXT_DEFAULTS, customization))
# Low level text rendering for one line text
GLPlot.toopengl(text::Texture{GLGlyph, 1, 1}, style=Style(:Default); customization...) = toopengl(style, text, mergedefault!(style, TEXT_DEFAULTS, customization))
# Low level text rendering for multiple line text
GLPlot.toopengl(text::Texture{GLGlyph, 1, 2}, style=Style(:Default); customization...) = toopengl(style, text, mergedefault!(style, TEXT_DEFAULTS, customization))

# END Text Rendering
#################################################################################################################################


#include("renderfunctions.jl")

function makecompatible(glyph::Char, typ)
  if int(glyph) >= 0 && int(glyph) <= 255
    return convert(typ, glyph)
  else
    return convert(typ, 0)
  end
end


# Returns either 1D or 2D array, with elements converted to elementtype
function glsplit(text::String, ElemType::DataType)
  splitted      = split(text, "\n")
  maxlinelength = reduce(0, splitted) do v0, x
       max(length(x), v0)
  end
  dimensions = Int[maxlinelength]
  # If more than one line, or there is a newline in the end, make array 2D
  if length(splitted) == 1 || isempty(rsearch(text, "\n"))
    return ElemType[makecompatible(x, ElemType) for x in first(splitted)]
  else
    result = Array(ElemType, length(splitted), maxlinelength)
    fill!(result, convert(ElemType, ' '))
    for (i, line) in enumerate(splitted)
      result[i,1:length(line)] = ElemType[makecompatible(x, ElemType) for x in line]
    end
    return result
  end
end


function GLPlot.toopengl(s::Style{:Default}, text::String, data::Dict{Symbol, Any})
  textarray = glsplit(text, GLGlyph{Uint8})
  toopengl(s, Texture(textarray), data)
end

# Text rendering for one line text
function GLPlot.toopengl(::Style{:Default}, text::Texture{GLGlyph{Uint8}, 1, 1}, data::Dict{Symbol, Any})
  renderdata  = merge(data, getfont().data)

  view = [
    "GLSL_EXTENSIONS"     => "#extension GL_ARB_draw_instanced : enable"
  ]

  renderdata[:text]           = text
  renderdata[:projectionview] = ocam2.projectionview
  shader = TemplateProgram(
    Pkg.dir("GLText", "src", "textShader.vert"), Pkg.dir("GLText", "src", "textShader.frag"), 
    view=view, attributes=renderdata, fragdatalocation=[(0, "fragment_color"),(1, "fragment_groupid")]
  )

  obj = instancedobject(renderdata, shader, length(text))
  obj[:prerender, enabletransparency] = ()
  return obj
end
# Text rendering for multiple line text
function GLPlot.toopengl(::Style{:Default}, text::Texture{GLGlyph{Uint8}, 1, 2}, data::Dict{Symbol, Any})
  renderdata  = merge(data, getfont().data)

  view = [
    "GLSL_EXTENSIONS"     => "#extension GL_ARB_draw_instanced : enable"
  ]

  renderdata[:text]           = text
  renderdata[:projectionview] = ocam2.projectionview
  shader = TemplateProgram(
    Pkg.dir("GLText", "src", "textShader.vert"), Pkg.dir("GLText", "src", "textShader.frag"), 
    view=view, attributes=renderdata, fragdatalocation=[(0, "fragment_color"),(1, "fragment_groupid")]
  )

  obj = instancedobject(renderdata, shader, length(text))
  obj[:prerender, enabletransparency] = ()

  return obj
end


obj = toopengl(readall(open("fboblit_text.jl")))


function make_editible(text::Texture{GLGlyph{Uint8}, 1, 2}, selection, pressedkeys)
    testinput = foldl(v00, window.inputs[:unicodeinput], textselection, specialkeys) do v0, unicode_array, selection1, specialkey
    # selection0 tracks, where the carsor is after a new character addition, selection10 tracks the old selection
    text0, selection0, selection10 = v0
    # to compare it to the newly selected mouse position
    if selection10 != selection1
      return (text0, selection1, selection1)
    end
    if !isempty(unicode_array)# else unicode input must have occured
      unicode_char = first(unicode_array)

      text1  = addchar(text0, unicode_char, selection0)

      updatetext(text1, start, rotation, advance_dir, newline_dir, obj)

      return (text1, selection0 + 1, selection1)
    elseif in(GLFW.KEY_BACKSPACE, specialkey)
      text1 = delete(text0, selection0)
      updatetext(text1, start, rotation, advance_dir, newline_dir, obj)
      return (text1, max(selection0 - 1, 0), selection1)
    end
    return (text0, selection0, selection1)
  end
end

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
  println(mousehover[1][2])
  #@async push!(selectiondata, mousehover)

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
