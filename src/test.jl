using ModernGL, GLAbstraction, GLWindow, GLFW, Reactive, ImmutableArrays, Images, GLText, Quaternions, Color, FixedPointNumbers
using GLPlot

window  = createdisplay(w=1920, h=1080, debugging=false)
immutable GLGlyph{T <: Real} <: AbstractVector{T}
	glyph::T
end
Base.getindex(collection::GLGlyph, I::Integer) = I == 1 ? collection.glyph : error("Out of bounds")
Base.length{T}(::GLGlyph{T}) 		= 1
Base.length{T}(::Type{GLGlyph{T}}) 	= 1
Base.eltype{T}(::GLGlyph{T}) 		= T
Base.eltype{T}(::Type{GLGlyph{T}}) 	= T
Base.convert{T}(::Type{GLGlyph{T}}, x::Char) = (int(x) >= 0 && int(x) <= 256) ? GLGlyph(convert(T, x)) : error("This char: ", x, " can't be converted to GLGlyph")


rgba(r::Real, g::Real, b::Real, a::Real) = AlphaColorValue(RGB{Float32}(r,g,b), float32(a))

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
	textarray = glsplit(text, Float32)
	toopengl(s, Texture(textarray), data)
end


toopengl("hallo du idiot\n")