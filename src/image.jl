using GLWindow, GLUtil, ModernGL, ImmutableArrays, GLFW, React, Images

framebuffdims = [1500, 1500]
window  = createwindow("Mesh Display", framebuffdims..., debugging = true)
cam     = Cam(window.inputs, Vector3(1.5f0, 1.5f0, 1.0f0))

shaderdir = Pkg.dir()*"/GLPlot/src/shader/"
vert = "
#version 130
in vec2 vertex;
in vec2 uv;

out vec2 uv_frag;

uniform mat4 projectionview;
void main(){
  uv_frag = uv;
  gl_Position = projectionview * vec4(vertex, 0, 1);
}

"
frag = "
#version 130
in vec2 uv_frag;

out vec4 frag_color;

uniform sampler2D image;

void main(){
  frag_color = texture(image, uv_frag);
}

"

shader              = GLProgram(vert, frag, "vert", "frag")



camposition = Input(Vec3(0))
camdims    = window.inputs[:window_size]
#lift(x -> glViewport(0,0, x...) ,camdims)

projection = lift(wh -> begin
  @assert wh[2] > 0
  @assert wh[1] > 0

  wh = wh[1] > wh[2] ? ((wh[1]/wh[2]), 1f0) : (1f0,(wh[2]/wh[1]))
                    println(wh)
  orthographicprojection(0f0, float32(wh[1]), 0f0, float32(wh[2]), -1f0, 10f0)
end, Mat4, camdims)

view = lift(translatematrix , Mat4, camposition)
projectionview = @lift projection * view

texparams = [
   (GL_TEXTURE_MIN_FILTER, GL_LINEAR),
  (GL_TEXTURE_MAG_FILTER, GL_LINEAR),
  (GL_TEXTURE_WRAP_S,  GL_CLAMP_TO_EDGE),
  (GL_TEXTURE_WRAP_T,  GL_CLAMP_TO_EDGE),
  (GL_TEXTURE_WRAP_R,  GL_CLAMP_TO_EDGE)
]

function GLUtil.render{T, D}(img::Texture{T, D, 2})
  c, w, h  = img.dims
  dims = w > h ? (float32((w/h)), 1f0) : (1f0, float32((h/w)))
  v, uv, indexes = genquad(0f0, 0f0,dims...)
  data = RenderObject([
    :vertex         => GLBuffer(v, 2),
    :index          => indexbuffer(indexes),
    :uv             => GLBuffer(v, 2),
    :image          => img,
    :projectionview     => projectionview,
  ], shader)

  prerender!(data, glDisable, GL_DEPTH_TEST, enabletransparency)
  postrender!(data, render, data.vertexarray)
  data
end
test = render(Texture(Pkg.dir()"/GLPlot/src/test.jpg"))

glClearColor(1,1,1,1)
glClearDepth(1)
while !GLFW.WindowShouldClose(window.glfwWindow)

  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

  render(test)
  GLFW.SwapBuffers(window.glfwWindow)
  GLFW.PollEvents()
  sleep(0.1)
end
GLFW.Terminate()
