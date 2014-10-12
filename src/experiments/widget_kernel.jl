using ModernGL, GLAbstraction, GLWindow, GLFW, Reactive, ImmutableArrays, Images, GLText, Quaternions, Color, FixedPointNumbers, ApproxFun
using GLPlot

windowhints = [
  (GLFW.SAMPLES, 0), 
  (GLFW.DEPTH_BITS, 0), 
  (GLFW.ALPHA_BITS, 0), 
  (GLFW.STENCIL_BITS, 0),
  (GLFW.AUX_BUFFERS, 0)
]
immutable GLGlyph{T <: Real} <: AbstractVector{T}
  glyph::T
end


immutable Style{StyleValue}
end
window  = createdisplay(w=1920, h=1080, windowhints=windowhints)

mousepos = window.inputs[:mouseposition]

color_mousepos = lift(mousepos) do xy 
  if isinside(Rectangle(0f0,0f0,200f0,200f0), xy[1], xy[2])
    return Vec2(xy...)
  else
    Vec2(-1f0)
  end
end

mousepos_cam = lift(mousepos) do xy 
  if !isinside(Rectangle(0f0,0f0,200f0,200f0), xy[1], xy[2])
    return xy
  else
    Vector2(0.0)
  end
end

cam_inputs    = [
:mouseposition        => mousepos_cam,
:mousebuttonspressed  => window.inputs[:mousebuttonspressed],
:buttonspressed       => window.inputs[:buttonspressed],
:window_size          => window.inputs[:window_size],
:scroll_y             => window.inputs[:scroll_y]
]

color_inputs  = merge(window.inputs, [:mouseposition => color_mousepos, :scroll_y => Input(0f0), :scroll_x => Input(0f0)])

cam     = PerspectiveCamera(cam_inputs, Vec3(1,1,1), Vec3(0))
pcamera = OrthographicPixelCamera(window.inputs)

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

selectiondata = Input(Vector2{GLushort}[Vector2{GLushort}(0,0)])




#GLPlot.toopengl{T <: AbstractRGB}(colorinput::Input{T}) = toopengl(lift(x->AlphaColorValue(x, one(T)), RGBA{T}, colorinput))
tohsv(rgba)     = AlphaColorValue(convert(HSV, rgba.c), rgba.alpha)
torgb(hsva)     = AlphaColorValue(convert(RGB, hsva.c), hsva.alpha)
tohsv(h,s,v,a)  = AlphaColorValue(HSV(float32(h), float32(s), float32(v)), float32(a))

Base.getindex(collection::GLGlyph, I::Integer) = I == 1 ? collection.glyph : error("Out of bounds")
Base.length{T}(::GLGlyph{T})                   = 1
Base.length{T}(::Type{GLGlyph{T}})             = 1
Base.eltype{T}(::GLGlyph{T})                   = T
Base.eltype{T}(::Type{GLGlyph{T}})             = T
Base.convert{T}(::Type{GLGlyph{T}}, x::Char)   = (int(x) >= 0 && int(x) <= 256) ? GLGlyph(convert(T, x)) : error("This char: ", x, " can't be converted to GLGlyph")

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
GLPlot.toopengl(text::String,                 style=Style(:Default); customization...) = toopengl(style, text, mergedefault!(style, TEXT_DEFAULTS, customization))
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
  renderdata[:projectionview] = pcamera.projectionview
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
  renderdata[:projectionview] = pcamera.projectionview
  shader = TemplateProgram(
    Pkg.dir("GLText", "src", "textShader.vert"), Pkg.dir("GLText", "src", "textShader.frag"), 
    view=view, attributes=renderdata, fragdatalocation=[(0, "fragment_color"),(1, "fragment_groupid")]
  )

  obj = instancedobject(renderdata, shader, length(text))
  obj[:prerender, enabletransparency] = ()

  return obj
end

MATRIX_EDITING_DEFAULTS = [
:Default => [

:backgroundcolor => rgba(0.9, 0.9, 0.9, 1.0),
:camera          => GLPlot.pcamera,
:color           => rgba(0,0,0,1),
:gap             => Vec3(10, 10, 0),
:maxdigits       => 5f0,
:maxlength       => 10f0, 
:model           => eye(Mat4),
:window          => window.inputs

]]

# High Level text rendering for one line or multi line text, which is decided by searching for the occurence of '\n' in text
# Low level text rendering for one line text
# Low level text rendering for multiple line text
edit{T <: AbstractArray}(text::Texture{T, 1, 2}, style=Style(:Default); customization...) = edit(style, text, mergedefault!(style, MATRIX_EDITING_DEFAULTS, customization))

