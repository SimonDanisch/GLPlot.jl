using GLWindow, GLUtil, ModernGL, Meshes, Events, React
import Base.merge
import GLWindow.EVENT_HISTORY
import GLUtil.rotate
import GLUtil.move
width = 514
height = 514
window = createWindow([width, height], "Mesh Display")


#Setup the Camera, with some events for moving the camera
function move(event::MouseDragged, cam::PerspectiveCamera)
	lastPosition = get(EVENT_HISTORY, MouseMoved{Window}, event.start)
	move(0, lastPosition.y - event.y, cam)
end
function rotate(event::MouseDragged, cam::PerspectiveCamera)
	lastPosition = get(EVENT_HISTORY, MouseMoved{Window}, event.start)
	rotate(lastPosition.x - event.x, lastPosition.y - event.y, cam)
end
perspectiveCam = PerspectiveCamera(position = Float32[2, 0, 0])
registerEventAction(WindowResized{Window}, x -> true, resize, (perspectiveCam,))
registerEventAction(WindowResized{Window}, x -> true, x -> glViewport(0,0,x.w, x.h))
registerEventAction(MouseDragged{Window}, rightbuttondragged, move, (perspectiveCam,))
registerEventAction(MouseDragged{Window}, middlebuttondragged, rotate, (perspectiveCam,))

function renderObject2(renderObject::RenderObject)
	glDisable(GL_DEPTH_TEST)
	glEnable(GL_CULL_FACE)
	glCullFace(GL_FRONT)
	enableTransparency()
	programID = renderObject.vertexArray.program.id
	if programID!= glGetIntegerv(GL_CURRENT_PROGRAM)
		glUseProgram(programID)
	end
	render(renderObject.uniforms, programID)
	glBindVertexArray(renderObject.vertexArray.id)
	glDrawElements(GL_TRIANGLES, renderObject.vertexArray.indexLength, GL_UNSIGNED_INT, GL_NONE)
end
function renderlines(renderObject::RenderObject)
	glDisable(GL_DEPTH_TEST)
	enableTransparency()
	programID = renderObject.vertexArray.program.id
	if programID!= glGetIntegerv(GL_CURRENT_PROGRAM)
		glUseProgram(programID)
	end
	render(renderObject.uniforms, programID)
	glBindVertexArray(renderObject.vertexArray.id)
	glDrawArrays(GL_LINES, 0,renderObject.vertexArray.length)
end
function renderlinesindexed(renderObject::RenderObject)
	glEnable(GL_DEPTH_TEST)
	enableTransparency()
	programID = renderObject.vertexArray.program.id
	if programID!= glGetIntegerv(GL_CURRENT_PROGRAM)
		glUseProgram(programID)
	end
	render(renderObject.uniforms, programID)
	glBindVertexArray(renderObject.vertexArray.id)
	glDrawElements(GL_LINES, renderObject.vertexArray.indexLength, GL_UNSIGNED_INT, GL_NONE)
end
function renderObject(renderObject::RenderObject)
	glEnable(GL_DEPTH_TEST)
	glEnable(GL_CULL_FACE)
	glCullFace(GL_BACK)
	enableTransparency()
	programID = renderObject.vertexArray.program.id
	if programID!= glGetIntegerv(GL_CURRENT_PROGRAM)
		glUseProgram(programID)
	end
	render(:camposition, renderObject.uniforms[:mvp].position, programID)
	render(renderObject.uniforms, programID)
	glBindVertexArray(renderObject.vertexArray.id)
	glDrawElements(GL_TRIANGLES, renderObject.vertexArray.indexLength, GL_UNSIGNED_INT, GL_NONE)
end
function cullfaced(xxx, mode)
	glEnable(GL_DEPTH_TEST)
	glEnable(GL_CULL_FACE)
	glCullFace(mode)
	programID = xxx.vertexArray.program.id
	if programID!= glGetIntegerv(GL_CURRENT_PROGRAM)
		glUseProgram(programID)
	end
	render(xxx.uniforms, programID)
	glBindVertexArray(xxx.vertexArray.id)
	glDrawElements(GL_TRIANGLES, xxx.vertexArray.indexLength, GL_UNSIGNED_INT, GL_NONE)
end

function gencube()
	(Float32[
    0.0, 0.0,  1.0,
     1.0, 0.0,  1.0,
     1.0,  1.0,  1.0,
    0.0,  1.0,  1.0,
    # back
    0.0, 0.0, 0.0,
     1.0, 0.0, 0.0,
     1.0,  1.0, 0.0,
    0.0,  1.0, 0.0
	], GLuint[
	 0, 1, 2,
    2, 3, 0,
    # top
    3, 2, 6,
    6, 7, 3,
    # back
    7, 6, 5,
    5, 4, 7,
    # bottom
    4, 5, 1,
    1, 0, 4,
    # left
    4, 0, 3,
    3, 7, 4,
    # right
    1, 5, 6,
    6, 2, 1])

