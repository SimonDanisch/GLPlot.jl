using GLWindow, GLUtil, ModernGL, Meshes, Events, React, Images, ImmutableArrays


window 	= createwindow("Mesh Display", 1000, 1000 )


cam = Cam(window.inputs, Vector3(1.5f0, 1.5f0, 1.5f0))


include("volume.jl")


volume = createvolume("example/")
gc()

gldisplay(:glplot, volume)

glClearColor(0,0,0,0)

renderloop(window)


