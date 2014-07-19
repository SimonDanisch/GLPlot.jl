using GLWindow, GLUtil, ModernGL, ImmutableArrays, React, GLFW, Quaternions
immutable Pivot
	up::Vec3
	position::Vec3
	lookat::Vec3

	xangle::Float32
	yangle::Float32
	zoom::Float32	
	mousepressed::Bool
end
function createpivot(up::Vec3,
	position::Vec3,
	lookat::Vec3,

	xangle::Float32,
	yangle::Float32,
	zoom::Float32,
	pressed::Bool)
	Pivot(up, position, lookat, xangle, yangle, zoom, pressed)
end

function rotate2{T}(angle::T, axis::Vector3{T})
 	rotationmatrix(qrotation(convert(Array, axis), angle))
end

window  = createwindow("Mesh Display", 1500, 1500, debugging = false)

##########################################################################
##########################################################################
##########################################################################
# LIFTS

#=
mouseposition = foldl((v0,v1)-> begin
	history = sum(diff(v0[2:end]))
	println(v0)
	filtered = abs(history[1]) > abs(history[2]) ? Vec2(v1[1], v1[2] / 5f0) : Vec2(v1[1] / 5f0, v1[2])
	tmp = shift!(v0)
	unshift!(v0, Vec2(v1...))
	unshift!(v0, filtered)
	resize!(v0, 5)
	v0
end, Vec2[Vec2(mouseposition.value...), Vec2(mouseposition.value...), Vec2(mouseposition.value...), Vec2(mouseposition.value...)], mouseposition)
mouseposition = lift(first, mouseposition)
=#
#lift(println, mouseposition)
mouseposition 	= window.inputs[:mouseposition]
clicked 	= window.inputs[:mousepressed]
keypressed 	= window.inputs[:keypressed]

mousedown = window.inputs[:mousepressed]


draggx = lift(x-> float32(x[1]), Float32, mouseposition)
draggy = lift(x-> float32(x[2]), Float32, mouseposition)

strgmod = lift(x-> x==GLFW.MOD_CONTROL, Bool, window.inputs[:keymodifiers])
position = keepwhen(strgmod, lift(x-> Vec2(x...), Vec2, mouseposition)

zoom = foldl((a,b) -> float32(a+(b*0.1f0)) , 0f0, window.inputs[:scroll_y])

up 		= Input(Vec3(0,0,1))
pos 	= Input(Vec3(1,0,0)) 
lookatv = Input(Vec3(0))

inputs = lift(createpivot, up, pos, lookatv, draggx, draggy, zoom, mousedown)

function movecam(state0::Pivot, state1::Pivot)

	if state0.mousepressed
		xangle 		= state0.xangle - state1.xangle #get the difference from the previous state
		yangle 		= state0.yangle - state1.yangle

		dir 		= state0.position - state0.lookat

		right 		= unit(cross(dir, state0.up))
		xrotation 	= rotate2(deg2rad(xangle), state0.up) #rotation matrix around up
		yrotation 	= rotate2(deg2rad(yangle), right)
		up 			= Vector3(yrotation * [state0.up...])
	 	pos1 		= Vector3(yrotation * xrotation * [state0.position...])
 		return Pivot(up, pos1, state0.lookat, state1.xangle, state1.yangle, state1.zoom, state1.mousepressed)
	end	
	dir 	= state0.position - state0.lookat
	zoom 	= state0.zoom 	- state1.zoom
	zoomdir	= unit(dir)*zoom #zoom just shortens the direction vector
	pos1 	= state0.position-zoomdir
	return Pivot(state0.up, pos1, state0.lookat, state1.xangle, state1.yangle, state1.zoom, state1.mousepressed)
end
cam  	= foldl(movecam, Pivot(Vec3(0,0,1), Vec3(1,0,0), Vec3(0), 0f0, 0f0, 0f0, false) , inputs)
camvecs = lift(x-> (x.position, x.lookat, x.up), cam)

view = lift(x-> lookat(x...), camvecs)

window_ratio = lift(x -> x[1] / x[2], Float32, window.inputs[:window_size])


projection 		= lift(x -> perspectiveprojection(41f0, x, 1f0, 10f0), Mat4, window_ratio)

projectionview 	= lift(*, Mat4, projection, view)

############################################################################################
############################################################################################
############################################################################################





const gridvert = """
#version 130

in vec3 vertexes;

out vec3 vposition;

uniform mat4 mvp;

void main()
{
    vposition   = vertexes;
    gl_Position = mvp * vec4(vertexes, 1.0);
}
"""
const gridfrag = """
#version 130
uniform vec4 bg_color;
uniform vec4 grid_color;
uniform vec3 grid_thickness;
uniform vec3 grid_size;


in vec3 vposition;

out vec4 fragment_color;

void main()
{
 	vec3  v  		= vec3(vposition.xyz) * grid_size;
    vec3  f  		= abs(fract(v) - 0.5);
    vec3  df 		= fwidth(v);
    vec3  g  		= smoothstep(-grid_thickness * df, +grid_thickness * df, f);
    float c  		= (1.0-g.x * g.y * g.z);
    fragment_color 	= mix(bg_color, vec4(vposition.xyz, 1), c);
}
"""

global const shader = GLProgram(gridvert, gridfrag, "vert", "frag")


gridPlanes = GLBuffer(Float32[
					    0, 0, 0,
					    1, 0, 0,
					    1, 1, 0,
					    0,  1, 0,

					    0, 1, 1,
					    0,  0, 1,

					    1, 0, 1,
					    ], 3)

gridPlaneIndexes = GLBuffer(GLuint[
									0, 1, 2, 2, 3, 0,   #xy PLane
									0, 3, 4, 4, 5, 0,	#yz Plane
									0, 5, 6, 6, 1, 0 	#xz Plane
								  ], 1, buffertype = GL_ELEMENT_ARRAY_BUFFER)

global const axis = RenderObject(
[
	:vertexes 			  	=> gridPlanes,
	:indexes			   	=> gridPlaneIndexes,
	#:grid_color 		  => Float32[0.1,.1,.1, 1.0],
	:bg_color 			  	=> Vec4(1, 1, 1, 0.5),
	:grid_thickness  		=> Vec3(2, 2, 2),
	:grid_size  		  	=> Vec3(10,10,10),
	:mvp 				    => projectionview
], shader)


prerender!(axis, glEnable, GL_DEPTH_TEST, glDepthFunc, GL_LEQUAL, enabletransparency)
postrender!(axis, render, axis.vertexarray)

glClearColor(1,1,1,0)
glClearDepth(1)
while !GLFW.WindowShouldClose(window.glfwWindow)

  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

  render(axis)

  GLFW.SwapBuffers(window.glfwWindow)
  GLFW.PollEvents()
  sleep(0.1)
end
GLFW.Terminate()


