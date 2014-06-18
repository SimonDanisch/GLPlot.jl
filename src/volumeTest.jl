using GLWindow, GLUtil, ModernGL, Meshes, Events, React, Images, ImmutableArrays



function renderObject(renderObject::RenderObject)
	glEnable(GL_DEPTH_TEST)
	glEnable(GL_CULL_FACE)
	glCullFace(GL_BACK)
	enableTransparency()
	programID = renderObject.vertexArray.program.id
	glUseProgram(programID)
	render(renderObject.uniforms)
	render(renderObject.vertexArray)
end



window = createWindow("Volume Display", 1000, 1000 )

include("plotutil.jl")

#dragging = window.inputs[:mousedragged]
#println(dragging)
#lift(println,Nothing, dragging)

dragging = window.inputs[:mousedragged]
clicked = window.inputs[:mousepressed]
zoom = window.inputs[:scroll_y]
draggedlast = lift(x -> x[1], foldl((a,b) -> (a[2], b), (Vector2(0.0), Vector2(0.0)), dragging))
dragdiff = lift(-, dragging, draggedlast)
dragdiffx = lift(x -> float32(x[1]), Float32, dragdiff)
dragdiffy = lift(x -> float32(x[2]), Float32, dragdiff)
cam = Cam(window.inputs[:window_size], dragdiffx, dragdiffy, zoom, Vector3(1.5f0, 0f0, 0f0), Input(Vector3(0.0f0)))


println("creating texture")
volume = createvolume("example/")
gc()
println("created successfully")

glDisplay(:volume, renderObject, volume)


glClearColor(0,0,0,0)

renderloop(window)


