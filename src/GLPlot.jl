module GLPlot
using GLWindow, GLAbstraction, ModernGL, ImmutableArrays, React, GLFW, Images, Quaternions, GLText
import Mustache

export glplot, createdisplay, renderloop


const sourcedir = Pkg.dir()*"/GLPlot/src/"
const shaderdir = sourcedir*"shader/"

include(sourcedir*"grid.jl")
include(sourcedir*"surface.jl")
include(sourcedir*"volume.jl")
include(sourcedir*"image.jl")
include(sourcedir*"util.jl")
include(sourcedir*"text.jl")


global const RENDER_LIST = RenderObject[]


function glplot(args...;keyargs...)
	push!(RENDER_LIST, toopengl(args...;keyargs...))
end
function glplot(x::RenderObject)
	push!(RENDER_LIST, x)
end

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
function createdisplay(;async=false, w=500, h=500, eyeposition=Vec3(1,1,0), lookat=Vec3(0)) 
	global window 	= createwindow("GLPlot", w, h) 
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
	while !GLFW.WindowShouldClose(window.glfwWindow)
		tic()
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
		for elem in RENDER_LIST
	        render(elem)
	    end
	    yield()
	    GLFW.SwapBuffers(window.glfwWindow)
		GLFW.PollEvents()
		fps = toq()
		if fps < 0.016 # sleep, to get exactly 60 frames
			#sleep(0.016 - fps)
		end
	end
	GLFW.Terminate()
end


end