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

cam       = PerspectiveCamera(cam_inputs, Vec3(1,1,1), Vec3(0))
pcamera   = OrthographicPixelCamera(window.inputs)

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


selectiondata = Input(Vector2{GLushort}[Vector2{GLushort}(0,0)])















rgba(r::Real, g::Real, b::Real, a::Real) = AlphaColorValue(RGB{Float32}(r,g,b), float32(a))

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
  :offset           => Vec2(1, 1.5), #Multiplicator for advance, newline
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
function GLGlyph(glyph::Char, ::Type{Uint8})
  if glyph >= 0 && glyph <= 255
      return GLGlyph(uint8(glyph))
  else
    return GLGlyph(uint8(0))
  end
end
function makecompatible(glyph::Char, typ)
  if int(glyph) >= 0 && int(glyph) <= 255
    return convert(typ, glyph)
  else
    return convert(typ, 0)
  end
end

#=
The text needs to be uploaded into a 2D texture, with 1D alignement, as there is no way to vary the row length, which would be a big waste of memory.
This is why there is the need, to prepare offsets information about where exactly new lines reside.
If the string doesn't contain a new line, the text is restricted to one line, which is uploaded into one 1D texture.
This is important for differentiation between multi-line and single line text, which might need different treatment
=#
function GLPlot.toopengl(style::Style{:Default}, text::String, data::Dict{Symbol, Any})
  if contains(text, '\n')
    tab         = 3
    text        = replace(text, "\t", " "^tab) # replace tabs
    tlength     = length(text)
    #Allocate some more memory, to reduce growing the texture residing on VRAM
    texturesize = div(tlength, 1024) # a texture size of 1024 should be supported on every GPU
    offset      = Array(Uint32, texturesize, 1024)
    text1D      = Array(GlGlyph{Uint8}, texturesize, 1024)
    line        = 0
    advance     = 0
    runner      = Vector2(Uint32)
    for (i,elem) in enumerate(text)
      if elem == '\n'
        advance = 0
        line += 1
      else
        advance += 1
      end
      offset[mod1(i, 1024)] = Vector2{Uint32}(line, advance)
      text1D[mod1(i, 1024)] = GLGlyph(elem, Uint8)
    end
    # To make things simple for now, checks if the texture is too big for the GPU are done by Texture and an error gets thrown.
    data[:offset] = Texture(offset)
    return toopengl(style, Texture(text1D), data)
  else
    return toopengl(style, Texture(reinterpret(GLGlyph{Uint8}, convert(Array{Uint8}, text))), data)
  end
end


# This is the low-level text interface, which simply prepares the correct shader and cameras
function GLPlot.toopengl(::Style{:Default}, text::Union(Texture{GLGlyph{Uint8}, 1, 1}, Texture{GLGlyph{Uint8}, 1, 2}), data::Dict{Symbol, Any})
  camera      = data[:camera]
  renderdata  = merge(data, getfont().data) # merge font texture and uv informations -> details @ GLFont/src/types.jl
  view = [
    "GLSL_EXTENSIONS"     => "#extension GL_ARB_draw_instanced : enable"
  ]

  renderdata[:text]           = text
  renderdata[:projectionview] = camera.projectionview
  shader = TemplateProgram(
    Pkg.dir("GLText", "src", "textShader.vert"), Pkg.dir("GLText", "src", "textShader.frag"), 
    view=view, attributes=renderdata, fragdatalocation=[(0, "fragment_color"),(1, "fragment_groupid")]
  )

  obj = instancedobject(renderdata, shader, length(text))
  obj[:prerender, enabletransparency] = ()
  return obj
end


edit{T <: AbstractArray}(text::Texture{T, 1, 2}, style=Style(:Default); customization...) = edit(style, text, mergedefault!(style, MATRIX_EDITING_DEFAULTS, customization))

function edit(style::Style{:Default}, text::Texture{GLGlyph{Uint8}, 1, 2}, selection, pressedkeys)
  testinput = foldl(v00, window.inputs[:unicodeinput], textselection, specialkeys) do v0, unicode_array, selection1, specialkey
    # selection0 tracks, where the carsor is after a new character addition, selection10 tracks the old selection
    text0, selection0, selection10 = v0
    # to compare it to the newly selected mouse position
    if selection10 != selection1
      return (text0, selection1, selection1)
    end
    if !isempty(unicode_array)# else unicode input must have occured
      unicode_char = first(unicode_array)
      text1        = addchar(text0, unicode_char, selection0)

      return (text1, selection0 + 1, selection1)
    elseif in(GLFW.KEY_BACKSPACE, specialkey)
      text1 = delete(text0, selection0)
      return (text1, max(selection0 - 1, 0), selection1)
    end
    return (text0, selection0, selection1)
  end
end

 















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
