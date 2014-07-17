using GLWindow, GLUtil, ModernGL, ImmutableArrays, GLFW, React, Images


global const window = createwindow("Mesh Display", 1000, 1000, debugging = true)
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

    vec1(sin(10*(x^2+y^2))/15f0)
end
function zcolor(z)
    vec4(1 - (z[1] * 5), 0 , z[1] * 5, 1)
end

function sliding{T}(f, neighbours, a::AbstractArray{T,2})
  window = Array(T, length(neighbours))
  [
    begin
      for k=1:length(window)
        elem = neighbours[k]
        println(elem)
        x1 = i + elem[1]
        y1 = j + elem[2]
        x1 = x1 < 1 ? 1 : x1
        x1 = x1 > size(a,1) ? size(a,1) : x1
        y1 = y1 < 1 ? 1 : y1
        y1 = y1 > size(a,2) ? size(a,2) : y1
        window[k] = a[x1,y1]
      end
      f(window)
    end
    for i=1:size(a, 1), j=1:size(a, 2)
  ]
end
N = 200
texdata = [zdata(i/N, j/N, 5) for i=1:N, j=1:N]

colordata = map(zcolor , texdata)
function stretch(x, r::Range, normalizer = 1)
  T = typeof(x)
  convert(T, first(r) + ((x / normalizer) * (last(r) - first(r))))
end

function normal(A, xrange, yrange)
  w,h = size(A)
  result = Array(Vector3{eltype(A[1])}, w,h)
  for x=1:w, y=1:h
    xs = stretch(float32(x), xrange, w)
    ys = stretch(float32(y), yrange, h)
    zs = A[x,y][1]

    current = Vector3(xs, ys, zs)
    #calculate indexes for surrounding zvalues
    indexes = [(x+1,y), (x,y+1), (x+1,y+1),
               (x-1,y), (x,y-1), (x-1,y-1)]
    #Remove out of bounds
    map!(elem -> begin
      xx = elem[1] < 1 ? 1 : elem[1] 
      xx = elem[1] > w ? w : xx 

      yy = elem[2] < 1 ? 1 : elem[2] 
      yy = elem[2] > h ? h : yy 
      (xx,yy)
    end, indexes)
    #Construct the full surrounding difference vectors with x,y,z coordinates
    differencevecs = map(elem -> begin
      xx = stretch(float32(elem[1]), xrange, w) # treat indexes as coordinates by stretching them to the correct range
      yy = stretch(float32(elem[2]), yrange, h)
      cvec = current - Vector3(xx, yy, A[elem...][1])
    end, indexes)
    #normals = reduce((v0, a) -> push!(v0, cross(a,v0[end])), Vector3{Float32}[kdiffs[end]], kdiffs[1:end-1])

    #get the some of the cross with the current vector and normalize
    #normal = unit(sum(map(x -> cross(current,x), kneighbours)))
    normalvec = unit(reduce((v0, a) -> begin
      a1 = a[2]
      a2 = differencevecs[mod1(a[1] + 1, length(differencevecs))]

      v0 + cross(a1, a2)
    end, vec3(0), enumerate(differencevecs)))
    result[x,y] = normalvec
  end  
  result       
end

normaldata = normal(texdata, 0:1, 0:1)

texparams = [
   (GL_TEXTURE_MIN_FILTER, GL_LINEAR),
  (GL_TEXTURE_MAG_FILTER, GL_LINEAR),
  (GL_TEXTURE_WRAP_S,  GL_CLAMP_TO_EDGE),
  (GL_TEXTURE_WRAP_T,  GL_CLAMP_TO_EDGE)
 ]

ztex       = Texture(texdata, parameters = texparams)
normaltex  = Texture(normaldata, parameters = texparams)
colortex   = Texture(colordata, parameters = texparams)

shader = GLProgram(shaderdir*"instanced.vert", shaderdir*"phongblinn.frag")
println(shader)
const datainstanced = instancedobject([
    :offset         => GLBuffer(Float32[0,0, 0,1, 1,1, 1,0], 2),
    :index          => indexbuffer(GLuint[0,1,2,2,3,0]),
    :ztex           => ztex,
    :normaltex      => normaltex,
    :colortex       => colortex,
    :projection     => cam.projection,
    :view           => cam.view,
    :normalmatrix   => cam.normalmatrix,
    :light_position => vec3(20, 20, -20)
], shader, N*N)



xyz = Array(Vector3{Float32}, N*N)
index = 1
for x=1:N, y=1:N
  x1 = (x / N) 
  y1 = (y / N)
  xyz[index] = Vector3{Float32}(x1, y1, sin(10f0*((((x1- 0.5f0) * 2)^2) + ((y1 - 0.5f0) * 2)^2))/10f0)
  index += 1
end
normals     = Array(vec3, N*N)
binormals   = Array(vec3, N*N)
tangents    = Array(vec3, N*N)
indices     = uivec3[]
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
#=
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
 #The RenderObject combines the shader, and Integrates the buffer into a VertexArray
 mesh = RenderObject(mesh, GLProgram(shaderdir*"standard.vert", shaderdir*"phongblinn.frag"))
prerender!(mesh, glEnable, GL_DEPTH_TEST)
postrender!(mesh, render, mesh.vertexarray)
=#



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
