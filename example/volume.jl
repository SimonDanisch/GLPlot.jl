using GLWindow, GLAbstraction, ModernGL, ImmutableArrays, GLFW, React, Images, ModernGL, GLPlot
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
const cam = Cam(window.inputs, Vector3(2.0f0, 2f0, 0f0))

initplotting()
##########################################################
# Volume

#So far just 1 dimensional color values are supported
N = 128
volume = Float32[sin(x / 16f0)+sin(y / 16f0)+sin(z / 16f0) for x=1:N, y=1:N, z=1:N]
max = maximum(volume)
min = minimum(volume)
volume = (volume .- min) ./ (max .- min)

#Filter keydown events
keypressed = keepwhen(lift(x -> x == 1, Bool, window.inputs[:keypressedstate]), 0, window.inputs[:keypressed])

#Make some attributes interactive
algorithm 	= lift( x -> x==GLFW.KEY_I ? 2f0 : 1f0, filter(x-> x==GLFW.KEY_I || x==GLFW.KEY_M, 2, keypressed)) # i for isosurface, m for MIP
isovalue 	= foldl( (v0, v1) -> v1==GLFW.KEY_UP ? (v0 + 0.05f0) : (v1==GLFW.KEY_DOWN ? (v0 - 0.05f0) : v0), 0.5f0, keypressed)
stepsize 	= foldl( (v0, v1) -> v1==GLFW.KEY_LEFT ? (v0 + 0.001f0) : (v1==GLFW.KEY_RIGHT ? (v0 - 0.001f0) : v0), 0.001f0, keypressed)

obj = toopengl(volume, algorithm=algorithm, isovalue=isovalue, stepsize=stepsize, color=Vec3(1,0,0))
#obj = toopengl(Texture(""))

# I decided not to fake some kind of Render tree for now, as I don't really have more than a list of render objects currently.
# So this is a little less comfortable, but therefore you have all of the control
glClearColor(1,1,1,0) #background color
while !GLFW.WindowShouldClose(window.glfwWindow)

  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

  render(obj)
  #render(axis)
  yield() # this is needed for react to work
  GLFW.SwapBuffers(window.glfwWindow)
  GLFW.PollEvents()

end
GLFW.Terminate()



