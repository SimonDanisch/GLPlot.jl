using GLWindow, GLUtil, ModernGL, Meshes, Events
import Base.merge
import GLWindow.EVENT_HISTORY
import GLUtil.rotate
import GLUtil.move

window = createWindow([1500, 1300], "Mesh Display")

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
	 glDepthFunc(GL_LESS)
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


function gencube(x, y, z)
	Float32[
		0.0, 0.0, 0.0,
		0.0, y, 0.0,
		x, y, 0.0,
		x, 0.0, 0.0,

		0.0, 0.0, z,
		x, 0.0, z,
		x, y, z,
		0.0, y, z,

		0.0, y, 0.0,
		0.0, y, z,
	    x, y, z,
		x, y, 0.0,

		0.0, 0.0, 0.0,
		x, 0.0, 0.0,
		x, 0.0, z,
		0.0, 0.0, z,

		0.0, 0.0, 0.0,
		0.0, 0.0, z,
		0.0, y, z,
		0.0, y, 0.0,

		x, 0.0, 0.0,
		x, y, 0.0,
		x, y, z,
		x, 0.0, z
	]
end

cube = gencube(1f0,1f0,1f0)

sz = [201, 301, 31]
center = iceil(sz/2)
C3 = Bool[(i-center[1])^2 + (j-center[2])^2 <= k^2 for i = 1:sz[1], j = 1:sz[2], k = sz[3]:-1:1]
cmap1 = uint32(linspace(0,255,60))
cmap = Array(Uint32, length(cmap1))
for i = 1:length(cmap)
    cmap[i] = cmap1[i]<<16 + cmap1[end-i+1]<<8 + cmap1[i]
end
C4 = Array(Uint32, sz..., length(cmap))
for i = 1:length(cmap)
    C4[:,:,:,i] = C3*cmap[i]
end

tex = Texture(C4, textureType=GL_TEXTURE_3D)









#Display the object with some ID and a render function. Could be deleted or overwritten with that ID
glDisplay(:xy, (FuncWithArgs(renderObject, (xyPlane,)),))
glDisplay(:zy, (FuncWithArgs(renderObject, (yzPlane,)),))
glDisplay(:zx, (FuncWithArgs(renderObject, (xzPlane,)),))

glEnable(GL_DEPTH_TEST)



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