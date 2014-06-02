using GLWindow, GLUtil, ModernGL, Meshes, Events
import Base.merge
import GLWindow.EVENT_HISTORY
import GLUtil.rotate
import GLUtil.move

window = createWindow([1500, 1300], "Mesh Display")


shaderDepthVert = """
#version 130
in vec3 position;

out float o_z;
out vec3 xyz;

uniform mat4 mvp;

void main(){
	xyz = position;	

	gl_Position =  mvp * vec4(position, 1.0);
	o_z = position.z;
}

"""
shaderDepthfrag = """
#version 130
in vec3 xyz;
out vec4 colourV;

uniform vec3 camPosition;

void main(){
	float distance = length(xyz - camPosition) / 1000.0;
	vec4 color1 = vec4(1.0,0.0,0.0,1.0);
	vec4 color2 = vec4(1.0,1.0,0.0,1.0);
	colourV = mix(color1, color2, xyz.y / 500.0);
}
"""

shader = GLProgram("gridShader")
shader2 = GLProgram(shaderDepthVert, shaderDepthfrag, "shaderDepth")


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
function renderObject2(renderObject::RenderObject)
	 glDepthFunc(GL_LESS)
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
function createSampleMesh()
	x_min, x_max = -1, 15
	y_min, y_max = -1, 5
	z_min, z_max = -1, 5
	scale = 8
	a = 3
	b = 5
	c = 8
	d = 10
	e = 13
	b1(x,y,z) = box(   x,y,z, 0,0,0,a,a,a)
	s1(x,y,z) = sphere(x,y,z, a,a,a,sqrt(a))
	f1(x,y,z) = min(b1(x,y,z), s1(x,y,z))  # UNION
	b2(x,y,z) = box(   x,y,z, b,0,0,c,a,a)
	s2(x,y,z) = sphere(x,y,z, c,a,a,sqrt(a))
	f2(x,y,z) = max(b2(x,y,z), -s2(x,y,z)) # NOT
	b3(x,y,z) = box(   x,y,z, d,0,0,e,a,a)
	s3(x,y,z) = sphere(x,y,z, e,a,a,sqrt(a))
	f3(x,y,z) = max(b3(x,y,z), s3(x,y,z))  # INTERSECTION
	f(x,y,z) = min(f1(x,y,z), f2(x,y,z), f3(x,y,z))

	vol = volume(f, x_min,y_min,z_min,x_max,y_max,z_max, scale)
	msh = isosurface(vol, 0.0)
	#A conversion is necessary so far, as the Mesh DataType is not parametrized and uses Float64+Int64

	verts = Array(Float32, length(msh.vertices) * 3)
	indices = Array(GLuint, length(msh.faces) * 3)

	index = 1
	for elem in msh.vertices
		verts[index:index+2] = Float32[elem.e1, elem.e2, elem.e3] .* 5f0 .+ 50f0
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
			:mvp			=> perspectiveCam,
			:camPosition	=> perspectiveCam.position
		]
	# The RenderObject combines the shader, and Integrates the buffer into a VertexArray
	RenderObject(mesh, shader2)
end
sampleMesh = createSampleMesh()
#Display the object with some ID and a render function. Could be deleted or overwritten with that ID
glDisplay(:xy, (FuncWithArgs(renderObject, (xyPlane,)),))
glDisplay(:zy, (FuncWithArgs(renderObject, (yzPlane,)),))
glDisplay(:zx, (FuncWithArgs(renderObject, (xzPlane,)),))
glDisplay(:zzzzzzzzz, (FuncWithArgs(renderObject2, (sampleMesh,)),))

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