function edit{T <: AbstractArray}(style::Style{:Default}, numbertex::Texture{T, 1, 2}, customization::Dict{Symbol,Any})

  backgroundcolor = customization[:backgroundcolor] 
  camera          = customization[:camera] 
  color           = customization[:color] 
  gap             = customization[:gap] 
  maxdigits       = customization[:maxdigits] 
  maxlength       = customization[:maxlength] 
  model           = customization[:model] 
  _window         = customization[:window] 

  numbers         = data(numbertex) # get data from texture/video memory
  text            = Array(GLGlyph{Uint8}, int(size(numbers,1)*maxdigits), size(numbers, 2))
  offset          = Array(Vec3,    size(text))

  fill!(text, GLGlyph(uint8('X'))) # Fill text array with blanks, as we don't need all of them
  fill!(offset, Vec3(999999f0)) #

  # handle real values 
  Base.stride(x::Real, i)       = 1
  # remove f0 
  makestring(x::Integer)        = string(int(x))
  makestring(x::FloatingPoint)  = string(float64(x))
  makestring{T}(x::Vector1{T})  = string(float64(x[1]))
  makestring{T}(x::Vector1{T}, maxlen) = makestring(float64(x[1]), maxlen)

  makestring(x::Integer, maxlen) = begin
    tmp = string(int(x))
    len = length(tmp)
    if len > maxlen
        tmp = tmp[1:maxlen]
    elseif len < maxlen
      tmp = rpad(tmp, maxlen, " ")
    end
    tmp
  end
  makestring(x::FloatingPoint, maxlen) = begin
    tmp = string(float64(x))
    len = length(tmp)
    if len > maxlen
        tmp = tmp[1:maxlen]
    elseif len < maxlen
      tmp = rpad(tmp, maxlen, "0")
    end
    tmp
  end
  offsetgpu   = Texture(offset)
  textgpu     =  Texture(text)
  customization[:offset] = offsetgpu
  obj         = toopengl(style, textgpu, customization)
  font        = getfont()
  advance     = Vec3(font.props[1][1], 0, 0)
  newline     = Vec3(0, font.props[1][2] + gap[2], 0)

  startposition   = Vec3(0f0)
  positionrunner  = startposition

  maxlength = 5
  for i=1:size(numbers,1)
    for j=1:size(numbers, 2)
      number = numbers[i,j]
      i3 = ((i-1)*maxlength) + 1
      textgpu[i3:i3+maxlength, j:j]   = GLGlyph{Uint8}[GLGlyph(uint8(c)) for c in makestring(number, maxlength)]
      offsetgpu[i3:i3+maxlength, j:j] = Vec3[positionrunner + (advance*(k-1)) for k=1:maxlength]
      positionrunner += newline 
    end
    positionrunner = startposition + i*(advance * maxlength + (gap.*Vec3(2,0,0)))
  end

  # We allocated more space on the gpu then needed (length(numbers)*maxdigits)
  # So we need to update the render method, to render only length(numbers) * maxlength
  obj[:postrender, renderinstanced] = (obj.vertexarray, length(textgpu))

  # We allocated more space on the gpu then needed (length(numbers)*maxdigits)
  # So we need to update the render method, to render only length(numbers) * maxlength
  # ([numbers], zero(eltype(numbers)), -1, -1, -1, Vector2(0.0))
  foldl(([numbers], zero(eltype(numbers)), -1, -1, -1, Vector2(0.0)), window.inputs[:mouseposition], window.inputs[:mousebuttonspressed], selectiondata) do v0, mposition, mbuttons, selection
    numbers0, value0, inumbers0, igpu0, mbutton0, mposition0 = v0

    # if over a number           && nothing selected &&         only           left mousebutton clicked
    if selection[1][1] == obj.id && inumbers0 == -1 && length(mbuttons) == 1 && in(0, mbuttons)
      iorigin   = selection[1][2]
      inumbers  = div(iorigin, maxlength) + 1
      igpu      = int((iorigin - (iorigin%maxlength)) + 1)
      return (numbers0, numbers0[inumbers], inumbers, igpu, 0, mposition)
    end
    # if a number is selected && previous click was left && still only left button ist clicked
    if inumbers0 > 0 && mbutton0 == 0 && length(mbuttons) == 1 && in(0, mbuttons) 
      xdiff                    = mposition[1] - mposition0[1]
      numbers0[inumbers0]      = value0 + (float32(xdiff)/ 50.0f0)
      numbertex[inumbers0]     = Vec1(numbers0[inumbers0][1])
      textgpu[igpu0:maxlength] = GLGlyph{Uint8}[GLGlyph(uint8(c)) for c in makestring(numbers0[inumbers0], maxlength)]

      return (numbers0, value0, inumbers0, igpu0, 0, mposition0)
    end
    return (numbers0, zero(eltype(numbers0)), -1, -1, -1, Vector2(0.0))
  end

  obj
end

 
# Just for fun, lets apply a laplace filter:
kernel = Float32[
-1 -1 -1;
-1 8 -1;
-1 -1 -1]
img = glplot(Texture(Pkg.dir("GLPlot", "docs", "julia.png"), kernel=kernel, filternorm=0.1f0, camera=pcamera)

slider = edit(img[:filterkernel])
glClearColor(1,1,1,1)
const mousehover = Array(Vector2{GLushort}, 1)
lift(x-> glViewport(0,0,x...), window.inputs[:framebuffer_size])


function renderloop()
  glBindFramebuffer(GL_FRAMEBUFFER, fb)
  glDrawBuffers(2, [GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1])
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
  render(img)
  render(slider)

  mousex, mousey = int([window.inputs[:mouseposition].value])
  if mousex > 0 && mousey > 0
    glReadBuffer(GL_COLOR_ATTACHMENT1) 
    glReadPixels(mousex, mousey, 1,1, stencil.format, stencil.pixeltype, mousehover)
    @async push!(selectiondata, mousehover)
  end

  glReadBuffer(GL_COLOR_ATTACHMENT0)
  glBindFramebuffer(GL_READ_FRAMEBUFFER, fb)
  glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0)
  glClear(GL_COLOR_BUFFER_BIT)

  window_size = window.inputs[:framebuffer_size].value
  glBlitFramebuffer(0,0, window_size..., 0,0, window_size..., GL_COLOR_BUFFER_BIT, GL_NEAREST)
end



while !GLFW.WindowShouldClose(window.glfwWindow)
  yield() # this is needed for react to work
  renderloop()
  yield()

  GLFW.SwapBuffers(window.glfwWindow)
  GLFW.PollEvents()
end
GLFW.Terminate()
