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
const cam = PerspectiveCamera(window.inputs, Vector3(2f0, 2f0, 0.5f0), Vector3(0.5f0))

initplotting()
##########################################################
# Volume

#So far just 1 dimensional color values are supported
N = 128
volume = Float32[sin(x / 12f0)+sin(y / 12f0)+sin(z / 12f0) for x=1:N, y=1:N, z=1:N]
max = maximum(volume)
min = minimum(volume)
volume = (volume .- min) ./ (max .- min)

#Filter keydown events
keypressed = window.inputs[:buttonspressed]

#Make some attributes intseractive
algorithm 	= foldl( (v0, v1) -> in('I', v1) ? 2f0 : in('M', v1) ? 1f0 : v0, 2f0, keypressed) # i for isosurface, m for MIP#

isovalue 	= foldl( (v0, v1) -> in(GLFW.KEY_UP, v1) ? (v0 + 0.01f0) : (in(GLFW.KEY_DOWN, v1) ? (v0 - 0.01f0) : v0), 0.5f0, keypressed)
  
stepsize 	= foldl( (v0, v1) -> in(GLFW.KEY_LEFT, v1) ? (v0 + 0.0001f0) : (in(GLFW.KEY_RIGHT, v1)  ? (v0 - 0.0001f0) : v0), 0.005f0, keypressed)

obj = toopengl(volume, algorithm=algorithm, isovalue=isovalue, stepsize=stepsize, color=Vec3(1,0,0))
#obj = toopengl(imread("someexample.nrrd"), algorithm=algorithm, isovalue=isovalue, stepsize=stepsize, color=Vec3(1,0,0))

#screenshot
#lift(x->timeseries(window.inputs[:window_size].value), filter(x->x=='s', '0', window.inputs[:unicodeinput]))


# I decided not to fake some kind of Render tree for now, as I don't really have more than a list of render objects currently.
# So this is a little less comfortable, but therefore you have all of the control
glClearColor(1,1,1,0) #background color
glClearDepth(1)
while !GLFW.WindowShouldClose(window.glfwWindow)

  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

  render(GRID)
  render(obj)

  yield() # this is needed for react to work
  GLFW.SwapBuffers(window.glfwWindow)
  GLFW.PollEvents()

end
GLFW.Terminate()



