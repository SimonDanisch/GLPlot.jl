using ModernGL, GLAbstraction, GLWindow, GLFW, React, ImmutableArrays, Images, GLText, Quaternions
using GLPlot

window  = createwindow("test", 1000, 800, windowhints=[(GLFW.SAMPLES, 0)], debugging=false)
cam     = PerspectiveCamera(window.inputs, Vec3(1,0,0), Vec3(0))

sourcedir = Pkg.dir()*"/GLPlot/src/"
shaderdir = sourcedir*"shader/"


fb = glGenFramebuffers()
glBindFramebuffer(GL_FRAMEBUFFER, fb)

parameters = [
  (GL_TEXTURE_WRAP_S,  GL_CLAMP_TO_EDGE),
  (GL_TEXTURE_WRAP_T,  GL_CLAMP_TO_EDGE),
  (GL_TEXTURE_MIN_FILTER, GL_NEAREST),
  (GL_TEXTURE_MAG_FILTER, GL_NEAREST)
]

color   = Texture(GLfloat, 3, window.inputs[:window_size].value[3:4], format=GL_RGB, internalformat=GL_RGB8)
depth   = Texture(GLfloat, 1, window.inputs[:window_size].value[3:4], format=GL_DEPTH_COMPONENT, internalformat=GL_DEPTH_COMPONENT32F, parameters=parameters)

glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, color.id, 0)
glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, depth.id, 0)


ocam = OrthographicCamera(window.inputs)

vsh = "
#version 130
in vec2 vertex;

void main() {
gl_Position = vec4(vertex, 0.0, 1.0);
}
"

fsh = "
#version 130

out vec4 frag_color;

void main() {
frag_color = vec4(1.0, 0.0, 1.0, 1.0);
}
"

triangle = RenderObject(
  [
    :vertex  => GLBuffer(Float32[0.0, 0.5, 0.5, -0.5, -0.5,-0.5], 2),
    :indexes => indexbuffer(GLuint[0,1,2])
  ],
  GLProgram(vsh, fsh, "vertex", "fragment"))
postrender!(triangle, render, triangle.vertexarray)

v, uv, indexes = genquad(-1f0, -1f0, 2f0, 2f0)

data = [
  :vertex           => GLBuffer(v, 2),
  :uv               => GLBuffer(uv, 2),
  :index            => indexbuffer(indexes),
  :color            => color,
  :depth            => depth,
  :anti_aliasing_on => convert(GLint, 1)
]

obj = RenderObject(data, TemplateProgram("standard.vert", "texture.frag"))

prerender!(obj, glDisable, GL_DEPTH_TEST, enabletransparency,  glDisable, GL_CULL_FACE)
postrender!(obj, render, obj.vertexarray)

glClearDepth(1)
glEnable(GL_DEPTH_TEST)
while !GLFW.WindowShouldClose(window.glfwWindow)

  glBindFramebuffer(GL_FRAMEBUFFER, fb)
  glDrawBuffers(1, [GL_COLOR_ATTACHMENT0, GL_DEPTH_ATTACHMENT])
  glClearColor(1,1,1,0)
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
  glEnable(GL_DEPTH_TEST)

  render(triangle)

  glBindFramebuffer(GL_FRAMEBUFFER, 0)
  glClearColor(0,0,0,0)

  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
  render(obj)
 

  yield() # this is needed for react to work
  GLFW.SwapBuffers(window.glfwWindow)
  GLFW.PollEvents()
end
GLFW.Terminate()
