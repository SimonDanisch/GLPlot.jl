# GLPlot
Libarary for plotting in OpenGL and Julia.
It builds upon unregistered packages, to get all of them you can run src/packages.jl.

Current status: Just one example file for rendering a 3D mesh. So no plotting whatsoever.

#Next steps:

- Improve Camera:
	Should be relatively simple, and relieve me from a lot of pain, as the current camera is just terrible.

- Fix Bug in OpenGL/ModernGL package https://github.com/SimonDanisch/ModernGL.jl/issues/4

- Fix Bug in GLUT package https://github.com/rennis250/GLUT.jl/issues/12

- Create Plot Api

- Create different Example plots

- Polish things and create cool shader

- Along the way, improve GLUtil.jl with better OpenGL debugging and better API