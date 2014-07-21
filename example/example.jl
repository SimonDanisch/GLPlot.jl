using GLWindow, GLUtil, ModernGL, ImmutableArrays, GLFW, React, Images


global const window = createwindow("Mesh Display", 1000, 1000, debugging = false)
const cam = Cam(window.inputs, Vector3(1.0f0, 1.9f0, 1.0f0))
include("../src/surface.jl")

function screenshot(size, key, path="/home/screenshot.png")
	imgdata = Array(Uint8, 3, size...)
	imgprops = {"colorspace" => "RGB", "spatialorder" => ["x", "y"], "colordim" => 1}
	if key == 83
		glReadPixels(0, 0, size..., GL_RGB, GL_UNSIGNED_BYTE, imgdata)
		img = Image(imgdata, imgprops)
		imwrite(img, path)
		img = 0
		gc()
		println("written test.png")
	end
end
window_size = window.inputs[:window_size]
keypressed =  window.inputs[:keypressed]
lift(screenshot, window_size, keypressed)



N = 100
texdata = [zdata(i/N, j/N, 5) for i=1:N, j=1:N]

colordata = map(zcolor , texdata)

color = lift(x-> Vec4(sin(x), 0,0,1), Vec4, Timing.every(0.1))

mesh = zgrid(texdata, primitive=SURFACE(), color=colordata)


glClearColor(1,1,1,0)
while !GLFW.WindowShouldClose(window.glfwWindow)

  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

  render(mesh)

  GLFW.SwapBuffers(window.glfwWindow)
  GLFW.PollEvents()

end
GLFW.Terminate()
#=
Volume rendering
sz 		= [256, 256, 256]
center 	= iceil(sz/2)
C3 		= Bool[(i-center[1])^2 + (j-center[2])^2 <= (k^2) / 3 for i = 1:sz[1], j = 1:sz[2], k = sz[3]:-1:1]
cone 	= C3*uint8(255)
volume 	= createvolume(cone, shader = mipshader)

gldisplay(volume, shader=mipshader)
#gldisplay("path to folder with identically dimensioned images")
#dldisplay(imread("3d volume image"),  shader=volumeshader)

=#

#=
Other Inputs:
inputs = [
		:mouseposition					=> Input{Vector2{Float64})},
		:mousedragged 					=> Input{Vector2{Float64})},
		:window_size					=> Input{Vector2{Int})},
		:framebuffer_size 				=> Input{Vector2{Int})},
		:windowposition					=> Input{Vector2{Int})},

		:unicodeinput					=> Input{Char},
		:keymodifiers					=> Input{Int},
		:keypressed 					=> Input{Int},
		:keypressedstate				=> Input{Int},
		:mousebutton 					=> Input{Int},
		:mousepressed					=> Input{Bool},
		:scroll_x						=> Input{Int},
		:scroll_y						=> Input{Int},
		:insidewindow 					=> Input{Bool},
		:open 							=> Input{Bool}
	]
=#

