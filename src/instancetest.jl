using GLWindow, GLUtil, ModernGL, ImmutableArrays, GLFW, React, Images




global const window = createwindow("Mesh Display", 1000, 1000, debugging = false)
const cam = Cam(window.inputs, Vector3(1.9f0, 1.9f0, 1.0f0))

function gauss(x, y)
    factor = 1 / (2*pi)
    exponent = -( ((x^2) + (y^2))/ 2)
    factor * exp(exponent)
end
function gauss(x, mu, sigma)
    factor = 1 / (2*pi*sigma^2)
    exponent = -((x - mu)^2 / 2*(sigma^2))
    factor * exp(exponent)
end
function zdata(x1, y1, factor)
    x = (x1 - 0.5) * factor
    y = (y1 - 0.5) * factor

    Vector1(float32((gauss(x, y) *5f0) ))
    #Vector1(float32(sin(10(x^2+y^2))/10) * 1.5f0)
end
function zcolor(z)
    Vector4(z[1] , z[1] , z[1] * 5, 1f0)
end
const N = 25
texsize = Vector2(N)
const texdata = [zdata(i/N, j/N, 5) for i=1:N, j=1:N]
const colordata = map(zcolor, texdata)



ztex       = Texture(texdata, internalformat = GL_R32F, format=GL_RED)
colortex   = Texture(colordata)

key        = keepwhen(lift(x -> x == 1, Bool,window.inputs[:keypressedstate]), 0, window.inputs[:keypressed])



const vertexes, uv, normals, indexes = gencubenormals(
        Vector3{Float32}(0,0,0), Vector3{Float32}(0.05, 0, 0), Vector3{Float32}(0, 0.05, 0), Vector3{Float32}(0,0,1)
    )

const data = RenderObject([
    :vertex         => GLBuffer(vertexes, 3),
    :normal         => GLBuffer(normals, 3),
    :index          => GLBuffer(indexes, 1, buffertype = GL_ELEMENT_ARRAY_BUFFER),
    :ztex           => ztex,
    :colortex       => colortex,
    :texsize        => convert(Vector2{Float32}, texsize),
    :projection     => cam.projection,
    :view           => cam.view,
    :normalmatrix   => cam.normalmatrix,
    :light_position => Float32[-800, -800, 800]
], GLProgram(vert, phongfrag, "lol"))


postrender!(data, renderinstanced, data.vertexarray, N*N)

include("grid.jl")

glClearColor(1,1,1,0)

glEnable(GL_DEPTH_TEST)
glDepthFunc(GL_LESS)

glDisable(GL_CULL_FACE)
while !GLFW.WindowShouldClose(window.glfwWindow)

  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

  render(data)
  render(axis)

  GLFW.SwapBuffers(window.glfwWindow)
  GLFW.PollEvents()

end
GLFW.Terminate()
