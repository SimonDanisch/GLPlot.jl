using GLAbstraction, GLPlot, React

window = createdisplay()

##########################################################
# Volume

#So far just 1 dimensional color values are supported
N 		= 128
volume 	= Float32[sin(x / 12f0)+sin(y / 12f0)+sin(z / 12f0) for x=1:N, y=1:N, z=1:N]
max 	= maximum(volume)
min 	= minimum(volume)
volume 	= (volume .- min) ./ (max .- min)

#Filter keydown events
keypressed = window.inputs[:buttonspressed]

#Make some attributes intseractive
algorithm 	= foldl( (v0, v1) -> in('I', v1) ? 2f0 : in('M', v1) ? 1f0 : v0, 2f0, keypressed) # i for isosurface, m for MIP#
isovalue 	= foldl( (v0, v1) -> in(GLFW.KEY_UP, v1) ? (v0 + 0.01f0) : (in(GLFW.KEY_DOWN, v1) ? (v0 - 0.01f0) : v0), 0.5f0, keypressed)
stepsize 	= foldl( (v0, v1) -> in(GLFW.KEY_LEFT, v1) ? (v0 + 0.0001f0) : (in(GLFW.KEY_RIGHT, v1)  ? (v0 - 0.0001f0) : v0), 0.005f0, keypressed)

glplot(volume, algorithm=algorithm, isovalue=isovalue, stepsize=stepsize, color=Vec3(1,0,0))
#glplot(imread("someexample.nrrd"), algorithm=algorithm, isovalue=isovalue, stepsize=stepsize, color=Vec3(1,0,0))

#screenshot
#lift(x->timeseries(window.inputs[:window_size].value), filter(x->x=='s', '0', window.inputs[:unicodeinput]))


renderloop(window)


