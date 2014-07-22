module GLPlot
using GLWindow, GLUtil, ModernGL, Meshes, Events, ImmutableArrays, React, GLFW, Images
import Mustache
export toopengl, initplotting
const sourcedir = Pkg.dir()*"/GLPlot/src/"
const shaderdir = sourcedir*"shader/"

function initplotting()
	include(sourcedir*"surface.jl")
	include(sourcedir*"volume.jl")
	include(sourcedir*"image.jl")
end

end