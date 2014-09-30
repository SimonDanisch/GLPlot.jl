begin 
local color_chooser_shader = TemplateProgram(joinpath(shaderdir, "colorchooser.vert"), joinpath(shaderdir, "colorchooser.frag"), 
  fragdatalocation=[(0, "fragment_color"),(1, "fragment_groupid")])
verts, uv, normals, indexes = genquad(Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(0, 1, 0))

local data = [

:vertex                   => GLBuffer(verts),
:uv                       => GLBuffer(uv),
:index                    => indexbuffer(indexes),

:middle                   => Vec2(0.5),
:color                    => Vec4(0,1,0,1),

:swatchsize               => 0.1f0,
:border_color             => Vec4(1, 1, 0.99, 1),
:border_size              => 0.01f0,

:hover                    => Input(false),
:hue_saturation           => Input(false),
:brightness_transparency  => Input(false),

:antialiasing_value       => 0.01f0,
]

#GLPlot.toopengl{T <: AbstractRGB}(colorinput::Input{T}) = toopengl(lift(x->AlphaColorValue(x, one(T)), RGBA{T}, colorinput))
tohsv(rgba)     = AlphaColorValue(convert(HSV, rgba.c), rgba.alpha)
torgb(hsva)     = AlphaColorValue(convert(RGB, hsva.c), hsva.alpha)
tohsv(h,s,v,a)  = AlphaColorValue(HSV(float32(h), float32(s), float32(v)), float32(a))

function GLPlot.toopengl{X <: AbstractAlphaColorValue}(colorinput::Signal{X}; camera=ocam)

  data[:view]       = camera.view
  data[:projection] = camera.projection
  data[:model]      = eye(Mat4)

  obj = RenderObject(data, color_chooser_shader)
  obj[:postrender, render] = (obj.vertexarray,) # Render the vertexarray

  color = colorinput.value

  # hover is true, if mouse 
  hover = lift(selectiondata) do selection
    selection[1][1] == obj.id
  end


  all_signals = foldl((tohsv(color), false, false, Vec2(0)), selectiondata) do v0, selection

    hsv, hue_sat0, bright_trans0, mouse0 = v0
    mouse           = window.inputs[:mouseposition].value
    mouse_clicked   = window.inputs[:mousebuttonspressed].value

    hue_sat = in(0, mouse_clicked) && selection[1][1] == obj.id
    bright_trans = in(1, mouse_clicked) && selection[1][1] == obj.id
    

    if hue_sat && hue_sat0
      diff = mouse - mouse0
      hue = mod(hsv.c.h + diff[1], 360)
      sat = max(min(hsv.c.s + (diff[2] / 30.0), 1.0), 0.0)

      return (tohsv(hue, sat, hsv.c.v, hsv.alpha), hue_sat, bright_trans, mouse)
    elseif hue_sat && !hue_sat0
      return (hsv, hue_sat, bright_trans, mouse)
    end

    if bright_trans && bright_trans0
      diff    = mouse - mouse0
      brightness  = max(min(hsv.c.v - (diff[2]/100.0), 1.0), 0.0)
      alpha     = max(min(hsv.alpha + (diff[1]/100.0), 1.0), 0.0)

      return (tohsv(hsv.c.h, hsv.c.s, brightness, alpha), hue_sat0, bright_trans, mouse)
    elseif bright_trans && !bright_trans0
      return (hsv, hue_sat0, bright_trans, mouse)
    end

    return (hsv, hue_sat, bright_trans, mouse)
  end
  color1 = lift(x -> torgb(x[1]), all_signals)
  color1 = lift(x -> Vec4(x.c.r, x.c.g, x.c.b, x.alpha), Vec4, color1)
  hue_saturation = lift(x -> x[2], all_signals)
  brightness_transparency = lift(x -> x[3], all_signals)


  obj.uniforms[:color]                    = color1
  obj.uniforms[:hover]                    = hover
  obj.uniforms[:hue_saturation]           = hue_saturation
  obj.uniforms[:brightness_transparency]  = brightness_transparency

  return obj
end

end # local begin color chooser

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
function delete(s::UTF8String, i::Int)
  if i == 0
    return s
  elseif i == length(s)
    return s[1:end-1]
  end
  I = chr2ind(s, i)
  return s[1:prevind(s, I)] * s[nextind(s, I):end]
end

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
function updatetext(text, start, rotation, advance_dir, newline_dir, obj)
  offset2, ctext2 = textwithoffset(text, start, rotation*advance_dir, rotation*newline_dir)

  program   = obj.vertexarray.program
  textgpu   = obj[:text]
  offsetgpu = obj[:offset]
  # Grow texture if necessary
  if size(textgpu) != size(ctext2)
    gluniform(program.uniformloc[:text]..., textgpu)
    glTexImage1D(texturetype(textgpu), 0, textgpu.internalformat, size(ctext2, 1), 0, textgpu.format, textgpu.pixeltype, ctext2)
    textgpu.dims[2] = size(ctext2, 1)
  end
  if size(offsetgpu) != size(offset2)
    gluniform(program.uniformloc[:offset]..., offsetgpu)
    glTexImage1D(texturetype(offsetgpu), 0, offsetgpu.internalformat, size(offset2, 1), 0, offsetgpu.format, offsetgpu.pixeltype, offset2)
    offsetgpu.dims[2] = size(offset2, 1)
  end
  textgpu[1:0]   = ctext2
  offsetgpu[1:0] = offset2
  obj[:postrender, renderinstanced] = (obj.vertexarray, length(text))
end

