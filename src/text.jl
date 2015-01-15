#=
function textwithoffset{T}(text::String, start::Vector3{T}, advance::Vector3{T}, lineheight::Vector3{T})
	resulttext 	= Vec1[]
	offset 		= Vec3[start]
	newlines    = one(T)

	for elem in text
		offset1 = last(offset)
		if elem == '\t'
        	offset[end] = offset1 + (advance*3)
        elseif  elem == ' '
        	offset[end] = offset1 + advance
        elseif elem == '\r' || elem == '\n'
        	offset[end] = start + (newlines*lineheight)
        else
        	glchar = float32(elem)
        	if glchar > 256 
        		glchar = float32(0)
        	end
			push!(offset, offset1 + advance)
			push!(resulttext, Vec1(glchar))
        end
	end
	offset, resulttext
end

function toopengl(text::String;
					start=Vec3(0), scale=Vec2(1/500), color=Vec4(0,0,1,1), backgroundcolor=Vec4(0), 
					lineheight=Vec3(0,0,0), advance=Vec3(0,0,0), rotation=Quaternion(1f0,0f0,0f0,0f0), textrotation=Quaternion(1f0,0f0,0f0,0f0),
					camera=ocamera
				)

	font 			= getfont()
	fontprops 		= font.props[1] .* scale

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


	offset, ctext 	= textwithoffset(text, start, rotation*advance_dir, rotation*newline_dir)

	parameters 		= [(GL_TEXTURE_WRAP_S,  GL_CLAMP_TO_EDGE), (GL_TEXTURE_MIN_FILTER, GL_NEAREST)]
	texttex 		= Texture(ctext, parameters=parameters)
	offset 			= Texture(offset, parameters=parameters)
	view = @compat Dict(
	  "GLSL_EXTENSIONS"     => "#extension GL_ARB_draw_instanced : enable",
	  "offset_calculation"  => "texelFetch(offset, index, 0).rgb;",
	)
	if !isa(color, Vec4)
		view["color_calculation"] = "texelFetch(color, index, 0);"
		color = Texture(color, parameters=parameters)
	end
	data = merge(@compat(Dict(
		:index_offset		=> convert(GLint, 0),
	    :rotation 			=> Vec4(textrotation.s, textrotation.v1, textrotation.v2, textrotation.v3),
	    :text 				=> texttex,
	    :offset 			=> offset,
	    :scale 				=> scale,
	    :color 				=> color,
	    :backgroundcolor 	=> backgroundcolor,
	    :projectionview 	=> camera.projectionview
	)), font.data)

	program = TemplateProgram(
		Pkg.dir()*"/GLText/src/textShader.vert", Pkg.dir()*"/GLText/src/textShader.frag", 
		view=view, attributes=data
	)
	obj = instancedobject(data, program, length(text))
	prerender!(obj, enabletransparency)
	return obj
end

=#

#########################################################################################################
#=
Glyph type for Text rendering.
It doesn't offer any functionality, and is only used for multiple dispatch.
=#
immutable GLGlyph{T} <: AbstractFixedVector{T, 4}
  glyph::T
  line::T
  row::T
  style_group::T
end

function GLGlyph(glyph::Integer, line::Integer, row::Integer, style_group::Integer)
  if !isascii(char(glyph))
    glyph = char('1')
  end
  GLGlyph{Uint16}(uint16(glyph), uint16(line), uint16(row), uint16(style_group))
end
function GLGlyph(glyph::Char, line::Integer, row::Integer, style_group::Integer)
  if !isascii(glyph)
    glyph = char('1')
  end
  GLGlyph{Uint16}(uint16(glyph), uint16(line), uint16(row), uint16(style_group))
end

GLGlyph() = GLGlyph(' ', typemax(Uint16), typemax(Uint16), 0)

Base.length{T}(::GLGlyph{T})                   = 4
Base.length{T}(::Type{GLGlyph{T}})             = 4
Base.eltype{T}(::GLGlyph{T})                   = T
Base.eltype{T}(::Type{GLGlyph{T}})             = T
Base.size{T}(::GLGlyph{T})                     = (4,)

Base.start{T}(::GLGlyph{T})                    = 1
Base.next{T}(x::GLGlyph{T}, state::Integer)    = (getfield(x, state), state+1)
Base.done{T}(x::GLGlyph{T}, state::Integer)    = state > 4

import Base: (+)

