module GLPlot
using GLWindow, GLAbstraction, ModernGL, ImmutableArrays, React, GLFW, Images
import Mustache
export toopengl, initplotting
const sourcedir = Pkg.dir()*"/GLPlot/src/"
const shaderdir = sourcedir*"shader/"

function initplotting()
	include(sourcedir*"surface.jl")
	include(sourcedir*"volume.jl")
	include(sourcedir*"image.jl")
	include(sourcedir*"grid.jl")
	include(sourcedir*"util.jl")
end

end