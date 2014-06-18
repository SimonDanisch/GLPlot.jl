# GLPlot
Libarary for plotting in OpenGL and Julia.

It builds upon unregistered packages, to get all of them you can run src/packages.jl.
If you want to try this package, I advice to wait a few more days, as I plan on cleaning my packages starting today.


##Current Sate: 
Volume rendering and surface rendering prototype finished, but not really usable for plotting, as there is no api.

###Volume Rendering
![Volume](/doc/volume1.png "Maximum intensity projection with basic transfer function")

Currently creating a volume rendering looks something like this:

```Julia
volumeRenderObject = RenderObject(
	[
		:volume_tex 	=> tex,
		:stepsize 		=> 0.001f0,
		:normalizer 	=> spacing, 
		:vertice 		=> GLBuffer(vertices, 3),
		:indexes 		=> GLBuffer(indexes, 1, bufferType = GL_ELEMENT_ARRAY_BUFFER),
		:mvp 			=> cam.projectionview,
		:camposition	=> cam.eyeposition
	]
	, volumeShader)

glDisplay(:id, volumeRenderObject)
```

####Planned API:
```Julia
glDisplay(img::Image; attributes...)
```
The attributes will overwrite the defaults, which will look like `volumeRenderObject`.
This way one has full control over the shader, but you can still have quick results!

###Surfaces:
Phong shading and BRDF shading work now, but automatic surface creation is still not fully there yet.
What should work pretty well now is supplying the z information for a grid.
####Planned API:
```Julia
glDisplay(xyz::Array; attributes...)
```
![Surface](/doc/surface.png "Surface with Phong shader")
#Next steps:

- Improve Camera

- Create Plot Api

- Create different Example plots

- Polish things and create cool shader

- Along the way, improve GLUtil.jl with better OpenGL debugging and better API


