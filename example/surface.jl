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
const cam = Cam(window.inputs, Vector3(2.0f0, 0f0, 0f0))

initplotting()

##########################################################
# Surface
# Signature:
# toopengl{T <: AbstractArray}(attributevalue::Matrix{T}, attribute= :z; primitive=SURFACE(), xrange::Range=0:1, yrange::Range=0:1, color=Vec4(1), rest...)
# With this API, you can upload attributes to VRAM, either as matrix or a Vector(1,2,3,4), with the cardinality depending on the attribute.
# The default defines a grid with xrange*yrange*Matrix[n], and projects a 2D geometry onto the z-values on every grid point.
# This will look something like this, for a quad as a 2D geometry:
# +---+---+---+
# | * | * | * |
# +---+---+---+
# Whereas the stars are the zvalues defined by the Matrix and the plusses are defined by the 2D geometry, with zvalues interpolated from the surrounding zvalues.
# You can upload different attributes, different 2D geometries, and your own meshes, which will be instanced for every value in the matrix.
# If you upload more then one Matrix, different scalings are allowed. This works quite easily, as OpenGL always does texture lookup in the range of 0-1.
# The lookup coordinates are calculated from the main matrix, which is the "attributevalue" matrix.

function zdata(x1, y1, factor)
    x = (x1 - 0.5) * 15
    y = (y1 - 0.5) * 15
    Vec1((sin(x) + cos(y)) / 10)
end
function zcolor(z)
    a = Vec4(0,1,0,1)
    b = Vec4(1,0,0,1)
    return mix(a,b,z[1]*5)
end

N = 128
texdata = [zdata(i/N, j/N, 5) for i=1:N, j=1:N]
colordata = map(zcolor , texdata)
color = lift(x-> Vec4(sin(x), 0,1,1), Vec4, Timing.every(0.1)) # Example on how to use react to change the color over time

#obj = toopengl(texdata) # This is the base case, where the Matrix is simply mapped as a surface, with white color
obj = toopengl(texdata, primitive=CIRCLE(), color=colordata) # Color can be any matrix or a Vec3

#####################################################################################################################
# This is basically what the SURFACE() function returns.
# The coordinates are in grid coordinates, meaning +1 is the next cell on the grid
#=

verts = Vec2[Vec2(0,0), Vec2(0,1), Vec2(1,1), Vec2(1,0)]
offset = GLBuffer(verts)
custom_surface = [
    :vertex         => Vec3(0),
    :offset         => offset,
    :index          => indexbuffer(GLuint[0,1,2,2,3,0]),
    :xscale         => 1f0,
    :yscale         => 1f0,
    :zscale         => 1f0,
    :z              => 0f0,
    :drawingmode    => GL_TRIANGLES
]
obj = toopengl(texdata, primitive=custom_surface, color=color) # Color can also be a time varying value
#now you can animate the offset:
lift(x-> begin
	update!(offset, verts + [Vec2(rand(-0.2f0:0.0001f0:0.2f0)) for i=1:4])
end, Timing.every(0.2))
=#

#####################################################################################################################
#=
obj = toopengl(texdata, :zscale, primitive=CUBE(), color=color, xscale=0.001f0, yscale=texdata)
# You can look at surface.jl to find out how the primitives look like, and create your own.
# Also, it's pretty easy to extend the shader, which you can find under shader/instance_template.vert
# Its also planned, that you can just upload your own functions and uniforms, to further move computations to the shader.

# you can also simply update the texture, even though it's not nicely exposed by the API yet.

zscale = Dict{Symbol,Any}(obj.uniforms)[:zscale]
lift(x-> begin
	update!(zscale, texdata + [Vec1((sin(x) +cos(i))/4.0) for i=1:N, k=1:N])
end, Timing.every(0.1))
=#

# I decided not to fake some kind of Render tree for now, as I don't really have more than a list of render objects currently.
# So this a little less comfortable, but therefore you have all of the control
glClearColor(1,1,1,0)

grid_size = Dict{Symbol,Any}(GRID.uniforms)[:gridsteps]
#lift(x->screenshot(window.inputs[:window_size].value), filter(x->x=='s', '0', window.inputs[:unicodeinput]))

runner = 0.0

function renderloop()
  global runner
  runner += 0.01
  render(obj)
end

#@async begin # can be used in REPL
while !GLFW.WindowShouldClose(window.glfwWindow)

  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
  #push!(grid_size, Vec3(sin(runner) * 30.0))

  renderloop()

  #timeseries(window.inputs[:window_size].value)

  yield() # this is needed for react to work

  GLFW.SwapBuffers(window.glfwWindow)
  GLFW.PollEvents()

end

GLFW.Terminate()
#end


