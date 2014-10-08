using ModernGL, GLAbstraction, GLWindow, GLFW, Reactive, ImmutableArrays, Images, GLText, Quaternions, Color, FixedPointNumbers, ApproxFun
using GLPlot, HTTPClient


immutable GLGlyph{T} <: TextureCompatible
  glyph::T
  line::T
  row::T
  style_index::T

end
function GLGlyph(glyph::Integer, line::Integer, row::Integer, style_index::Integer)
  if !isascii(char(glyph))
    glyph = char('1')
  end
  GLGlyph{Uint16}(uint16(glyph), uint16(line), uint16(row), uint16(style_index))
end
function GLGlyph(glyph::Char, line::Integer, row::Integer, style_index::Integer)
  if !isascii(glyph)
    glyph = char('1')
  end
  GLGlyph{Uint16}(uint16(glyph), uint16(line), uint16(row), uint16(style_index))
end
GLGlyph() = GLGlyph(' ', typemax(Uint16), typemax(Uint16), 0)

immutable Style{StyleValue}
end

window  = createdisplay(w=1920, h=1080, windowhints=[
  (GLFW.SAMPLES, 0), 
  (GLFW.DEPTH_BITS, 0), 
  (GLFW.ALPHA_BITS, 0), 
  (GLFW.STENCIL_BITS, 0),
  (GLFW.AUX_BUFFERS, 0)
])

mousepos = window.inputs[:mouseposition]

pcamera   = OrthographicPixelCamera(window.inputs)

sourcedir = Pkg.dir("GLPlot", "src", "experiments")
shaderdir = sourcedir

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


selectiondata = Input(Vector2(0))



RGBAU8 = AlphaColorValue{RGB{Ufixed8}, Ufixed8}
rgba(r::Real, g::Real, b::Real, a::Real) = AlphaColorValue(RGB{Float32}(r,g,b), float32(a))
rgbaU8(r::Real, g::Real, b::Real, a::Real) = AlphaColorValue(RGB{Ufixed8}(r,g,b), ufixed8(a))

#GLPlot.toopengl{T <: AbstractRGB}(colorinput::Input{T}) = toopengl(lift(x->AlphaColorValue(x, one(T)), RGBA{T}, colorinput))
tohsv(rgba)     = AlphaColorValue(convert(HSV, rgba.c), rgba.alpha)
torgb(hsva)     = AlphaColorValue(convert(RGB, hsva.c), hsva.alpha)
tohsv(h,s,v,a)  = AlphaColorValue(HSV(float32(h), float32(s), float32(v)), float32(a))

Base.length{T}(::GLGlyph{T})                   = 4
Base.length{T}(::Type{GLGlyph{T}})             = 4
Base.eltype{T}(::GLGlyph{T})                   = T
Base.eltype{T}(::Type{GLGlyph{T}})             = T
Base.size{T}(::GLGlyph{T})                     = (4,)

GLGlyph(x::GLGlyph; glyph=x.glyph, line=x.line, row=x.row, style_index=x.style_index) = GLGlyph(glyph, line, row, style_index)

import Base: (+)

function (+){T}(a::Array{GLGlyph{T}, 1}, b::GLGlyph{T})
  for i=1:length(a)
    a[i] = a[i] + b
  end
end
function (+){T}(a::GLGlyph{T}, b::GLGlyph{T})
  GLGlyph{T}(a.glyph + b.glyph, a.line + b.line, a.row + b.row, a.style_index + b.style_index)
end

Style(x::Symbol) = Style{x}()
mergedefault!{S}(style::Style{S}, styles, customdata) = merge!(styles[S], Dict{Symbol, Any}(customdata))