end


sz = [128, 128, 128]
center = iceil(sz/2)
C3 = Bool[(i-center[1])^2 + (j-center[2])^2 <= k^2 for i = 1:sz[1], j = 1:sz[2], k = sz[3]:-1:1]
cone = C3*uint8(255)
tex = Texture(cone, GL_TEXTURE_3D)
position, indexes = gencube()

volumeShader = GLProgram("volumeShader")
frontbackface = GLProgram("frontbackface")
gridShader = GLProgram("gridShader")
lineShader = GLProgram("lineShader")
cube =   
[
	:position 		=> GLBuffer(position, 3),
	:indexes 		=> GLBuffer(indexes, 1, bufferType = GL_ELEMENT_ARRAY_BUFFER),
	:mvp 			=> perspectiveCam
]


dirvol = Input(convert(GLint, 1))
registerEventAction(Scrolled{Window}, x -> true, x -> push!(dirvol, int32(x.yOffset + 2)))


cone3D = RenderObject(merge(cube, [
	:volume_tex		=> tex,
	:stepsize		=> 0.001f0,
]), volumeShader)




gridCube = [
	:grid_color 		=> Float32[0.0,.0,.0,1],
	:grid_size 			=> Float32[0.0,0.0,0.0],
	:grid_offset 		=> Float32[0.1,0.1,0.1],
	:grid_thickness  	=> Float32[0.1,0.1,0.1],
	:bg_color			=> Float32[0, 0, 0, 0],

]
gridCU = RenderObject(merge(cube, gridCube), gridShader)

x =    RenderObject( 
[
	:position 		=> GLBuffer(Float32[0,0,0, 2,0,0], 3),
	:linecolor 		=> Float32[1,0,0,1],
	:mvp 			=> perspectiveCam
],lineShader)
y =    RenderObject( 
[
	:position 		=> GLBuffer(Float32[0,0,0, 0,2,0], 3),
	:linecolor 		=> Float32[0,1,0,1],
	:mvp 			=> perspectiveCam
],lineShader)
z =  RenderObject( 
[
	:position 		=> GLBuffer(Float32[0,0,0, 0,0,2], 3),
	:linecolor 		=> Float32[0,0,1,1],
	:mvp 			=> perspectiveCam
],lineShader)
z =  RenderObject( 
[
	:position 		=> GLBuffer(Float32[0,0,0, 0,0,2], 3),
	:linecolor 		=> Float32[0,0,1,1],
	:mvp 			=> perspectiveCam
],lineShader)

cubeLines = GLBuffer([perspectiveCam.position..., position...], 3)
cubeLinesIndexes = GLBuffer(GLuint[0,1,0,2,0,3,0,4,0,5,0,6,0,7], 1, bufferType = GL_ELEMENT_ARRAY_BUFFER)

function updateBuffer(event, buffer, cam)
	glBindBuffer(buffer.bufferType, buffer.id)
	data = cam.position
	glBufferSubData(buffer.bufferType, 0, sizeof(data), data)
end
#registerEventAction(MouseDragged{Window}, x -> true, updateBuffer, (cubeLines, perspectiveCam))

camLines =  RenderObject( 
[
	:position 		=> cubeLines,
	:indexes 		=> cubeLinesIndexes,
	:linecolor 		=> Float32[0,1,1,1],
	:mvp 			=> perspectiveCam
], lineShader)


#=
renderCube =  RenderObject(cube, frontbackface)


fb = GLuint[0]
glGenFramebuffers(1, fb)
fb = fb[1]

frontFace = glGenTextures()
glBindTexture(GL_TEXTURE_2D, frontFace)
glTexImage2D(
  GL_TEXTURE_2D,
  0,
  GL_RGBA16F,
  width,
  height,
  0,
  GL_RGBA,
  GL_FLOAT,
  C_NULL)
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER)
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER)
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)

=#


function framebuffers()
	#=
	glBindFramebuffer(GL_FRAMEBUFFER, fb)
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, frontFace, 0)

	glDrawBuffers(1, [GL_COLOR_ATTACHMENT0])
	glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT )
	cullfaced(renderCube, GL_FRONT)

	glBindFramebuffer(GL_FRAMEBUFFER, 0)
	glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT )

	activeTarget = GL_TEXTURE0 + uint32(1)
    glActiveTexture(activeTarget)
    glBindTexture(GL_TEXTURE_2D, frontFace)
    glUniform1i(glGetUniformLocation(volumeShader.id, :frontface), 1)
	=#
	renderObject(cone3D)
end


#glDisplay(:zzzzzz, (FuncWithArgs(renderObject2, (gridCU, )),))

glDisplay(:x, (FuncWithArgs(renderlines, (x,)),))
glDisplay(:y, (FuncWithArgs(renderlines, (y,)),))
glDisplay(:z, (FuncWithArgs(renderlines, (z,)),))





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