function GLPlot.toopengl{T <: String}(textinput::Input{T};
          start=Vec3(0), scale=Vec2(1/500), color=Vec4(0,0,0,1), backgroundcolor=Vec4(0), 
          lineheight=Vec3(0,0,0), advance=Vec3(0,0,0), rotation=Quaternion(1f0,0f0,0f0,0f0), textrotation=Quaternion(1f0,0f0,0f0,0f0),
          camera=GLPlot.ocamera
        )
  text = textinput.value
  
  obj = toopengl(text,  start=start, scale=scale, color=color, backgroundcolor=backgroundcolor, 
          lineheight=lineheight, advance=advance, rotation=rotation, textrotation=textrotation,
          camera=camera)
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

####################################################################

  # selection[1] <- Vector2(ObjectID, Index) for mouseposition

  # Filter events for only the one, when you select text
  textselection = lift(x -> x[2][2], filter((x)-> length(x[1]) == 1 && first(x[1]) == 0 && x[2][1] == obj.id, (IntSet(), Vector2(-1,-1)), clickedselection))
  specialkeys = filteritems(window.inputs[:buttonspressed], [GLFW.KEY_DELETE, GLFW.KEY_BACKSPACE], IntSet())
  # Initial value for foldl
  v00 = (utf8(text), textselection.value, textselection.value)
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
  obj
end
function 

MATRIX_EDITING_DEFAULTS = [
:Default => [

:color           => rgba(0,0,0,1),
:backgroundcolor => rgba(1,0,0,0.1),
:maxlenght       => 10f0, 
:maxdigits       => 5f0,
:gap             => Vec3(10, 10, 0),
:model           => eye(Mat4),
:camera          => GLPlot.pcamera,
:window          => window.inputs

]]

# High Level text rendering for one line or multi line text, which is decided by searching for the occurence of '\n' in text
# Low level text rendering for one line text
# Low level text rendering for multiple line text
make_editible{T <: Real}(text::Texture{T, 1, 2}, style=Style(:Default); customization...) = toopengl(style, text, mergedefault!(style, MATRIX_EDITING_DEFAULTS, customization))

function make_editible{T <: Real}(numbertex::Texture{T, CD, 2}, customization)

  color, backgroundcolor, maxlength, maxdigitis, gap, model, camera, window  = values(customization)

  numbers = data(numbertex) # get data from texture/video memory
  text    = Array(GLGlyph, size(numbers,1)*maxdigitis, size(numbers, 2))
  offset  = Array(Vec3,    size(text))
  fill!(text, GLGlyph(' ')) # Fill text array with blanks, as we don't need all of them

  # handle real values 
  Base.stride(x::Real, i)       = 1
  # remove f0 
  makestring(x::Integer)        = string(int(x))
  makestring(x::FloatingPoint)  = string(float64(x))

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
  obj         = toopengl(text, offset=offset, customization)

  font        = getfont()
  advance     = Vec3(font.props[1][1],0,0)
  newline     = Vec3(0, font.props[1][2] + gap[2], 0)

  i3 = 0
  maxlength = 3
  for (i, elem) in enumerate(numbers)
    i3 = ((i-1)*maxlength) + 1

    textgpu[i3:i3+maxlength]   = Vec1[Vec1(c) for c in makestring(elem, maxlength)]
    offsetgpu[i3:i3+maxlength] = Vec3[positionrunner + (advance*(k-1)) for k=1:maxlength]

    positionrunner += (advance*maxlength) + (gap.*Vec3(2,0,0))
    if i % linebreak == 0 && i!=length(numbers)
        positionrunner = start + (newline *(i/linebreak))
    end
  end

  # We allocated more space on the gpu then needed (length(numbers)*maxdigits)
  # So we need to update the render method, to render only length(numbers) * maxlength
  obj[:postrender, renderinstanced] = (obj.vertexarray, length(numbers) * maxlength)


  # We allocated more space on the gpu then needed (length(numbers)*maxdigits)
  # So we need to update the render method, to render only length(numbers) * maxlength

  foldl(([numbers], zero(eltype(numbers)), -1, -1, -1, Vector2(0.0)), window.inputs[:mouseposition], window.inputs[:mousebuttonspressed], selectiondata) do v0, mposition, mbuttons, selection
    numbers0, value0, inumbers0, igpu0, mbutton0, mposition0 = v0

    # if over a number           && nothing selected &&         only           left mousebutton clicked
    if selection[1][1] == obj.id && inumbers0 == -1 && length(mbuttons) == 1 && in(0, mbuttons)
      iorigin   = selection[1][2]
      inumbers  = div(iorigin, maxlength) + 1
      igpu      = (iorigin - (iorigin%maxlength)) + 1
      return (numbers0, numbers0[inumbers], inumbers, igpu, 0, mposition)
    end
    # if a number is selected && previous click was left && still only left button ist clicked
    if inumbers0 > 0 && mbutton0 == 0 && length(mbuttons) == 1 && in(0, mbuttons) 
      xdiff                    = mposition[1] - mposition0[1]

      numbers0[inumbers0]      = value0 + int(xdiff)

      textgpu[igpu0:maxlength] = Float32[float32(c) for c in makestring(numbers0[inumbers0], maxlength)]
      return (numbers0, value0, inumbers0, igpu0, 0, mposition0)
    end
    return (numbers0, zero(eltype(numbers0)), -1, -1, -1, Vector2(0.0))
  end

  obj
end

  obj[:postrender, renderinstanced] = (obj.vertexarray, length(numbers) * maxlength)
