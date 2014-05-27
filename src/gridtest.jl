using GLWindow, GLUtil, ModernGL, Meshes, Events, GLUT
import Base.merge
import GLWindow.EVENT_HISTORY
import GLUtil.rotate
import GLUtil.move

window = createWindow([1000, 1000], "Mesh Display")

shader = GLProgram("gridShader")
shader2 = GLProgram("3dshader1.30")


#Setup the Camera, with some events for moving the camera
function move(event::Scrolled, cam::PerspectiveCamera)
	move(0, event.yOffset, cam)
end
function rotate(event::MouseDragged, cam::PerspectiveCamera)
	lastPosition = get(EVENT_HISTORY, MouseMoved{Window}, event.start)
	println(lastPosition)
	println(event)
	println(lastPosition.x - event.x)
	println(lastPosition.y - event.y)

	rotate(lastPosition.x - event.x, lastPosition.y - event.y, cam)
end

#registerEventAction(EventAction{MouseDragged}(x -> x.start.key == 0 && x.start.status == 0, (), move, (perspectiveCam,)))
#registerEventAction(EventAction{MouseDragged}(x ->x.start.key == 2 && x.start.status == 0, (), mouseToRotate, (perspectiveCam,)))
perspectiveCam = PerspectiveCamera(position = Float32[500, 500, 500])
registerEventAction(WindowResized{Window}, x -> true, resize, (perspectiveCam,))

registerEventAction(Scrolled{Window}, x->true, move, (perspectiveCam,))
registerEventAction(MouseDragged{Window}, middlebuttondragged, rotate, (perspectiveCam,))

defaults = [
	:indexes			=> GLBuffer(GLuint[0, 1, 2, 2, 3, 0], 1, bufferType = GL_ELEMENT_ARRAY_BUFFER),
	:grid_color 		=> Float32[0.1,.1,.1,1],
	:grid_size 			=> Float32[0.0,0.0,0.0],
	:grid_offset 		=> Float32[0.1,0.1,0.1],
	:grid_thickness  	=> Float32[0.1,0.1,0.1],
	
	:mvp 				=> perspectiveCam
]

xyPlane = RenderObject(
			merge(defaults, Dict{Symbol, Any}(
				[
					:position => GLBuffer(Float32[
					    0, 0, 0,
					    500, 0, 0,
					    500, 500, 0,
					    0,  500, 0
				    ], 3),
				    :bg_color => Float32[1,0,0, 0.1]
				])
			)
		, shader)
	
yzPlane = RenderObject(
			merge(defaults, Dict{Symbol, Any}(
				[
					:position => GLBuffer(Float32[
					    0, 0, 0,
					    0, 500, 0,
					    0, 500, 500,
					    0,  0, 500
				    ], 3),
				    :bg_color => Float32[0,0,1, 0.1]
				])
			)
		, shader)

xzPlane = RenderObject(
			merge(defaults, Dict{Symbol, Any}(
				[
					:position => GLBuffer(Float32[
					    0, 0, 0,
					    0, 0, 500,
					    500, 0, 500,
					    500,  0, 0
				    ], 3),
				    :bg_color => Float32[0,1,0, 0.1]
				])
			)
		, shader)



# function which will get inserted into the renderlist, that renders the Meshdf
function renderObject(renderObject::RenderObject)
	#glEnable(GL_DEPTH_TEST)
	glDisable(GL_DEPTH_TEST)

	enableTransparency()
	programID = renderObject.vertexArray.program.id
	if programID!= glGetIntegerv(GL_CURRENT_PROGRAM)
		glUseProgram(programID)
	end
	#Upload the camera uniform
	render(:mvp, renderObject.uniforms[:mvp], programID)
	render(renderObject.uniforms, programID)
	glBindVertexArray(renderObject.vertexArray.id)
	glDrawElements(GL_TRIANGLES, renderObject.vertexArray.indexLength, GL_UNSIGNED_INT, GL_NONE)
end
function renderObject2(renderObject::RenderObject)
	glEnable(GL_DEPTH_TEST)

	programID = renderObject.vertexArray.program.id
	if programID!= glGetIntegerv(GL_CURRENT_PROGRAM)
		glUseProgram(programID)
	end
	#Upload the camera uniform
	render(:mvp, renderObject.uniforms[:mvp], programID)
	render(renderObject.uniforms, programID)
	glBindVertexArray(renderObject.vertexArray.id)
	glDrawElements(GL_TRIANGLES, renderObject.vertexArray.indexLength, GL_UNSIGNED_INT, GL_NONE)
	glDisable(GL_DEPTH_TEST)

end
function createSampleMesh()
	N = 10
	sigma = 1.0
	distance = Float32[ sqrt(float32(i*i+j*j+k*k)) for i = -N:N, j = -N:N, k = -N:N ]
	distance = distance + sigma*rand(2*N+1,2*N+1,2*N+1)

	# Extract an isosurface.
	lambda = N-2*sigma # isovalue
	msh = isosurface(distance,lambda)
	#A conversion is necessary so far, as the Mesh DataType is not parametrized and uses Float64+Int64

	verts = Array(Float32, length(msh.vertices) * 3)
	indices = Array(GLuint, length(msh.faces) * 3)

	index = 1
	for elem in msh.vertices
		verts[index:index+2] = Float32[elem.e1, elem.e2, elem.e3]
		index += 3
	end
	index = 1
	for elem in msh.faces
		indices[index:index+2] = GLuint[elem.v1 - 1, elem.v2 - 1, elem.v3 - 1]
		index += 3
	end
	mesh =
		[
			:indexes		=> GLBuffer(indices, 1, bufferType = GL_ELEMENT_ARRAY_BUFFER),
			:position		=> GLBuffer(verts, 3),
			:mvp			=> perspectiveCam
		]
	# The RenderObject combines the shader, and Integrates the buffer into a VertexArray
	RenderObject(mesh, shader2)
end
sampleMesh = createSampleMesh()
#Display the object with some ID and a render function. Could be deleted or overwritten with that ID
glDisplay(:xy, (FuncWithArgs(renderObject, (xyPlane,)),))
glDisplay(:zy, (FuncWithArgs(renderObject, (yzPlane,)),))
glDisplay(:zx, (FuncWithArgs(renderObject, (xzPlane,)),))
glDisplay(:sampleMesh, (FuncWithArgs(renderObject2, (sampleMesh,)),))





renderloop(window)






#=
mesh =
[
	:indexes		=> GLBuffer(indices, 1, bufferType = GL_ELEMENT_ARRAY_BUFFER),
	:position		=> GLBuffer(verts, 3),
	:Tangent	=> FLoat32[0.9, 0.2, 0.1, 1.0],
	:Binormal	=> FLoat32[0.9, 0.2, 0.1, 1.0],
	:LightDir	=> FLoat32[0.9, 0.2, 0.1, 1.0],
	:ViewPosition	=> FLoat32[0.9, 0.2, 0.1, 1.0],
	:mvp	=> FLoat32[0.9, 0.2, 0.1, 1.0],

	:SurfaceColor	=> FLoat32[0.9, 0.2, 0.1, 1.0],
	:P 				=> FLoat32[0.2, 0.9],
	:A 				=> FLoat32[0.3, 0.3],
	:Scale 			=> FLoat32[0.9, 0.9, 0.9],
]
=#