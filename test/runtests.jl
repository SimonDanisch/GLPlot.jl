using Base.Test
using GLPlot, GLAbstraction, ModernGL

window = createdisplay(eyeposition=Vec3(2), lookat=Vec3(0.5))

glplot(Vec1[Vec1(sin(i)*sin(j) / 4f0) for i=0:0.1:10, j=0:0.1:10], color = Vec4(1,0,0,1))
glplot(Texture(Vec4[Vec4(sin(i), sin(j), cos(i), sin(j)*cos(i)) for i=1:0.1:12, j=1:0.1:12]))
N = 128

volume = Float32[sin(x / 12f0)+sin(y / 12f0)+sin(z / 12f0) for x=1:N, y=1:N, z=1:N]
glplot(volume, stepsize=0.001f0)

glClearColor(1,1,1,0)
windowsize = window.inputs[:window_size].value[3:4]
for i=1:100
  yield()
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
  for (i,elem) in enumerate(GLPlot.RENDER_LIST)
    if i == 1
      glViewport(0, 0, (windowsize/2)...)
    elseif i == 2
      glViewport(windowsize[1]/2, 0, (windowsize/2)...)
    elseif i == 3
      glViewport(window.inputs[:window_size].value...)
    end
    render(elem)
  end
  GLFW.SwapBuffers(window.nativewindow)
  GLFW.PollEvents()
end
GLFW.Terminate()
println("\033[32;1mSUCCESS\033[0m")