using GLWindow, GLUtil, ModernGL, Meshes, Events
import Base.merge
import GLWindow.EVENT_HISTORY
import GLUtil.rotate
import GLUtil.move

window = createWindow([1000, 1000], "Mesh Display")


#Setup the Camera, with some events for moving the camera
function move(event::MouseDragged, cam::PerspectiveCamera)
	lastPosition = get(EVENT_HISTORY, MouseMoved{Window}, event.start)
	move(0, lastPosition.y - event.y, cam)
end
function rotate(event::MouseDragged, cam::PerspectiveCamera)
	lastPosition = get(EVENT_HISTORY, MouseMoved{Window}, event.start)
	rotate(lastPosition.x - event.x, lastPosition.y - event.y, cam)
end
perspectiveCam = PerspectiveCamera(position = Float32[500, 500, 500])
registerEventAction(WindowResized{Window}, x -> true, resize, (perspectiveCam,))
registerEventAction(WindowResized{Window}, x -> true, x -> glViewport(0,0,x.w, x.h))
registerEventAction(MouseDragged{Window}, rightbuttondragged, move, (perspectiveCam,))
registerEventAction(MouseDragged{Window}, middlebuttondragged, rotate, (perspectiveCam,))

function renderObject2(renderObject::RenderObject)
	glDisable(GL_DEPTH_TEST)
	glEnable(GL_CULL_FACE)
	glCullFace(GL_BACK)
	enableTransparency()
	programID = renderObject.vertexArray.program.id
	if programID!= glGetIntegerv(GL_CURRENT_PROGRAM)
		glUseProgram(programID)
	end
	render(:camPosition, renderObject.uniforms[:mvp].position, programID)
	render(renderObject.uniforms, programID)
	glBindVertexArray(renderObject.vertexArray.id)
	glDrawElements(GL_TRIANGLES, renderObject.vertexArray.indexLength, GL_UNSIGNED_INT, GL_NONE)
end

function renderObject(renderObject::RenderObject)
	glDisable(GL_DEPTH_TEST)
	glDisable(GL_CULL_FACE)
	enableTransparency()
	programID = renderObject.vertexArray.program.id
	if programID!= glGetIntegerv(GL_CURRENT_PROGRAM)
		glUseProgram(programID)
	end
	render(renderObject.uniforms, programID)
	glBindVertexArray(renderObject.vertexArray.id)
	glDrawElements(GL_TRIANGLES, renderObject.vertexArray.indexLength, GL_UNSIGNED_INT, GL_NONE)
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


sz = [256, 256, 16]
center = iceil(sz/2)
C3 = Bool[(i-center[1])^2 + (j-center[2])^2 <= k^2*4 for i = 1:sz[1], j = 1:sz[2], k = sz[3]:-1:1]
cone = C3*uint8(255)
tex = Texture(cone, GL_TEXTURE_3D)
position, indexes = gencube()
cone3D = [
	:position 		=> GLBuffer(position .* 300f0 .+ 50f0, 3),
	:uvw 			=> GLBuffer(position, 3),
	:indexes 		=> GLBuffer(indexes, 1, bufferType = GL_ELEMENT_ARRAY_BUFFER),
	:volume_tex		=> tex,
	:stepsize		=> 0.001f0,
	:mvp 			=> perspectiveCam
]

grid3d = [
	:position 			=> GLBuffer(position .* 300f0 .+ 50f0, 3),
	:uvw 				=> GLBuffer(position, 3),
	:indexes 			=> GLBuffer(indexes, 1, bufferType = GL_ELEMENT_ARRAY_BUFFER),
	:grid_color 		=> Float32[0.1,.1,.1,0.1],
	:grid_size 			=> Float32[0.0,0.0,0.0],
	:grid_offset 		=> Float32[0.1,0.1,0.1],
	:grid_thickness  	=> Float32[0.1,0.1,0.1],
	:bg_color 			=> Float32[1, 0, 0, 0.0],
	:mvp 				=> perspectiveCam
]


volumeShader = GLProgram("volumeShader")
gridShader = GLProgram("gridShader")
coneObject = RenderObject(cone3D, volumeShader)
grid3dObject = RenderObject(grid3d, gridShader)


#Display the object with some ID and a render function. Could be deleted or overwritten with that ID

glDisplay(:zzzzz, (FuncWithArgs(renderObject2, (coneObject,)),))
glDisplay(:zzzzzz, (FuncWithArgs(renderObject, (grid3dObject,)),))






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