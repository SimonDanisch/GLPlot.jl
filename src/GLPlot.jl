module GLPlot

using GLWindow
using GLAbstraction
using ModernGL
using ImmutableArrays
using Reactive
using GLFW
using Images
using Quaternions
using GLText
using Compat
using FixedPointNumbers
using Color

import Mustache

export glplot, createdisplay, renderloop, toopengl,clearplot


const sourcedir = Pkg.dir()*"/GLPlot/src/"
const shaderdir = sourcedir*"shader/"

include(sourcedir*"grid.jl")
include(sourcedir*"surface.jl")
include(sourcedir*"volume.jl")
include(sourcedir*"image.jl")
include(sourcedir*"util.jl")
include(sourcedir*"text.jl")
include(sourcedir*"vectorfield.jl")
include(sourcedir*"mesh.jl")


global const RENDER_LIST = RenderObject[]


function glplot(args...;keyargs...)
	obj = toopengl(args...;keyargs...)
	push!(RENDER_LIST, obj)
	obj
end
function glplot(x::RenderObject)
	push!(RENDER_LIST, x)
	x
end
function glplot(x::Vector{RenderObject})
	append!(RENDER_LIST, x)
	x
end
clearplot() = empty!(RENDER_LIST)



#=
Args
		async: if true, renderloop gets started asyncronously, if not, you eed to start it yourself
			w: window width      
			h: window height
  eyeposition: position of the camera
  	   lookat: point the camera looks at
returns:
	window with window event signals
=#
function createdisplay(;async=false, w=500, h=500, eyeposition=Vec3(1,1,0), lookat=Vec3(0), debugging=false) 
	global window 	= createwindow("GLPlot", w, h, debugging=debugging) 
	global pcamera 	= PerspectiveCamera(window.inputs, eyeposition, lookat)
	global ocamera 	= OrthographicCamera(window.inputs)
	if async
		@async renderloop(window)
	end
	window
end
#=
Renderloop - blocking
=#
function renderloop(window)
	global RENDER_LIST
	glClearColor(1,1,1,0)
	while !GLFW.WindowShouldClose(window.nativewindow)
	    yield()
	    glViewport(0,0,window.inputs[:framebuffer_size].value...)
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
		for elem in RENDER_LIST
	        render(elem)
	    end
	    GLFW.SwapBuffers(window.nativewindow)
		GLFW.PollEvents()
		sleep(0.001)
	end
	GLFW.Terminate()
	empty!(RENDER_LIST)
end


end