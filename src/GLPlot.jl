using GLWindow, GLUtil, ModernGL, Meshes, Events, GLUT

createWindow(name="Mesh Display")

#Mesh creatin with Meshes.jl
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
		]
	# The RenderObject combines the shader, and Integrates the buffer into a VertexArray
	RenderObject(mesh, GLProgram("3dshader"))
end
#I use dicts to upload the attributes and buffer in a shader
meshObject = createSampleMesh()

# function which will get inserted into the renderlist, that renders the Mesh
function renderObject(renderObject::RenderObject)
	glEnable(GL_DEPTH_TEST)
	programID = renderObject.vertexArray.program.id
	if programID!= glGetIntegerv(GL_CURRENT_PROGRAM)
		glUseProgram(programID)
	end
	#Upload the camera uniform
	render(:mvp, renderObject.uniforms[:mvp], programID)
	glBindVertexArray(renderObject.vertexArray.id)
	render(:white, int32(0), programID)
	glDrawElements(GL_TRIANGLES, renderObject.vertexArray.indexLength, GL_UNSIGNED_INT, GL_NONE)
	render(:white, int32(1), programID)
	glDrawElements(GL_LINE_STRIP, renderObject.vertexArray.indexLength, GL_UNSIGNED_INT, GL_NONE)
	glDisable(GL_DEPTH_TEST)
end


#Setup the Camera, with some events for moving the camera
perspectiveCam = PerspectiveCamera(horizontalAngle = deg2rad(180f0), verticalAngle = deg2rad(0f0), position = Float32[50, 50, 50])
registerEventAction(EventAction{WindowResized{0}}(x -> true, (), resize, (perspectiveCam,)))
registerEventAction(EventAction{MouseDragged{0}}(x -> x.start.key == 0 && x.start.status == 0, (), move, (perspectiveCam,)))
registerEventAction(EventAction{MouseDragged{0}}(x ->x.start.key == 2 && x.start.status == 0, (), mouseToRotate, (perspectiveCam,)))
meshObject.uniforms[:mvp] = perspectiveCam
#Display the object with some ID and a render function. Could be deleted or overwritten with that ID
glDisplay("testObject", (FuncWithArgs(renderObject, (meshObject,)),))

glutMainLoop()










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