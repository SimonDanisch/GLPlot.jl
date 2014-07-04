module GLPlot
using GLWindow, GLUtil, ModernGL, Meshes, Events, ImmutableArrays, React, GLFW, Images
export gldisplay, createSampleMesh, createvolume, startplot


global const window = createwindow("Mesh Display", 1000, 1000 )


const cam = Cam(window.inputs, Vector3(1.5f0, 1.5f0, 1.0f0))

include("surface.jl")

GLWindow.gldisplay(x::Image) 		= gldisplay(:glplot, x)  
GLWindow.gldisplay(x::RenderObject) = gldisplay(:glplot, x)  

startplot() = renderloop(window)

glClearColor(0,0,0,0)
end