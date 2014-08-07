using GLWindow, GLAbstraction, ModernGL, ImmutableArrays, GLFW, React, Images, ModernGL, GLPlot

global const window = createwindow("Mesh Display", 1000, 1000, debugging = false) # debugging just works on linux and windows
const cam = Cam(window.inputs, Vector3(5.0f0, 0.0f0, 0f0), Vector3(0.5f0, 0.5f0, 0f0))
const camR = Cam(window.inputs, Vector3(5.0f0, 0.2f0, 0f0), Vector3(0.5f0, 0.5f0, 0f0))

initplotting()


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

#obj = toopengl(texdata) # This is the base case, where the Matrix is simply mapped as a surface, with white color
objL = toopengl(texdata, primitive=SURFACE(), color=Vec4(1,1,1,1)) # Color can be any matrix or a Vec3
objR = toopengl(texdata, primitive=SURFACE(), color=Vec4(1,1,1,1), projection=camR.projection, view=camR.view, normalmatrix=camR.normalmatrix) # Color can be any matrix or a Vec3

glClearColor(0,0,0,0)
glClearDepth(1)
function renderloop()
  glEnable(GL_BLEND);
  
  glColorMask(true, false, false, true)
  render(objL)
  glColorMask(false, true, true, true)
  glClear(GL_DEPTH_BUFFER_BIT)
  glBlendFunc(GL_ONE, GL_ONE)
  render(objR)
  glColorMask(true, true, true, true)

end

#@async begin # can be used in REPL
while !GLFW.WindowShouldClose(window.glfwWindow)
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
  renderloop()
  yield() # this is needed for react to work
  GLFW.SwapBuffers(window.glfwWindow)
  GLFW.PollEvents()
end

GLFW.Terminate()
#end


