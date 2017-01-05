using Base.Test
using GLPlot
using GLAbstraction

using ModernGL

using GLFW
using Color
using Images
using Reactive
using ImmutableArrays
using FixedPointNumbers

N = 54

GLPlot.init()
# window = createdisplay(w=iround(N*11.1), h=N)
camera = OrthographicPixelCamera(window.inputs)

immutable GLGlyph{T <: Real} <: AbstractVector{T}
  glyph::T
end
Base.getindex(collection::GLGlyph, I::Integer) = I == 1 ? collection.glyph : error("Out of bounds")
Base.length{T}(::GLGlyph{T}) 		= 1
Base.length{T}(::Type{GLGlyph{T}})  = 1
Base.eltype{T}(::GLGlyph{T}) 		= T
Base.eltype{T}(::Type{GLGlyph{T}}) 	= T
Base.convert{T}(::Type{GLGlyph{T}}, x::Char) = (int(x) >= 0 && int(x) <= 256) ? GLGlyph(convert(T, x)) : error("This char: ", x, " can't be converted to GLGlyph")


test_images = {
	[float32(33) for i=1:N, j=1:N],
	[GLGlyph{UInt8}(33) for i=1:N, j=1:N],
	[Vector3{Ufixed8}(0, 1, 0) for i=1:N, j=1:N],
	[Vec4(0,1,0,1) for i=1:N, j=1:N],
	[Vec3(0,1,0)   for i=1:N, j=1:N],
	[AlphaColorValue(RGB(0f0,1f0,0f0), 1f0) for i=1:N, j=1:N],
	Images.ColorTypes.AlphaColor{RGB{Float32}, Float32}[Images.ColorTypes.AlphaColor(RGB(0f0,1f0,0f0), 1f0) for i=1:N, j=1:N],
	[AlphaColorValue(Images.ColorTypes.BGR(0f0,1f0, 0f0), 1f0) for i=1:N, j=1:N],
	"test.png",
	"test.tif",
	"test.jpg",
	"test.bmp",
}
scale_matrix 	= scalematrix(Vec3(1, 1, 1))
trans_matrix	= translationmatrix(Vec3(0))

test_renderobjects = map(test_images) do image
	global scale_matrix, trans_matrix
	obj = toopengl(Texture(image), model=scale_matrix*trans_matrix, camera=camera)
	trans_matrix *= translationmatrix(Vec3(N+1, 0, 0))
	obj
end

map(glplot, test_renderobjects)

renderloop(window)
