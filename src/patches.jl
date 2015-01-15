 
using GLWindow, GLAbstraction, GLFW, ModernGL, GLPlot
import GLPlot: RENDER_LIST

 
type MeshDisplay
	window::Screen
	cam::PerspectiveCamera
end
 
function initDisplay()
	window = createwindow("Elemental", 1000, 1000)
	glClearColor(0.1,0.1,0.1,0)
	cam = PerspectiveCamera(window.inputs, Vec3(2, 2, 0.5), Vec3(0.0))
	md =  MeshDisplay(window, cam)
	interact(md)

	return md
end
 
function interact(disp::MeshDisplay)
	global RENDER_LIST
	@spawn begin
		while !GLFW.WindowShouldClose(disp.window.nativewindow)
	    	drawnow(disp)
			sleep(0.001)
		end
		GLFW.Terminate()
		empty!(RENDER_LIST)
	end
	return nothing
end
 
function drawnow(disp::MeshDisplay)
	global RENDER_LIST
	yield()
	glViewport(0,0,disp.window.inputs[:framebuffer_size].value...)
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
	for elem in RENDER_LIST
		render(elem)
	end
	GLFW.SwapBuffers(disp.window.nativewindow)
	GLFW.PollEvents()
	return nothing
end
#=
function displayMesh(disp::MeshDisplay, mesh::LagrangianMesh)
	faces = Array(Array{Int64,1},0)
	for el in mesh.elements
		efcs = facesUnsorted(el)
		for fc = 1:size(efcs,1)
			push!(faces, vec(efcs[fc,:]))
		end
	end
	verts = zeros(Float64, mesh.nnodes, 3)
	for nd = 1:mesh.nnodes
		verts[nd,1] = mesh.nodes[nd][1]
		verts[nd,2] = mesh.nodes[nd][2]
		verts[nd,3] = mesh.nodes[nd][3]
	end
	color = repmat([1. 1. 1.], mesh.nnodes,1)
	patch(disp, verts, faces, color)
	return nothing
end
=#

function patch{T <: FloatingPoint, T2 <: FloatingPoint, T3 <: Integer}(disp::MeshDisplay, verts::Array{T,2}, faces::Vector{Vector{T2}}, color::Array{T3,2})
	patch(disp, convert(Array{Float32}, verts), convert(Array{Vector{GLuint}}, faces), convert(Array{Float32}, color))
end
function patch(disp::MeshDisplay, verts::Array{Float32,2}, faces::Vector{Vector{GLuint}}, color::Array{Float32,2})
	checkbounds(verts,1,3)
	checkbounds(color,1,3)
	patch(disp, reinterpret(Vec3, verts, (size(verts,2),)), faces, reinterpret(Vec3, color, (size(color,2),)))
end
function patch(disp::MeshDisplay, verts::Vector{Vec3}, triangles::Vector{GLuint}, color::Vector{Vec3})
	lines 		 = zeros(GLuint, iround(length(triangles)*(8.0/6.0)))
	line_stencil = GLuint[0,1,1,2,2,3,3,0]
	for (i,t) in enumerate(triangles)
		i%3 == 0 && lines[]
	end

end

function patch(disp::MeshDisplay, verts::Vector{Vec3}, faces::Vector{Vector{GLuint}}, color::Vector{Vec3})
	lines 		= GLuint[]
	triangles 	= GLuint[]
	quadstencil = GLuint[1, 2, 3, 1, 3, 4]
	for fc = 1:length(faces)
		for v = 1:length(faces[fc])-1
			push!(lines, faces[fc][v])
			push!(lines, faces[fc][v+1])
		end
		push!(lines, faces[fc][end])
		push!(lines, faces[fc][1])
		if length(faces[fc]) == 3
			append!(triangles,faces[fc])
		elseif length(faces[fc]) == 4
			append!(triangles, faces[fc][quadstencil])
		else
			error("Currently only triangles and quadrilaterals are supported")
		end
	end
	patch(disp, verts, triangles, lines, color)
end

begin 
local const vert = "
	{{GLSL_VERSION}}
	{{in}} vec3 vertex;
	{{in}} vec3 color;
	{{out}} vec3 vert_color;
	uniform mat4 projectionview;
	void main(){
		vert_color = color;
		gl_Position = projectionview * vec4(vertex, 1.0);
	}
	"
local const frag = "
	{{GLSL_VERSION}}
	{{in}} vec3 vert_color; // gets automatically interpolated per fragment (fragment--> pixel)
	{{out}} vec4 frag_color;
	void main(){
		frag_color = vec4(vert_color, 0.9); // put in transparency
	}
	"
local const linevert = "
	{{GLSL_VERSION}}
	{{in}} vec3 vertex;
	uniform mat4 projectionview;
	void main(){
		gl_Position = projectionview * vec4(vertex, 1.0);
	}
	"
local const linefrag = "
	{{GLSL_VERSION}}
	{{out}} vec4 frag_color;
	void main(){
		frag_color = vec4(0.1176,0.7490,0.7490,1);
	}
	"


function patch(disp::MeshDisplay, verts::Vector{Vec3}, faces::Vector{GLuint}, lines::Vector{GLuint}, color::Vector{Vec3})
	lineshader 	= TemplateProgram(linevert, linefrag, "patch line vertex", "patch line fragment")
	shader 		= TemplateProgram(vert, frag, "patch vertex shader", "patch fragment shader")
	verts = GLBuffer(verts)
 
	obj = RenderObject([
		:vertex           => verts,
		:index            => indexbuffer(faces),
		:color            => GLBuffer(color),
		:projectionview   => disp.cam.projectionview
	], shader)
	prerender!(obj, glEnable, GL_DEPTH_TEST, glDepthFunc, GL_LEQUAL, glDisable, GL_CULL_FACE, enabletransparency)
	postrender!(obj, render, obj.vertexarray)
	
	lines = RenderObject([
		:vertex           => verts,
		:index            => indexbuffer(lines),
		:projectionview   => disp.cam.projectionview
	], lineshader)	

	prerender!(lines, glEnable, GL_DEPTH_TEST, glDepthFunc, GL_LEQUAL, glDisable, GL_CULL_FACE, enabletransparency)
	postrender!(lines, render, lines.vertexarray, GL_LINES)
	
	
	glplot(obj)
	glplot(lines)
	grid = creategrid(camera=disp.cam, bg_color=Vec4(0,0,0,0.01), grid_color=Vec4(1,1,1,0.2), xrange=(0,5), gridsteps=Vec3(5), grid_thickness=Vec3(3))
	glplot(grid)
	return nothing
end
end
 


N = 50
PD = 4
vertexes= Vec3[Vec3(sin(i)+(i/10f0), sin(i/10f0), sin(i*4f0)) for i=1:N*PD] #  Vec3 == Vector3{Float32} GLSL alike alias for immutable array
color 	= Vec3[Vec3(rand(Float32), rand(Float32), rand(Float32)) for i=1:N*PD] #random edge color

indexes = Vector{GLuint}[GLuint[1,2,3,4] + i for i=0:(N-1)]

vtx 	= reinterpret(Float32, vertexes, tuple(3, size(vertexes)...))
color 	= reinterpret(Float32, color, tuple(3, size(color)...))

md = initDisplay()

patch(md, vtx, indexes, color)

sleep(20)