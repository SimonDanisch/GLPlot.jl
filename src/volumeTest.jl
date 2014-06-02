using GLWindow, GLUtil, ModernGL, Meshes, Events
import Base.merge
import GLWindow.EVENT_HISTORY
import GLUtil.rotate
import GLUtil.move

window = createWindow([1000, 1000], "Mesh Display")

shader = GLProgram("gridShader")
shader2 = GLProgram("3dshader1.30")


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

defaults = [
	:indexes			=> GLBuffer(GLuint[0, 1, 2, 2, 3, 0], 1, bufferType = GL_ELEMENT_ARRAY_BUFFER),
	:grid_color 		=> Float32[0.1,.1,.1,0.5],
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
				    :bg_color => Float32[1,0,0, 0.01]
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
				    :bg_color => Float32[0,0,1, 0.01]
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
				    :bg_color => Float32[0,1,0, 0.05]
				])
			)
		, shader)



# function which will get inserted into the renderlist, that renders the Meshdf
function renderObject(renderObject::RenderObject)
	#glDepthFunc(GL_LESS)
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
	glPixelStorei(GL_UNPACK_ALIGNMENT, 1)
	glPixelStorei(GL_PACK_ALIGNMENT, 1)
	glEnable(GL_DEPTH_TEST)

	
	glDepthFunc(GL_LESS)

	#enableTransparency()
	glEnable(GL_TEXTURE_3D)

	programID = renderObject.vertexArray.program.id
	if programID!= glGetIntegerv(GL_CURRENT_PROGRAM)
		glUseProgram(programID)
	end
	#Upload the camera uniform
	#render(:mvp, renderObject.uniforms[:mvp], programID)
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


sz = [201, 301, 31]
center = iceil(sz/2)
C3 = Bool[(i-center[1])^2 + (j-center[2])^2 <= k^2 for i = 1:sz[1], j = 1:sz[2], k = sz[3]:-1:1]
cone = fill(0.4f0, sz...)
tex = Texture(cone, GL_TEXTURE_3D)
position, indexes = gencube()
cone3D = [
	:position 	=> GLBuffer(position .* 300f0 .+ 50f0, 3),
	:uvw 		=> GLBuffer(position, 3),
	:indexes 	=> GLBuffer(indexes, 1, bufferType = GL_ELEMENT_ARRAY_BUFFER),
	:volume_tex	=> tex,
	:scrollX	=> 0.0f0,
	:scrollY	=> 0.0f0,
	:scrollZ	=> 0.0f0,
	:mvp 		=> perspectiveCam
]




volumeShader = GLProgram("volumeShader")
coneObject = RenderObject(cone3D, volumeShader)

registerEventAction(KeyPressed{Window}, x -> x.key == GLFW.KEY_RIGHT, (_, x) -> x[:scrollY] = x[:scrollY] + 0.05f0, (coneObject.uniforms,))
registerEventAction(KeyPressed{Window}, x -> x.key == GLFW.KEY_LEFT, (_, x) -> x[:scrollY] = x[:scrollY] - 0.05f0, (coneObject.uniforms,))
registerEventAction(KeyPressed{Window}, x -> x.key == GLFW.KEY_UP, (_, x) -> x[:scrollZ] = x[:scrollZ] - 0.05f0, (coneObject.uniforms,))
registerEventAction(KeyPressed{Window}, x -> x.key == GLFW.KEY_DOWN, (_, x) -> x[:scrollZ] = x[:scrollZ] + 0.05f0, (coneObject.uniforms,))
registerEventAction(Scrolled{Window}, x -> true, (event, x) -> x[:scrollX] = x[:scrollX] - float32(event.yOffset * 0.05), (coneObject.uniforms,))

registerEventAction(Scrolled{Window}, x -> true, (event, x) -> println(x[:scrollX], ", ", x[:scrollY], ", ", x[:scrollZ]), (coneObject.uniforms,))


#Display the object with some ID and a render function. Could be deleted or overwritten with that ID
glDisplay(:xy, (FuncWithArgs(renderObject, (xyPlane,)),))
glDisplay(:zy, (FuncWithArgs(renderObject, (yzPlane,)),))
glDisplay(:zx, (FuncWithArgs(renderObject, (xzPlane,)),))
glDisplay(:zzzzz, (FuncWithArgs(renderObject2, (coneObject,)),))






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