using GLPlot
using Base.Test

using GLWindow, GLAbstraction, ModernGL, ImmutableArrays, GLFW, React, Images, ModernGL, GLPlot

global const window = createwindow("Mesh Display", 1000, 1000, debugging = false) # debugging just works on linux and windows
const cam = Cam(window.inputs, Vector3(2.0f0, 0f0, 0f0))

initplotting()


img = toopengl(Texture([Vec4(i/512,j/512,0,1)for i=1:512, j=1:512])) # any array works for texture

function zdata(x1, y1, factor)
    x = (x1 - 0.5) * 15
    y = (y1 - 0.5) * 15
    Vec1((sin(x) + cos(y)) / 10)
end
function zcolor(z)
    a = Vec4(0,1,0,1)
    b = Vec4(1,0,0,1)
    return mix(a,b,z[1]*5)
end

N = 128
texdata = [zdata(i/N, j/N, 5) for i=1:N, j=1:N]
colordata = map(zcolor , texdata)
color = lift(x-> Vec4(sin(x), 0,1,1), Vec4, Timing.every(0.1)) # Example on how to use react to change the color over time

obj = toopengl(texdata, primitive=CIRCLE(), color=colordata) # Color can be any matrix or a Vec3

N = 128
volume = Float32[sin(x / 12f0)+sin(y / 12f0)+sin(z / 12f0) for x=1:N, y=1:N, z=1:N]
max = maximum(volume)
min = minimum(volume)
volume = (volume .- min) ./ (max .- min)

#Filter keydown events
keypressed = window.inputs[:buttonspressed]

obj2 = toopengl(volume, algorithm=2f0, isovalue=0.5f0, stepsize=0.005f0, color=Vec3(1,0,0))

glClearColor(1,1,1,0)

runner = 0.0
while !GLFW.WindowShouldClose(window.glfwWindow)

  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
  render(img)

  render(obj)
  render(obj2)
  render(GRID)
  
  yield() # this is needed for react to work

  GLFW.SwapBuffers(window.glfwWindow)
  GLFW.PollEvents()

end
GLFW.Terminate()
