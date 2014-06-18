using GLWindow, GLUtil, ModernGL, Meshes, Events, ImmutableArrays, React, GLFW


const phongvert = """
#version 130
in vec3 vertex;
in vec3 normal;
out vec3 N;
out vec3 v;
out vec3 vertpos;

uniform mat4 view, projection;
uniform mat3 normalmatrix;

void main(){

	v = vec3(view  * vec4(vertex,1.0));       
	vertpos = vertex / 500.0;       
   	N = normalize(normalmatrix * normal);

   	gl_Position = projection * view * vec4(vertex, 1.0);
}

"""
const phongfrag = """
#version 130
in vec3 N;
in vec3 v;
in vec3 vertpos;
out vec4 fragment_color;
uniform vec3 light_position;

void main(){
	vec3 L 		= normalize(light_position - v);
	vec3 a 		= vec3(1.0, 0.0, 0.1);
   	vec3 b 		= vec3(0.0, 1.0, 0.1);
	vec4 color 	= vec4(mix(a, b, vertpos.z + 0.5), 1.0);
   	vec4 Idiff 	= color * max(dot(N,L), 0.0); 
   	Idiff 		= clamp(Idiff, 0.0, 1.0); 
   fragment_color = vec4(Idiff.rgb, 1.0);
}
"""

const gridvert = """
#version 130

in vec3 vertexes;

out vec3 vposition;

uniform mat4 mvp;

void main()
{
    vposition   = vertexes; 
    gl_Position = mvp * vec4(vertexes, 1.0); 
}
"""

const gridfrag = """
#version 130
uniform vec4 bg_color;
uniform vec4 grid_color;
uniform vec3 grid_thickness;
uniform vec3 grid_size;


in vec3 vposition;

out vec4 fragment_color;

void main()
{
 	vec3  v  	= vec3(vposition.xyz) * grid_size;
    vec3  f  	= abs(fract(v) - 0.5);
    vec3  df 	= fwidth(v);
    vec3  g  	= smoothstep(-grid_thickness * df, +grid_thickness * df, f);
    float c  	= (1.0-g.x * g.y * g.z);
    fragment_color = mix(bg_color, vec4(vposition.xyz / 500.0, 1), c);
}
"""


window = createWindow("Mesh Display", 1000, 1000 )
#=
dragging 			= window.inputs[:mousedragged]

leftclicked 		= lift(x-> x == 0, window.inputs[:mousebutton])
rightclicked	 	= lift(x-> x == 1, window.inputs[:mousebutton])


leftdragged 		= filter(_ -> leftclicked.value, Vector2(0.0), window.inputs[:mouseposition])
rightdragged 		= filter(_ -> rightclicked.value, Vector2(0.0), window.inputs[:mouseposition])

leftdraggedlast 	= lift(x -> x[1], foldl((a,b) -> (a[2], b), (Vector2(0.0), Vector2(0.0)), leftdragged))
rightdraggedlast 	= lift(x -> x[1], foldl((a,b) -> (a[2], b), (Vector2(0.0), Vector2(0.0)), rightdragged))

leftdraggdelta 		= lift(-, leftdragged, leftdraggedlast)
rightdraggdelta 	= lift(-, rightdragged, rightdraggedlast)


leftdraggdeltax 	= lift(x -> float32(x[1]), Float32, leftdraggdelta)
leftdraggdeltay 	= lift(x -> float32(x[2]), Float32, leftdraggdelta)

rightdraggdeltay 	= lift(x -> float32(x[2]), Float32, rightdraggdelta)

=#
dragging = window.inputs[:mousedragged]
clicked = window.inputs[:mousepressed]
zoom = window.inputs[:scroll_y]
draggedlast = lift(x -> x[1], foldl((a,b) -> (a[2], b), (Vector2(0.0), Vector2(0.0)), dragging))
dragdiff = lift(-, dragging, draggedlast)
dragdiffx = lift(x -> float32(x[1]), Float32, dragdiff)
dragdiffy = lift(x -> float32(x[2]), Float32, dragdiff)
cam = Cam(window.inputs[:window_size], dragdiffx, dragdiffy, zoom, Vector3(500f0,500f0,250f0), Input(Vector3(0f0)))


shader 		= GLProgram(gridvert, gridfrag, "grid shader")
phongshader = GLProgram(phongvert, phongfrag, "phong shader")


gridPlanes = GLBuffer(Float32[
					    0, 0, 0, 		
					    500, 0, 0,
					    500, 500, 0,
					    0,  500, 0,

					    0, 500, 500, 
					    0,  0, 500,

					    500, 0, 500,
					    ], 3)

gridPlaneIndexes = GLBuffer(GLuint[
									0, 1, 2, 2, 3, 0,   #xy PLane
									0, 3, 4, 4, 5, 0,	#yz Plane
									0, 5, 6, 6, 1, 0 	#xz Plane
								  ], 1, bufferType = GL_ELEMENT_ARRAY_BUFFER)
