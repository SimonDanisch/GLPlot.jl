using GLWindow, GLUtil, ModernGL, Meshes, Events, ImmutableArrays, React, GLFW


window 	= createWindow("Mesh Display", 1000, 1000 )


cam = Cam(window.inputs, Vector3(700f0, 700f0, 25f0))

include("surface.jl")
include("grid.jl")

sampleMesh = createSampleMesh()


glDisplay(:aaa, sampleMesh)

glDisplay(:zzz, axis)


glClearColor(1,1,1,0)
glEnable(GL_DEPTH_TEST)
renderloop(window)


