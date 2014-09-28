using Base.Test
using GLPlot, GLAbstraction, ModernGL, GLFW, Color, Images, Reactive

N = 54


window = createdisplay(w=iround(N*9.1), h=N)
camera = OrthographicPixelCamera(window.inputs)

test_images = {
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


scale_matrix 	= scalematrix(Vec3(N, N, 1))
trans_matrix	= translationmatrix(Vec3(0))

test_renderobjects = map(test_images) do image
	global scale_matrix, trans_matrix
	obj = toopengl(Texture(image), model=scale_matrix*trans_matrix, camera=camera)
	trans_matrix *= translationmatrix(Vec3(1.01, 0, 0))
	obj
end

map(glplot, test_renderobjects)

renderloop(window)