#################################################################################################################################
#Text Rendering:
TEXT_DEFAULTS = [
:Default => [
  :start            => Vec3(0),
  :offset           => Vec2(1, 1.5), #Multiplicator for advance, newline
  :color            => rgbaU8(248.0/255.0, 248.0/255.0,242.0/255.0, 1.0),
  :backgroundcolor  => rgba(0,0,0,0),
  :model            => eye(Mat4),
  :newline          => -Vec3(0, getfont().props[1][2], 0),
  :advance          => Vec3(getfont().props[1][1], 0, 0),
  :camera           => pcamera
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



function makecompatible(glyph::Char, typ)
  if int(glyph) >= 0 && int(glyph) <= 255
    return convert(typ, glyph)
  else
    return convert(typ, 0)
  end
end
operators = [":", ";","=", "+", "-", "!", "¬", "~", "<", ">","=", "/", "&", "|", "\$", "*"]
brackets  = ["(", ")", "[", "]", "{", "}"]
keywords  = ["for", "end", "while", "if", "elseif", "using", "return", "in", "function", "local", "global", "let", "quote", "begin", "const", "do", "false", "true"]

regex_literals = ['|', '[', ']', '*', '.', '?', '\\', '(', ')', '{', '}', '+', '-', '$']

function escape_regex(x::String)
    result = ""
    for elem in x
        if elem in regex_literals
            result *= string('\\')
        end
        result *= string(elem)
    end
    result
end
regreduce(arr, prefix="(", suffix=")") = Regex(reduce((v0, x) -> v0*"|"*prefix*escape_regex(x)*suffix, prefix*escape_regex(arr[1])*suffix, arr[2:end]))
operators         = regreduce(operators)
brackets          = regreduce(brackets)
keywords          = regreduce(keywords, "((?<![[:alpha:]])", "(?![[:alpha:]]))")
comments          = r"(#=.*=#)|(#.*[\n\r])"
stringalike_regex = r"(\".*\")|('.*')|((?<!:):[[:alpha:]][[:alpha:]_]*)"
function_regex    = r"(?<![[:alpha:]])[[:graph:]]*\("

function colorize(color, substrings, colortexture)
    for elem in substrings
        startorigin = elem.offset+1
        stoporigin  = elem.offset+elem.endof

        colortexture[startorigin:stoporigin] = [GLGlyph(elem.glyph, elem.line, elem.row, color) for elem in colortexture[startorigin:stoporigin]]
    end
end


#=
The text needs to be uploaded into a 2D texture, with 1D alignement, as there is no way to vary the row length, which would be a big waste of memory.
This is why there is the need, to prepare offsets information about where exactly new lines reside.
If the string doesn't contain a new line, the text is restricted to one line, which is uploaded into one 1D texture.
This is important for differentiation between multi-line and single line text, which might need different treatment
=#
function GLPlot.toopengl(style::Style{:Default}, text::String, data::Dict{Symbol, Any})
  global operators, brackets, keywords, string_regex, function_regex, comments
    tab         = 3
    text        = map(x-> isascii(x) ? x : char(1), text)
    text        = utf8(replace(text, "\t", " "^tab)) # replace tabs

    #Allocate some more memory, to reduce growing the texture residing on VRAM
    texturesize = (div(length(text),     1024) + 1) * 2 # a texture size of 1024 should be supported on every GPU
    text_array  = Array(GLGlyph{Uint16}, 1024, texturesize)

    line        = 1
    advance     = 0
    for i=1:length(text_array)
      if i <= length(text)
        glyph = text[i]
        text_array[i] = GLGlyph(glyph, line, advance, 0)
        if glyph == '\n'
          advance = 0
          line += 1
        else
          advance += 1
        end
      else # Fill in default value
        text_array[i] = GLGlyph()
      end
    end


    color_lookup = Texture([
      data[:color]   
    ])

    # To make things simple for now, checks if the texture is too big for the GPU are done by 'Texture' and an error gets thrown there.
    data[:color_lookup] = color_lookup
    data[:textlength]   = length(text)
    data[:lines]        = line

    return toopengl(style, Texture(text_array), data)
end


# This is the low-level text interface, which simply prepares the correct shader and cameras
function GLPlot.toopengl(::Style{:Default}, text::Texture{GLGlyph{Uint16}, 4, 2}, data::Dict{Symbol, Any})
  camera        = data[:camera]
  font          = getfont()
  renderdata    = merge(data, font.data) # merge font texture and uv informations -> details @ GLFont/src/types.jl
  renderdata[:model] = renderdata[:model] * translationmatrix(Vec3(20,1080-20,0))

  view = [
    "GLSL_EXTENSIONS" => "#extension GL_ARB_draw_instanced : enable"
  ] 

  renderdata[:text]           = text
  renderdata[:projectionview] = camera.projectionview
  shader = TemplateProgram(
    Pkg.dir("GLText", "src", "textShader.vert"), Pkg.dir("GLText", "src", "textShader.frag"), 
    view=view, attributes=renderdata, fragdatalocation=[(0, "fragment_color"),(1, "fragment_groupid")]
  )
  obj = instancedobject(renderdata, shader, data[:textlength])
  obj[:prerender, enabletransparency] = ()
  return obj
end

TEXT_EDIT_DEFAULTS = (Symbol => Any)[:Default => (Symbol => Any)[]]
edit(text::Texture{GLGlyph{Uint16}, 4, 2}, obj, style=Style(:Default); customization...) = edit(style, text, obj, mergedefault!(style, TEXT_EDIT_DEFAULTS, customization))

# Filters a signal. If any of the items is in the signal, the signal is returned.
# Otherwise default is returned
function filteritems{T}(a::Signal{T}, items, default::T)
  lift(a) do signal
    if any(item-> in(item, signal), items)
      signal
    else
      default 
    end
  end
end

function edit_text(v0, selection1, unicode_keys, special_keys)
  # selection0 tracks, where the carsor is after a new character addition, selection10 tracks the old selection
  obj, textlength, textGPU, text0, selection0, selection10 = v0
  v1 = (obj, textlength, textGPU, text0, selection0, selection1)
  changed = false 
  try
    # to compare it to the newly selected mouse position
    if selection10 != selection1
      v1 = (obj, textlength, textGPU, text0, selection1, selection1)
    elseif !isempty(special_keys) && isempty(unicode_keys)
      if in(GLFW.KEY_BACKSPACE, special_keys)
        text0 = delete!(text0, selection0[2])
        textlength -= 1
        changed = true
        selection = selection0[2] >= 1 ? Vector2(selection0[1], selection0[2] - 1) : Vector2(selection0[1], 0)
        v1 = (obj, textlength, textGPU, text0, selection, selection1)
      elseif in(GLFW.KEY_ENTER, special_keys)
        text0 = addchar(text0, '\n', selection0[2])
        textlength += 1
        changed = true
        v1 = (obj, textlength, textGPU, text0, selection0 + Vector2(0,1), selection1)
      end
    elseif !isempty(unicode_keys) && selection0[1] == obj.id # else unicode input must have occured
      text0 = addchar(text0, first(unicode_keys), selection0[2])
      textlength += 1
      changed = true
      v1 = (obj, textlength, textGPU, text0, selection0 + Vector2(0,1), selection1)
    end

    if changed
      line        = 1
      advance     = 0
      for i=1:length(text0)
        if i <= textlength
          glyph = text0[i].glyph
          text0[i] = GLGlyph(glyph, line, advance, 0)
          if glyph == '\n'
            advance = 0
            line += 1
          else
            advance += 1
          end
        else # Fill in default value
          text0[i] = GLGlyph()
        end
      end

      if textlength > length(text0) || length(text0) % 1024 != 0
        newlength = 1024 - rem(length(text0)+1024, 1024)
        text0     = [text0, Array(GLGlyph{Uint16}, newlength)]
        resize!(textGPU, [1024, div(length(text0),1024)])
      end
      textGPU[1:0, 1:0] = reshape(text0, 1024, div(length(text0),1024))
      obj[:postrender, renderinstanced] = (obj.vertexarray, textlength)
    end
  catch err
    Base.show_backtrace(STDERR, catch_backtrace())
    println(err)
  end

  return v1
end

function edit(style::Style{:Default}, textGPU::Texture{GLGlyph{Uint16}, 4, 2}, obj, custumization::Dict{Symbol, Any})
  specialkeys = filteritems(window.inputs[:buttonspressed], [GLFW.KEY_ENTER, GLFW.KEY_BACKSPACE], IntSet())
  # Filter out the selected index, 
  changed = lift(x->x[1], foldl((true, selectiondata.value), selectiondata) do v0, data
    (v0[2] != data, data)
  end)

  leftclick_selection = foldl((Vector2(-1)), keepwhen(changed, Vector2(-1), selectiondata), window.inputs[:mousebuttonspressed]) do v0, data, buttons
    if !isempty(buttons) && first(buttons) == 0  # if any button is pressed && its the left button
      data #return index^^^
    else
      v0
    end
  end
  text      = vec(data(textGPU))

  v00       = (obj, obj.alluniforms[:textlength], textGPU, text, leftclick_selection.value, leftclick_selection.value)
  testinput = foldl(edit_text, v00, leftclick_selection, window.inputs[:unicodeinput], specialkeys)

  return lift(testinput) do tinput
    Uint8[uint8(elem.glyph) for elem in tinput[4][1:tinput[2]]]
  end
end


function Base.delete!(s::Array{GLGlyph{Uint16}, 1}, Index::Integer)
  if Index == 0
    return s
  elseif Index == length(s)
    return s[1:end-1]
  end
  return [s[1:max(Index-1, 0)], s[min(Index+1,length(s)):end]]
end

addchar(s::Array{GLGlyph{Uint16}, 1}, glyph::Char, Index::Integer) = addchar(s, GLGlyph(glyph, 0, 0, 0), int(Index))
function addchar(s::Array{GLGlyph{Uint16}, 1}, glyph::GLGlyph{Uint16}, i::Integer)
  if i == 0
    return [glyph, s]
  elseif i == length(s)
    return [s, glyph]
  elseif i > length(s) || i < 0
    return s
  end
  return [s[1:i], glyph, s[i+1:end]]
end


const url = "http://192.168.178.40:8080/findFunctionByName/"


obj  = toopengl("len\n")
obj2 = toopengl("search", model=eye(Mat4)*translationmatrix(Vec3(0,-40, 0)))


searchterm = edit(obj[:text], obj)
lift(searchterm) do term
  @async begin
    try    
      term = replace(bytestring(HTTPClient.HTTPC.get(url*ascii(term)).body), '§', '\n')
    catch ex
      term = repr(ex)
    end
    line        = 1
    advance     = 0
    text_array  = Array(GLGlyph{Uint16}, length(term))
    for i=1:length(term)
      glyph = term[i]
      text_array[i] = GLGlyph(glyph, line, advance, 0)
      if glyph == '\n'
        advance = 0
        line += 1
      else
        advance += 1
      end
    end
    obj2[:text][1:0, 1] = text_array
    obj2[:postrender, renderinstanced] = (obj.vertexarray, length(term))
  end
end


lift(x-> glViewport(0,0,x...), window.inputs[:framebuffer_size])
glClearColor(39.0/255.0, 40.0/255.0, 34.0/255.0, 1.0)
function renderloop()
  render(obj)
  render(obj2)
end


const mousehover = Vector2{GLushort}[Vector2{GLushort}(0,0)]
runner = 0
while !GLFW.WindowShouldClose(window.glfwWindow)
  yield() # this is needed for react to work
  glBindFramebuffer(GL_FRAMEBUFFER, fb)
  glDrawBuffers(2, [GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1])
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
  renderloop()

  if runner % 15 == 0
    mousex, mousey = int([window.inputs[:mouseposition].value])
    glReadBuffer(GL_COLOR_ATTACHMENT1) 
    glReadPixels(mousex, mousey, 1,1, stencil.format, stencil.pixeltype, mousehover)
    @async push!(selectiondata, convert(Vector2{Int}, mousehover[1]))
  end


  glReadBuffer(GL_COLOR_ATTACHMENT0)
  glBindFramebuffer(GL_READ_FRAMEBUFFER, fb)
  glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0)
  glClear(GL_COLOR_BUFFER_BIT)

  window_size = window.inputs[:framebuffer_size].value
  glBlitFramebuffer(0,0, window_size..., 0,0, window_size..., GL_COLOR_BUFFER_BIT, GL_NEAREST)
  yield()

  GLFW.SwapBuffers(window.glfwWindow)
  GLFW.PollEvents()
  
  runner += 1
end
GLFW.Terminate()
