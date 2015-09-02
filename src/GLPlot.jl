VERSION >= v"0.4.0-dev+6521" && __precompile__(true)

module GLPlot

using GLVisualize, GLWindow, ModernGL, GeometryTypes

export clearplot, glplot, windowroot

function glplot(args...;window=WindowRoot, keyargs...)
	robj = visualize(args...;keyargs...)
	view(robj, window)
	bb = robj.boundingbox.value 
	view(visualize(AABB{Float32}(bb.minimum, bb.maximum*2f0), :grid), window)
	robj
end

clearplot(w::Screen=WindowRoot) = empty!(w.renderlist)

windowroot() = WindowRoot

function __init__()
	w, r = glscreen()
	glClearColor(1,1,1,1)
	global WindowRoot = w 
	@async r()

end

end