function (+){T}(a::Array{GLGlyph{T}, 1}, b::GLGlyph{T})
  for i=1:length(a)
    a[i] = a[i] + b
  end
end
function (+){T}(a::GLGlyph{T}, b::GLGlyph{T})
  GLGlyph{T}(a.glyph + b.glyph, a.line + b.line, a.row + b.row, a.style_group + b.style_group)
end
Base.utf16(glypharray::Array{GLGlyph{Uint16}}) = utf16(Uint16[c.glyph for c in glypharray])
Base.utf8(glypharray::Array{GLGlyph{Uint16}})  = utf8(Uint8[uint8(c.glyph) for c in glypharray])

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


function update_groups!{T}(textGPU::Texture{GLGlyph{T}, 4, 2}, regexs::Dict{T, Regex}, start=1, stop=length(text_array))
  textRam = textGPU.data[start:stop]
  text    = utf8(map(textRam) do x
    char(x.glyph)
  end)
  for (group,regex) in regexs
      for match in matchall(regex, text)
        startorigin = match.offset+1
        stoporigin  = match.offset+match.endof
        setindex1D!(textGPU, group, startorigin:stoporigin, 4) # Set group
      end
  end
end

function update_glyphpositions!{T}(text_array::AbstractArray{GLGlyph{T}}, start=1, stop=length(text_array))
  line = text_array[start].line
  row  = text_array[start].row
  for i=1:stop
    glyph = text_array[i].glyph
    setindex1D!(text_array, T[line, row], i, 2:3)
    if glyph == '\n'
      row = zero(T)
      line += one(T)
    else
      row += one(T)
    end
  end
end
function update_glyphpositions!{T}(text_array::Texture{GLGlyph{T}, 4, 2}, start=1, stop=length(text_array))
  textarray = data(text_array)
  line = textarray[start].line
  row  = textarray[start].row
  for i=1:stop-1
    glyph = textarray[i].glyph
    setindex1D!(textarray, T[line, row], i, 2:3)
    if glyph == '\n'
      row = 0
      line += 1
    else
      row += 1
    end
  end
  text_array[1:end, 1:end] = textarray
end
function makedisplayable(text::String, tab=3)
  result = map(collect(text)) do x
    str = string(x)
    if !is_valid_utf8(str)
      return utf8([one(Uint8)]) # replace with something that yields a missing symbol
    elseif str == "\r"
      return "\n"
    else
      return str == "\t" ? utf8(" "^tab) : utf8(str) # also replace tabs
    end
  end
  join(result)
end 

function toglypharray(text::String, tab=3)
  #@assert is_valid_utf16(text) # future support for utf16
  
  #Allocate some more memory, to reduce growing the texture residing on VRAM
  texturesize = div(length(text),     1024)+1 # a texture size of 1024 should be supported on every GPU
  text_array  = Array(GLGlyph{Uint16}, 1024, texturesize)
  setindex1D!(text_array, 1, 1, 2) # set first line
  setindex1D!(text_array, 0, 1, 3) # set first row
  #Set text
  for (i, elem) in enumerate(text)
    setindex1D!(text_array, uint16(char(elem)), i, 1) # character
    setindex1D!(text_array, 0, i, 4) # style group
  end
  update_glyphpositions!(text_array) # calculate glyph positions
  text_array
end


operators = [":", ";","=", "+", "-", "!", "¬", "~", "<", ">","=", "/", "&", "|", "\$", "*"]
brackets  = ["(", ")", "[", "]", "{", "}"]
keywords  = ["for", "end", "while", "if", "elseif", "using", "return", "in", "function", "local", "global", "let", "quote", "begin", "const", "do", "false", "true"]
regex_literals = ['|', '[', ']', '*', '.', '?', '\\', '(', ')', '{', '}', '+', '-', '$']

