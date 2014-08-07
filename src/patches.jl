using GLWindow, GLAbstraction, GLFW, ModernGL

global const window = createwindow("Mesh Display", 1000, 1000, debugging = false) # debugging just works on linux and windows
const cam = Cam(window.inputs, Vector3(2.0f0, 0f0, 0f0))




glClearColor(1,1,1,0)
while !GLFW.WindowShouldClose(window.glfwWindow)

  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

  render(obj)
  #render(axis)
  yield() # this is needed for react to work
  GLFW.SwapBuffers(window.glfwWindow)
  GLFW.PollEvents()

end
GLFW.Terminate()



