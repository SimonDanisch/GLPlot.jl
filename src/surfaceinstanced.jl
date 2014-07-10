using GLWindow, GLUtil, ModernGL, ImmutableArrays, GLFW, React, Images


global const window = createwindow("Mesh Display", 1000, 1000, debugging = false)
const cam = Cam(window.inputs, Vector3(1.9f0, 1.9f0, 1.0f0))
shaderdir = Pkg.dir()*"/GLPlot/src/shader/"

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
    x = (x1 - 0.5) * 2
    y = (y1 - 0.5) * 2

    Vector4(float32(sin(10(x^2+y^2))/10) * 1.5f0,  0f0, 0f0, 0f0)
end
function zcolor(z)
    Vector4(z[1] , z[1] , z[1] * 5, 1f0)
end


N = 50
texsize = Vector2(N)
texdata = [zdata(i/N, j/N, 5) for i=1:N, j=1:N]

colordata = map(zcolor, texdata)
w, h = size(texdata)
for x=1:w, y=1:h
  xf = float32(x / w)
  yf = float32(y / h)
  zf = float32(texdata[x,y][1])
  current = Vector3(xf, yf, zf)
  #calculate indexes for surrounding zvalues
  indexes = [(x+1,y), (x,y+1), (x+1,y+1),
             (x-1,y), (x,y-1), (x-1,y-1)]
  #Remove out of bounds
  filter!(elem -> elem[1] >= 1 && elem[2] >= 1 && elem[1] <= w && elem[2] <= h, indexes)
  #Construct the full surrounding vectors with x,y,z coordinates
  kneighbours = map(elem -> Vector3(xf+ float32(elem[1] / w), yf+ float32(elem[2] / h), texdata[elem...][1]), indexes)
  kdiffs = map(elem -> current - elem, kneighbours)
  #normals = reduce((v0, a) -> push!(v0, cross(a,v0[end])), Vector3{Float32}[kdiffs[end]], kdiffs[1:end-1])

  #get the some of the cross with the current vector and normalize
  #normal = unit(sum(map(x -> cross(current,x), kneighbours)))
  normal = unit( cross(kdiffs[1],kdiffs[2]))
  #=normal = unit( reduce( (v0, a) -> begin
                              res = cross(a, v0[end])
                              push!(v0, a)

                            end, Vector3{Float32}[kdiffs[1]], kdiffs[2:end]))=#

  texdata[x,y] = Vector4(zf, normal...)
end

texparams = [
   (GL_TEXTURE_MIN_FILTER, GL_LINEAR),
  (GL_TEXTURE_MAG_FILTER, GL_LINEAR),
  (GL_TEXTURE_WRAP_S,  GL_CLAMP_TO_EDGE),
  (GL_TEXTURE_WRAP_T,  GL_CLAMP_TO_EDGE)
 ]

ztex       = Texture(texdata, internalformat = GL_RGBA32F, format=GL_RGBA, parameters = texparams)
colortex   = Texture(colordata, parameters = texparams)


const datainstanced = RenderObject([
    :offset         => GLBuffer(Float32[0,0, 0,1, 1,1, 1,0], 2),
    :index          => GLBuffer(GLuint[0,1,2,2,3,0], 1, buffertype = GL_ELEMENT_ARRAY_BUFFER),
    :ztex           => ztex,
    #:colortex       => colortex,
    #:texsize        => convert(Vector2{Float32}, texsize),
    :projection     => cam.projection,
    :view           => cam.view,
    :normalmatrix   => cam.normalmatrix,
    :light_position => Float32[800, 800, -800]
], GLProgram(shaderdir*"instanced.vert", shaderdir*"phongblinn.frag"))


prerender!(datainstanced, glEnable, GL_DEPTH_TEST)
postrender!(datainstanced, renderinstanced, datainstanced.vertexarray, N*N)

xyz = Array(Vector3{Float32}, N*N)
index = 1
for x=1:N, y=1:N
  x1 = (x / N) 
  y1 = (y / N)
  xyz[index] = Vector3{Float32}(x1, y1, sin(10f0*((((x1- 0.5f0) * 2)^2) + ((y1 - 0.5f0) * 2)^2))/10f0)
  index += 1
end
normals     = Array(Vector3{Float32}, N*N)
binormals   = Array(Vector3{Float32}, N*N)
tangents    = Array(Vector3{Float32}, N*N)
indices     = Vector3{GLuint}[]
for i=1:(N*N) - N - 1
  if i%N != 0
     a = Vector3{GLuint}(i    , i+N, i+N+1) - 1
     b = Vector3{GLuint}(i+N+1, i+1, i   ) - 1
     push!(indices, a)
     push!(indices, b)
  end
end
for i=1:length(normals)
  #indices = [i-1, i+1, i-N, i+N, i-1 + N, i+1 +N, i-1 - N, i+1-N]
  a = xyz[i]
  b = i > 1 ? xyz[i-1] : xyz[i+1]
  c = i + N > N*N ? xyz[i-N] : xyz[i+N]

  Tt = a-b
  Bt = a-c
  Nt = cross(Tt, Bt)

  tangents[i]    = Tt / norm(Tt)
  binormals[i]   = Bt / norm(Bt)
  normals[i]     = Nt / norm(Nt)
end
mesh =
[
   :indexes       => GLBuffer{GLuint}(convert(Ptr{GLuint},   pointer(indices)),   sizeof(indices),    1, GL_ELEMENT_ARRAY_BUFFER, GL_STATIC_DRAW),
   :vertex        => GLBuffer{Float32}(convert(Ptr{Float32}, pointer(xyz)),       sizeof(xyz),        3, GL_ARRAY_BUFFER, GL_STATIC_DRAW),
   :normal        => GLBuffer{Float32}(convert(Ptr{Float32}, pointer(normals)),   sizeof(normals),    3, GL_ARRAY_BUFFER, GL_STATIC_DRAW),

   :view          => cam.view,
   :projection    => cam.projection,
   :normalmatrix  => lift( x -> begin
                           m = Matrix3x3(x)
                           tmp    = zeros(Float32, 3,3)
                           tmp[1, 1:3] = [m.c1...]
                           tmp[2, 1:3] = [m.c2...]
                           tmp[3, 1:3] = [m.c3...]
                           inv(tmp)'
                        end , Array{Float32, 2}, cam.projectionview),
   :light_position   => Float32[-800, -800, 0],
]
# The RenderObject combines the shader, and Integrates the buffer into a VertexArray
 #mesh = RenderObject(mesh, GLProgram(shaderdir*"standard.vert", shaderdir*"phongblinn.frag"))
#prerender!(mesh, glEnable, GL_DEPTH_TEST)
#postrender!(mesh, render, mesh.vertexarray)



glClearColor(1,1,1,0)

while !GLFW.WindowShouldClose(window.glfwWindow)
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

  #tic()
  #render(mesh)
  #toc()
  render(datainstanced)

  GLFW.SwapBuffers(window.glfwWindow)
  GLFW.PollEvents()
end
GLFW.Terminate()
