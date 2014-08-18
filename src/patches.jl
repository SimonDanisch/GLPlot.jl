using GLWindow, GLAbstraction, GLFW, ModernGL

global const window = createwindow("Mesh Display", 1000, 1000, debugging = false) # debugging just works on linux and windows
const cam = PerspectiveCamera(window.inputs, Vec3(2, 2, 0.5), Vec3(0.5))

vert = "
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
frag = "
{{GLSL_VERSION}}


{{in}} vec3 vert_color; // gets outomatically interpolated per fragment (fragment--> pixel)

{{out}} vec4 frag_color;
void main(){
   	frag_color = vec4(vert_color, 1); // put in transparency
}
"
linevert = "
{{GLSL_VERSION}}

{{in}} vec3 vertex;

uniform mat4 projectionview;

void main(){
   	gl_Position = projectionview * vec4(vertex, 1.0);
}
"
linefrag = "
{{GLSL_VERSION}}

{{out}} vec4 frag_color;
void main(){
   	frag_color = vec4(0,0,0,1);
}
"
lineshader 	= TemplateProgram(linevert, linefrag, "linevert", "linefrag")
shader 		= TemplateProgram(vert, frag, "vert", "frag")

N  = 5
PD = 4

verts 	= GLBuffer(Vec3[Vec3(sin(i), cos(i), cos(i)) for i=1:N*PD]) #  Vec3 == Vector3{Float32} GLSL alike alias for immutable array
color 	= GLBuffer(Vec3[Vec3(rand(Float32), rand(Float32), rand(Float32)) for i=1:N*PD]) #random edge color

obj = RenderObject([
    :vertex           => verts,
    :index            => indexbuffer(vcat([GLuint[0,1,2,2,3,0] + i for i=0:(N-1)]...)),
    :color            => color,
    :projectionview   => cam.projectionview
], shader)
postrender!(obj, render, obj.vertexarray)

lines = RenderObject([
    :vertex           => verts,
    :index            => indexbuffer(vcat([GLuint[0,1,1,2,2,3,3,0] + i for i=0:(N-1)]...)),
    :projectionview   => cam.projectionview
], lineshader)	
postrender!(lines, render, lines.vertexarray, GL_LINES)


glClearColor(1,1,1,0)
@async begin while !GLFW.WindowShouldClose(window.glfwWindow)

	  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

	  render(obj)
	  render(lines)
	  #render(axis)
	  yield() # this is needed for react to work
	  GLFW.SwapBuffers(window.glfwWindow)
	  GLFW.PollEvents()

	end
end
#GLFW.Terminate()



