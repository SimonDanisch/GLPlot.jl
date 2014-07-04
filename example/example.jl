using GLPlot, React, ModernGL, Images

function screenshot(size, key)
	local imgdata = Array(Uint8, 3, size...)
	local imgprops = {"colorspace" => "RGB", "spatialorder" => ["x", "y"], "colordim" => 1}
	println(key)
	if key == 83
		glReadPixels(0, 0, size..., GL_RGB, GL_UNSIGNED_BYTE, imgdata)
		img = Image(imgdata, imgprops)
		imwrite(img, "/home/s/test.png")
		img = 0
		gc()
		println("written test.png")
	end
end
size = GLPlot.window.inputs[:window_size]
key = GLPlot.window.inputs[:keypressed]
lift(screenshot, size, key)


sampleMesh = createSampleMesh()
gldisplay(sampleMesh)



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


startplot()