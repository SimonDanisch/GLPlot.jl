using GLWindow, GLUtil, ModernGL, Meshes, Events, React, Images
import Base.merge
import GLWindow.EVENT_HISTORY
import GLUtil.rotate
import GLUtil.move
import GLUtil.render
width = 514
height = 514
window = createWindow(:VolumeRender, width, height)


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


function render(renderObject::RenderObject)
	programID = renderObject.vertexArray.program.id
	glUseProgram(programID)
	render(renderObject.uniforms)
	render(renderObject.vertexArray)
end

function renderObject(renderObject::RenderObject)
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
	glEnable(GL_DEPTH_TEST)
	glEnable(GL_CULL_FACE)
	glCullFace(GL_BACK)
	enableTransparency()
	programID = renderObject.vertexArray.program.id
	glUseProgram(programID)
	render(:camposition, perspectiveCam.position, programID)
	render(renderObject.uniforms)
	render(renderObject.vertexArray)
end
function renderObject2(renderObject::RenderObject)
	glDisable(GL_DEPTH_TEST)
	glDisable(GL_CULL_FACE)
	enableTransparency()
	render(renderObject)
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

cone = imread("small.nrrd").data
cone = cone[1:256, :, :]


max = maximum(cone)
min = minimum(cone)

cone = float32((cone .- min) ./ (max - min))

tex = Texture(cone, GL_TEXTURE_3D)
position, indexes = gencube()

volumeShader = GLProgram("volumeShader")


cone3D = RenderObject([
		:volume_tex 	=> tex,
		:stepsize 		=> 0.001f0,
		:position 		=> GLBuffer(position, 3),
		:indexes 		=> GLBuffer(indexes, 1, bufferType = GL_ELEMENT_ARRAY_BUFFER),
		:mvp 			=> perspectiveCam
	], volumeShader)



glDisplay(:zz, renderObject, cone3D)




glClearColor(1,1,1,0)

renderloop(window)

