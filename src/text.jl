#=
export textwithoffset
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
        	newlines += 1
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
	view = [
	  "GLSL_EXTENSIONS"     => "#extension GL_ARB_draw_instanced : enable",
	  "offset_calculation"  => "texelFetch(offset, index, 0).rgb;",
	]
	if !isa(color, Vec4)
		view["color_calculation"] = "texelFetch(color, index, 0);"
		color = Texture(color, parameters=parameters)
	end
	data = merge([
		:index_offset		=> convert(GLint, 0),
	    :rotation 			=> Vec4(textrotation.s, textrotation.v1, textrotation.v2, textrotation.v3),
	    :text 				=> texttex,
	    :offset 			=> offset,
	    :scale 				=> scale,
	    :color 				=> color,
	    :backgroundcolor 	=> backgroundcolor,
	    :projectionview 	=> camera.projectionview,
	    :model 				=> eye(Mat4)
	], font.data)

	program = TemplateProgram(
		Pkg.dir("GLText", "src", "textShader.vert"), Pkg.dir("GLText", "src", "textShader.frag"), 
		view=view, attributes=data, fragdatalocation=[(0, "fragment_color"),(1, "fragment_groupid")]
	)
	obj = instancedobject(data, program, length(text))
	prerender!(obj, enabletransparency)
	return obj
end
=#
using ModernGL, GLAbstraction, GLWindow, GLFW, Reactive, ImmutableArrays, Images, GLText, Quaternions, Color, FixedPointNumbers
using GLPlot

window  = createdisplay(w=1920, h=1080, debugging=true)
camera   = OrthographicPixelCamera(window.inputs)

immutable GLGlyph{T <: Real} <: AbstractVector{T}
	glyph::T
end
Base.getindex(collection::GLGlyph, I::Integer) = I == 1 ? collection.glyph : error("Out of bounds")
Base.length{T}(::GLGlyph{T}) = 1
Base.length{T}(::Type{GLGlyph{T}}) = 1
Base.eltype{T}(::GLGlyph{T}) = T
Base.eltype{T}(::Type{GLGlyph{T}}) = T
Base.convert{T}(::Type{GLGlyph{T}}, x::Char) = (int(x) >= 0 && int(x) <= 256) ? GLGlyph(convert(T, x)) : error("This char: ", x, " can't be converted to GLGlyph")


rgba(r::Real, g::Real, b::Real, a::Real) = AlphaColorValue(RGB{Float32}(r,g,b), float32(a))
#include("renderfunctions.jl")

function makecompatible(glyph::Char, typ)
	if int(glyph) >= 0 && int(glyph) <= 256
		return convert(typ, glyph)
	else
		return convert(typ, 0)
	end
end


# Returns either 1D or 2D array, with elements converted to elementtype
function glsplit(text::String, ElemType::DataType)
	splitted 		= split(text)
	maxlinelength 	= reduce(0, splitted) do v0, x
       max(length(x), v0)
    end

	dimensions 		= Int[maxlinelength]
	# If more than one line, or there is a newline in the end, make array 2D
	length(splitted) > 1 || rsearch(text, "\n") || prepend!(dimensions, [length(splitted)])
	# Copy into a 1D or 2D array
	result = Array(ElemType, length(splitted), maxlinelength)
	fill!(result, convert(ElemType, ' '))
	for (i, line) in enumerate(splitted)
		result[i, 1:length(line)] = ElemType[makecompatible(x, ElemType) for x in line]
	end
	return result
end


function GLPlot.toopengl(s::Style{:Default}, text::String, data)
	textarray = glsplit(text, GLGlyph{Uint8})
	toopengl(s, Texture(textarray), data)
end
#=
immutable GLWindow
	windowrect::Input{Vec4}
	#camera::Camera
	#framebuffer::FrameBuffer
end
=#
# Text rendering for one line text
function GLPlot.toopengl(::Style{:Default}, text::Texture{GLGlyph{Uint8}, 1, 1}, data)
	offset = data[:offset]
	color  = data[:color]

end
# Text rendering for multiple line text
function GLPlot.toopengl(::Style{:Default}, text::Texture{GLGlyph{Uint8}, 1, 2}, data)
	renderdata 	= merge(data, getfont().data)
	view = [
	  "GLSL_EXTENSIONS"     => "#extension GL_ARB_draw_instanced : enable"
	]
	renderdata[:text] = text
	renderdata[:projectionview] = camera.projectionview
	shader = TemplateProgram(
		Pkg.dir("GLText", "src", "textShader.vert"), Pkg.dir("GLText", "src", "textShader.frag"), 
		view=view, attributes=renderdata, fragdatalocation=[(0, "fragment_color"),(1, "fragment_groupid")]
	)
	obj = instancedobject(renderdata, shader, length(text), GL_POINTS)
	obj[:prerender, enabletransparency] = ()
	return obj
end


toopengl("hallo du idiot\n")

vsh = "
#version 130
in vec2 vertex;
uniform mat4 projectionview;

void main() {
gl_Position = projectionview * vec4(vertex, 0.0, 1.0);
}
"

fsh = "
#version 130

out vec4 frag_color;

void main() {
frag_color = vec4(1.0, 0.0, 1.0, 1.0);
}
"


const triangle = RenderObject(
	[
		:vertex 		=> GLBuffer(Vec2[Vec2(0, 0), Vec2(500, 1000), Vec2(1000,0)]),
		:indexes 		=> indexbuffer(GLuint[0,1,2]),
		:projectionview =>camera.projectionview
	],
	GLProgram(vsh, fsh, "vertex", "fragment"))

postrender!(triangle, render, triangle.vertexarray)


glplot(triangle)

renderloop(window)