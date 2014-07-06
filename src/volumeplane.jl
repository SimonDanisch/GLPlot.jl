using GLWindow, GLUtil, ModernGL, ImmutableArrays, GLFW, React, Images

framebuffdims = [512,512]
window = createwindow("Mesh Display", framebuffdims..., debugging = false)
cam = Cam(window.inputs, Vector3(1.5f0, 1.5f0, 1.0f0))

shaderdir = Pkg.dir()*"/GLPlot/src/shader/"
shader = GLProgram(shaderdir*"planecut")

N = 128
volume = Float32[sin(x / 4f0)+sin(y / 4f0)+sin(z / 4f0) for x=1:N, y=1:N, z=1:N]
max = maximum(volume)
min = minimum(volume)
volume = (volume .- min) ./ (max .- min)
volume = map(x -> Vector4(uint8(x * 255)), volume)


texparams = [
   (GL_TEXTURE_MIN_FILTER, GL_LINEAR),
  (GL_TEXTURE_MAG_FILTER, GL_LINEAR),
  (GL_TEXTURE_WRAP_S,  GL_CLAMP_TO_EDGE),
  (GL_TEXTURE_WRAP_T,  GL_CLAMP_TO_EDGE),
  (GL_TEXTURE_WRAP_R,  GL_CLAMP_TO_EDGE)

]

verts, uv, indexes = genquad(Vector3(0f0), Vector3(0f0,1f0,1f0), Vector3(1f0,0f0,0f0))

keypressed = keepwhen(lift(x-> x==1 ,Bool, window.inputs[:keypressedstate]) ,0,window.inputs[:keypressed])
modelv 	= foldl((a,b) -> begin
				if b == GLFW.KEY_O
					return a - Vector3(0.01f0, 0f0, 0f0)
				elseif b == GLFW.KEY_P
					return a + Vector3(0.01f0, 0f0, 0f0)
				end
				a
			end, Vector3(0f0), keypressed)

modelm = lift(translatematrix, Matrix4x4{Float32}, modelv)

planedata = [
:vertex 	=> GLBuffer(verts, 3),
:index 		=> indexbuffer(indexes),
:volume_tex => Texture(volume, internalformat=GL_RGBA8, format=GL_RGBA, parameters=texparams),
:view 		=> cam.view,
:projection => cam.projection,
:model 		=> modelm
]
plane = RenderObject(planedata, shader)
prerender!(plane, enabletransparency)
postrender!(plane, render, plane.vertexarray)

glClearColor(1,1,1,1)
glClearDepth(1)

while !GLFW.WindowShouldClose(window.glfwWindow)


  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

  render(plane)

  GLFW.SwapBuffers(window.glfwWindow)
  GLFW.PollEvents()
  sleep(0.01)
end
GLFW.Terminate()