julia_groups = @compat Dict(
  1 => regreduce(operators),
  2 => regreduce(brackets),
  3 => regreduce(keywords, "((?<![[:alpha:]])", "(?![[:alpha:]]))"),
  4 => r"(#=.*=#)|(#.*[\n\r])", #Comments
  5 => r"(\".*\")|('.*')|((?<!:):[[:alpha:]][[:alpha:]_]*)", #String alike
  6 => r"(?<![[:alpha:]])[[:graph:]]*\(" # functions 
)
function toopengl{T <: String}(text::Union(T, Signal{T}); data...)
	TEXT_DEFAULTS = @compat Dict(
	  :start            => Vec3(0.0),
	  :offset           => Vec2(1.0, 1.5), #Multiplicator for advance, newline
	  :color            => rgba(0,0,0, 1.0),
	  :backgroundcolor  => rgba(0,0,0,0),
	  :model            => eye(Mat4),
	  :newline          => -Vec3(0, getfont().props[1][2], 0),
	  :advance          => Vec3(getfont().props[1][1], 0, 0),
	  :camera           => ocamera,
	  :font             => getfont(),
	  :stride           => 1024
	)

	toopengl(text, merge(TEXT_DEFAULTS, Dict{Symbol, Any}(data)))
end

function toopengl(text::String, data::Dict{Symbol, Any})
	text = makedisplayable(text)
	glypharray          = toglypharray(text)
	data[:style_group]  = Texture([data[:color]])
	data[:textlength]   = length(text) # needs to get remembered, as glypharray is usually bigger than the text
	data[:lines]        = count(x->x=='\n', text) 
	textGPU             = Texture(glypharray)
	# To make things simple for now, checks if the texture is too big for the GPU are done by 'Texture' and an error gets thrown there.
	return toopengl(textGPU, data)
end

# This is the low-level text interface, which simply prepares the correct shader and cameras
function toopengl(text::Texture{GLGlyph{Uint16}, 4, 2}, data::Dict{Symbol, Any})
  camera             = data[:camera]
  renderdata         = merge(data, data[:font].data) # merge font texture and uv informations -> details @ GLFont/src/types.jl

  view = @compat Dict(
    "GLSL_EXTENSIONS" => "#extension GL_ARB_draw_instanced : enable"
  )
  renderdata[:text]           = text
  renderdata[:projectionview] = camera.projectionview
  shader = TemplateProgram(
    Pkg.dir("GLText", "src", "textShader.vert"), Pkg.dir("GLText", "src", "textShader.frag"), 
    view=view, attributes=renderdata, fragdatalocation=[(0, "fragment_color")]
  )
  obj = instancedobject(renderdata, data[:textlength], shader, GL_TRIANGLES, textboundingbox)
  prerender!(obj, enabletransparency, glDisable, GL_DEPTH_TEST, glDisable, GL_CULL_FACE,)
  return obj
end
function toopengl(text::Vector{GLGlyph{Uint16}}, data::Dict{Symbol, Any})
  textstride = data[:stride]
  data[:textlength] = length(text) # remember text
  if length(text) % textstride != 0
    append!(text, Array(GLGlyph{Uint16}, textstride-(length(text)%textstride))) # append if can't be reshaped with 1024
  end
  data[:style_group]  = Texture([data[:color]])
  # To make things simple for now, checks if the texture is too big for the GPU are done by 'Texture' and an error gets thrown there.
  return toopengl(Texture(reshape(text, textstride, div(length(text), textstride))), data)
end
function textboundingbox(obj)
  glypharray  = data(obj[:text]) 
  advance     = obj[:advance]  
  newline     = obj[:newline]  

  maxv = Vector3(typemin(Float32))
  minv = Vector3(typemax(Float32))
  glyphbox = Vec3(12,24,0)
  for elem in glypharray[1:obj.alluniforms[:textlength]]
    
    currentpos = elem.row*advance + elem.line*newline

    maxv = maxper(maxv, currentpos + glyphbox)
    minv = minper(minv, currentpos)
  end
  AABB(minv+newline, maxv)
end

function toopengl{T <: String}(text::Signal{T}, data::Dict{Symbol, Any})
	obj = toopengl(text.value, data)
	lift(text) do txt
		update!(obj, txt)
	end
	obj
end

function GLAbstraction.update!(obj::RenderObject, text::String)
	text = makedisplayable(text)
	glypharray 	= toglypharray(text)
	textGPU 	= obj[:text]
	textlength  = length(text)
	remaining 	= div(textlength, 1024)
	if textlength > length(textGPU)
      resize!(textGPU, [size(textGPU,1), size(textGPU,2)*2])
    end
	if remaining < 1
        textGPU[1:textlength, 1:1] = reshape(glypharray[1:textlength], textlength)
    else
        textGPU[1:end, 1:remaining] = reshape(glypharray[1:1024*remaining], 1024, remaining)
    end
    obj[:postrender, renderinstanced] = (obj.vertexarray, textlength)
end