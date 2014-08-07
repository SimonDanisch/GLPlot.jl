using GLWindow, GLAbstraction, ImmutableArrays, GLFW, React, Images, ModernGL, GLPlot

#=
Offered window Inputs, which can be used together with React:
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

global const window = createwindow("Mesh Display", 1000, 1000, debugging = false) # debugging just works on linux and windows

const cam = PerspectiveCamera(window.inputs, Vector3(1f0, 1f0, 0.5f0), Vector3(0.5f0, 0.5f0, 0f0))

initplotting()
##########################################################
# Image
#obj = toopengl(Texture("surf.png")) #reads in image in this path, supports all formats from Images.jl
obj = toopengl(Texture([Vec4(i/512,j/512,0,1)for i=1:512, j=1:512])) # any array works for texture


# I decided not to fake some kind of Render tree for now, as I don't really have more than a list of render objects currently.
# So this a little less comfortable, but therefore you have all of the control
glClearColor(1,1,1,0)
while !GLFW.WindowShouldClose(window.glfwWindow)

  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
  render(obj)
  #render(axis)
  yield() # this is needed for react to work
  GLFW.SwapBuffers(window.glfwWindow)
  GLFW.PollEvents()

end
GLFW.Terminate()




