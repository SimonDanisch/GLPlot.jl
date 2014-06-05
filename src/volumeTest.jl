using GLWindow, GLUtil, ModernGL, Meshes, Events, React, Images
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
function renderObject2(renderObject::RenderObject)
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

cone = restrict(imread("small.nrrd"), [1]).data

cone = float32((cone .- 100.0) ./ (2400.0)) .+ 0.41f0

tex = Texture(cone, GL_TEXTURE_3D)
position, indexes = gencube()

volumeShader 	= GLProgram("volumeShader")
lineShader 		= GLProgram("lineShader")
gridShader 		= GLProgram("gridShader")
volumeExplorer 	= GLProgram("volumeExplorer")

function scaleuvw(event, uvw)
	if event.key == GLFW.KEY_UP
		uvw[1] += 0.05f0
	elseif event.key == GLFW.KEY_DOWN
		uvw[1] -= 0.05f0
	elseif event.key == GLFW.KEY_RIGHT
		uvw[2] += 0.05f0
	elseif event.key == GLFW.KEY_LEFT
		uvw[2] -= 0.05f0
	elseif event.key == GLFW.KEY_O
		uvw[3] += 0.05f0
	elseif event.key == GLFW.KEY_P
		uvw[3] -= 0.05f0
	end
end


cube =   
[
	:position 		=> GLBuffer(position, 3),
	:indexes 		=> GLBuffer(indexes, 1, bufferType = GL_ELEMENT_ARRAY_BUFFER),
	:mvp 			=> perspectiveCam
]

scaleUVW =  Float32[0, 0, 0]

registerEventAction(KeyPressed{Window}, x -> true, scaleuvw, (scaleUVW,))

cone3D = RenderObject(merge(cube, [
		:volue_tex => tex,
		:stepsize => 0.001f0
		#:scaleUVW => scaleUVW
	]), volumeShader)



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
					    2, 0, 0,
					    2, 2, 0,
					    0,  2, 0
				    ], 3),
				    :bg_color => Float32[1,0,0, 0.01]
				])
			)
		, gridShader)
	
yzPlane = RenderObject(
			merge(defaults, Dict{Symbol, Any}(
				[
					:position => GLBuffer(Float32[
					    0, 0, 0,
					    0, 2, 0,
					    0, 2, 2,
					    0,  0, 2
				    ], 3),
				    :bg_color => Float32[0,0,1, 0.01]
				])
			)
		, gridShader)

xzPlane = RenderObject(
			merge(defaults, Dict{Symbol, Any}(
				[
					:position => GLBuffer(Float32[
					    0, 0, 0,
					    0, 0, 2,
					    2, 0, 2,
					    2,  0, 0
				    ], 3),
				    :bg_color => Float32[0,1,0, 0.05]
				])
			)
		, gridShader)


#glDisplay(:xyPlane, (FuncWithArgs(renderObject2, (xyPlane,)),))
#glDisplay(:yzPlane, (FuncWithArgs(renderObject2, (yzPlane,)),))
#glDisplay(:xzPlane, (FuncWithArgs(renderObject2, (xzPlane,)),))
glDisplay(:zz, (FuncWithArgs(renderObject, (cone3D,)),))





renderloop(window)

