using GLWindow, GLUtil, ModernGL, Meshes, Events, React, Images
import Base.merge
import GLWindow.EVENT_HISTORY
import GLUtil.rotate
import GLUtil.move
import GLUtil.render
width = 1024
height = 1024
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
perspectiveCam = PerspectiveCamera(position = Float32[2, 2, 2], lookAt=Float32[0.5, 0.5, 0.5])
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


function gencube(x,y,z)
	vertices = Float32[
    0.0, 0.0,  z,
     x, 0.0,  z,
     x,  y,  z,
    0.0,  y,  z,
    # back
    0.0, 0.0, 0.0,
     x, 0.0, 0.0,
     x,  y, 0.0,
    0.0,  y, 0.0
	]
	uv = Float32[
    0.0, 0.0,  1.0,
     1.0, 0.0,  1.0,
     1.0,  1.0,  1.0,
    0.0,  1.0,  1.0,
    # back
    0.0, 0.0, 0.0,
     1.0, 0.0, 0.0,
     1.0,  1.0, 0.0,
    0.0,  1.0, 0.0
	]
	indexes = GLuint[
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
    6, 2, 1]
    return (vertices, uv, indexes)

end

volumeShader = GLProgram("volumeShader")

cone = imread("small.nrrd")
x,y,z = cone.properties["pixelspacing"]
pspacing = [float64(x), float64(y), float64(z)]

cone = cone.data[1:256, :, :]
spacing = float32(pspacing .* Float64[size(cone)...] * 2000.0)
println(spacing)

max = maximum(cone)
min = minimum(cone)

cone = float32((cone .- min) ./ (max - min))

tex = Texture(cone, GL_TEXTURE_3D)

spacing = Float32[1,1,1]
position, uv, indexes = gencube(spacing...)

cone3D = RenderObject([
		:volume_tex 	=> tex,
		:stepsize 		=> 0.001f0,
		:normalizer 	=> spacing, 
		:position 		=> GLBuffer(position, 3),
		:indexes 		=> GLBuffer(indexes, 1, bufferType = GL_ELEMENT_ARRAY_BUFFER),
		:mvp 			=> perspectiveCam
	], volumeShader)



glDisplay(:zz, renderObject, cone3D)




glClearColor(0,0,0,0)

renderloop(window)

