using GLWindow, GLUtil, ModernGL, ImmutableArrays, GLFW, React, Images

framebuffdims = [800, 500]
window    = createwindow("Mesh Display", framebuffdims..., debugging = false)
cam       = Cam(window.inputs, Vector3(0f0, 3.5f0, 0f0))

shaderdir = Pkg.dir()*"/GLPlot/src/shader/"



volumeshader              = GLProgram(shaderdir*"simple.vert", shaderdir*"iso.frag")
uvwshader           = GLProgram(shaderdir*"uvwposition")


fb = glGenFramebuffers()


function createvolume(img::Image; cropDimension=1:256, shader = volumeshader )
  volume = img.data
  max = maximum(volume)
  min = minimum(volume)

  volume = float32((volume .- min) ./ (max - min))
  createvolume(volume, shader = shader)
end
function createvolume(img::Array; spacing = [1f0, 1f0, 1f0], shader = volumeshader )
  texparams = [
     (GL_TEXTURE_MIN_FILTER, GL_NEAREST),
    (GL_TEXTURE_MAG_FILTER, GL_NEAREST),
    (GL_TEXTURE_WRAP_S,  GL_CLAMP_TO_EDGE),
    (GL_TEXTURE_WRAP_T,  GL_CLAMP_TO_EDGE),
    (GL_TEXTURE_WRAP_R,  GL_CLAMP_TO_EDGE)
  ]

  v, uvw, indexes = gencube(1f0, 1f0, 1f0)
  cubedata = [
      :vertex         => GLBuffer(v, 3),
      :uvw            => GLBuffer(uvw, 3),
      :indexes        => GLBuffer(indexes, 1, buffertype = GL_ELEMENT_ARRAY_BUFFER),
      :projectionview => cam.projectionview
  ]
  cube1,frontf1, backf1 = genuvwcube(1f0, 1f0, 1f0 )
  cube2,frontf2, backf2 = genuvwcube(0.1f0, 1f0, 1f0)
  delete!(cubedata, :uvw)

  cubedata[:frontface1]    = frontf1
  cubedata[:backface1]     = backf1
  cubedata[:backface2]     = backf2
  cubedata[:frontface2]    = frontf2

  cubedata[:volume_tex]    = Texture(img, 1, parameters=texparams)
  cubedata[:stepsize]      = 0.002f0
  cubedata[:isovalue]      = 0.5f0
  cubedata[:algorithm]     = 2f0

  cubedata[:light_position] = Vec3(2, 2, -2)
  volume = RenderObject(cubedata, shader)

  rendertouvwtexture = () -> begin
    render(cube1)
    render(cube2)
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
  end
  prerender!(volume, rendertouvwtexture, glEnable, GL_DEPTH_TEST, glEnable, GL_CULL_FACE, glCullFace, GL_BACK, enabletransparency)
  postrender!(volume, render, volume.vertexarray)
  volume

end
function createvolume(dirpath::String; cropDimension = 1:256, shader = volumeshader )
  files     = readdir(dirpath)
  imgSlice1   = imread(dirpath*files[1])
  volume    = Array(Uint16, size(imgSlice1,1), size(imgSlice1,2), length(files))
  imgSlice1 = 0
  for (i,elem) in enumerate(files)
    img = imread(dirpath*elem)
    volume[:,:, i] = img.data
  end
  max = maximum(volume)
  min = minimum(volume)

  volume = float32((volume .- min) ./ (max - min))
  volume = volume[cropDimension, cropDimension, cropDimension]
  createvolume(volume, shader = shader)
end

function genuvwcube(x,y,z)
  v, uvw, indexes = gencube(x,y,z)
  cubeobj = RenderObject([
    :vertex         => GLBuffer(v, 3),
    :uvw            => GLBuffer(uvw, 3),
    :indexes        => indexbuffer(indexes),
    :projectionview => cam.projectionview
  ], uvwshader)

  frontface = Texture(GLfloat, 4, framebuffdims)
  backface  = Texture(GLfloat, 4, framebuffdims)

  lift(windowsize -> begin
    glBindTexture(texturetype(frontface), frontface.id)
    glTexImage(0, frontface.internalformat, windowsize..., 0, frontface.format, frontface.pixeltype, C_NULL)
    glBindTexture(texturetype(backface), backface.id)
    glTexImage(0, backface.internalformat, windowsize..., 0, backface.format, backface.pixeltype, C_NULL)
  end, window.inputs[:window_size])

  rendersetup = () -> begin
      glBindFramebuffer(GL_FRAMEBUFFER, fb)
      glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, backface.id, 0)
      glClearColor(1,1,1,0)
      glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

      glDisable(GL_DEPTH_TEST)
      glEnable(GL_CULL_FACE)
      glCullFace(GL_FRONT)
      render(cubeobj.vertexarray)

      glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, frontface.id, 0)
      glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

      glDisable(GL_DEPTH_TEST)
      glEnable(GL_CULL_FACE)
      glCullFace(GL_BACK)
      render(cubeobj.vertexarray)

      glBindFramebuffer(GL_FRAMEBUFFER, 0)
  end

  postrender!(cubeobj, rendersetup)

  cubeobj, frontface, backface

end


N = 56
volume = Float32[sin(x / 4f0)+sin(y / 4f0)+sin(z / 4f0) for x=1:N, y=1:N, z=1:N]
max = maximum(volume)
min = minimum(volume)
volume = (volume .- min) ./ (max .- min)


cube = createvolume("example/")

glClearColor(0,0,0,1)
glClearDepth(1)

include("grid.jl")
while !GLFW.WindowShouldClose(window.glfwWindow)

  render(cube)
  render(axis)

  GLFW.SwapBuffers(window.glfwWindow)
  GLFW.PollEvents()
  sleep(0.1)
end
GLFW.Terminate()