axis = RenderObject(
[
	:vertexes 			=> gridPlanes,
	:indexes			=> gridPlaneIndexes,
	#:grid_color 		=> Float32[0.1,.1,.1, 1.0],
	:bg_color 			=> Float32[0.0,.0,.0,0.04],
	:grid_thickness  	=> Float32[1,1,1],
	:grid_size  		=> Float32[0.05,0.05,0.05],
	:mvp 				=> cam.projectionview
], shader)


# function which will get inserted into the renderlist, that renders the Meshdf
function renderObject(renderObject::RenderObject)
	glDepthFunc(GL_LESS)
	enableTransparency()
	render(renderObject)
end
function renderObject2(renderObject::RenderObject)
	glEnable(GL_DEPTH_TEST)
	#glDisable(GL_BLEND)
	glDepthFunc(GL_LESS)
	vao = renderObject.vertexArray
	programID = vao.program.id
    glUseProgram(programID)
    render(renderObject.uniforms)
    glBindVertexArray(vao.id)
    glDrawElements(GL_TRIANGLES, vao.indexLength, GL_UNSIGNED_INT, GL_NONE)

end

function createSampleMesh()
	const N = 100
	xyz = Array(Vector3{Float32}, N*N)
	index = 1
	for x=1:N, y=1:N
		x1 = (x / N) * 500f0
		y1 = (y / N) * 500f0
		xyz[index] = Vector3{Float32}(x1,y1, (sin(x1 / 30f0) + cos(y1 / 30f0)) * 50f0)
		index += 1
	end
	normals 	= Array(Vector3{Float32}, N*N)
	binormals 	= Array(Vector3{Float32}, N*N)
	tangents 	= Array(Vector3{Float32}, N*N)
	indices 	= Vector3{GLuint}[]
	for i=1:(N*N) - N - 1
		if i%N != 0
			a = Vector3{GLuint}(i 	 , i+N, i+N+1) - 1
			b = Vector3{GLuint}(i+N+1, i+1, i 	) - 1
			push!(indices, a)
			push!(indices, b)
		end
	end
	for i=1:length(normals)
		#indices = [i-1, i+1, i-N, i+N, i-1 + N, i+1 +N, i-1 - N, i+1-N]
		a = xyz[i]
		b = i > 1 ? xyz[i-1] : xyz[i+1]
		c = i + N > N*N ? xyz[i-N] : xyz[i+N]

		Tt = a-b
		Bt = a-c
		Nt = cross(Tt, Bt)

		tangents[i] 	= Tt / norm(Tt)
		binormals[i] 	= Bt / norm(Bt)
		normals[i] 		= Nt / norm(Nt)
	end
	mesh =
		[
			:indexes		=> GLBuffer{GLuint}(convert(Ptr{GLuint}, pointer(indices)), sizeof(indices), 1, GL_ELEMENT_ARRAY_BUFFER, GL_STATIC_DRAW),

			:vertex			=> GLBuffer{Float32}(convert(Ptr{Float32}, pointer(xyz)), sizeof(xyz), 3,GL_ARRAY_BUFFER, GL_STATIC_DRAW),
			:normal			=> GLBuffer{Float32}(convert(Ptr{Float32}, pointer(normals)), sizeof(normals), 3,GL_ARRAY_BUFFER, GL_STATIC_DRAW),
			#:tangent		=> GLBuffer{Float32}(convert(Ptr{Float32}, pointer(tangents)), sizeof(tangents), 3,GL_ARRAY_BUFFER, GL_STATIC_DRAW),
			#:binormal		=> GLBuffer{Float32}(convert(Ptr{Float32}, pointer(binormals)), sizeof(binormals), 3,GL_ARRAY_BUFFER, GL_STATIC_DRAW),

			:view			=> cam.view,
			:projection		=> cam.projection,
			#:viewposition 	=> cam.eyeposition,
			:normalmatrix 	=> lift( x -> begin
									m = Matrix3x3(x)
									tmp 	 = zeros(Float32, 3,3)
									tmp[1, 1:3] = [m.c1...]
									tmp[2, 1:3] = [m.c2...]
									tmp[3, 1:3] = [m.c3...]
									inv(tmp)'
								end , Array{Float32, 2}, cam.projectionview),
			:light_position		=> Float32[1,1,0],
			#:SurfaceColor	=> Float32[0.9, 0.2, 0.1, 1.0],
			#:P 				=> Float32[0.2, 0.9],
			#:A 				=> Float32[0.8, 0.8],
			#:Scale 			=> Float32[0.5, 0.5, 0.5],
		]
	# The RenderObject combines the shader, and Integrates the buffer into a VertexArray
	RenderObject(mesh, phongshader)
end
sampleMesh = createSampleMesh()

#Display the object with some ID and a render function. Could be deleted or overwritten with that ID
glDisplay(:axis, renderObject, axis)

glDisplay(:mesh, renderObject2, sampleMesh)



glClearColor(1,1,1,0)
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