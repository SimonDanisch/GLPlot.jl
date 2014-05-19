import GLFW
using GLUtil, ModernGL, Meshes


GLFW.Init()
GLFW.WindowHint(GLFW.SAMPLES, 4);
GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3);
GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 3);
#glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE);

window = GLFW.CreateWindow(640, 480, "GLFW.jl")
GLFW.MakeContextCurrent(window)

initGLUtils()
shader = GLProgram("3dshader1.30")

println(bytestring(glGetString(GL_VERSION)))
println(bytestring(glGetString(GL_SHADING_LANGUAGE_VERSION)))

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
	RenderObject(mesh, shader)
end
#I use dicts to upload the attributes and buffer in a shader
meshObject = createSampleMesh()
perspectiveCam = PerspectiveCamera(horizontalAngle = deg2rad(180f0), verticalAngle = deg2rad(0f0), position = Float32[0, 0, 30])
meshObject.uniforms[:mvp] = perspectiveCam


function renderLoop()
	# Loop until the user closes the window
	while !GLFW.WindowShouldClose(window)

		glClearColor(1f0, 1f0, 1f0, 1f0)   
	    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
		glEnable(GL_DEPTH_TEST)
		programID = meshObject.vertexArray.program.id
		if programID!= glGetIntegerv(GL_CURRENT_PROGRAM)
			glUseProgram(programID)
		end
		#Upload the camera uniform
		render(:mvp, meshObject.uniforms[:mvp], programID)
		glBindVertexArray(meshObject.vertexArray.id)
		glDrawElements(GL_TRIANGLES, meshObject.vertexArray.indexLength, GL_UNSIGNED_INT, GL_NONE)
		glDisable(GL_DEPTH_TEST)
		# Swap front and back buffers
		GLFW.SwapBuffers(window)

		# Poll for and process events
		GLFW.PollEvents()
	end

	GLFW.Terminate()
	end