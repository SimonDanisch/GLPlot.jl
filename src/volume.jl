
const volumeshader        = TemplateProgram(shaderdir*"simple.vert", shaderdir*"iso.frag")
const uvwshader           = TemplateProgram(shaderdir*"uvwposition.vert", shaderdir*"uvwposition.frag")


fb = glGenFramebuffers()


function toopengl{T,A}(img::Image{T, 3, A}; shader = volumeshader, stepsize=0.002f0, isovalue=0.8, algorithm=2f0, color=Vec4(0,0,1,1))
  volume = img.data
  max = maximum(volume)
  min = minimum(volume)
  volume = float32((volume .- min) ./ (max - min))
  spacing = get(img.properties, "spacing", [1f0, 1f0, 1f0])
  
  toopengl(volume, shader = shader, stepsize=stepsize, isovalue=isovalue, algorithm=algorithm, color=color)
end

function toopengl{T <: Real}(img::Array{T, 3}; spacing = [1f0, 1f0, 1f0], shader=volumeshader, stepsize=0.002f0, isovalue=0.8, algorithm=2f0, color=Vec4(0,0,1,1))
  texparams = [
     (GL_TEXTURE_MIN_FILTER, GL_LINEAR),
    (GL_TEXTURE_MAG_FILTER, GL_LINEAR),
    (GL_TEXTURE_WRAP_S,  GL_CLAMP_TO_EDGE),
    (GL_TEXTURE_WRAP_T,  GL_CLAMP_TO_EDGE),
    (GL_TEXTURE_WRAP_R,  GL_CLAMP_TO_EDGE)
  ]

  v, uvw, indexes = gencube(spacing...)
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
  cubedata[:stepsize]      = stepsize
  cubedata[:isovalue]      = isovalue
  cubedata[:algorithm]     = algorithm
  cubedata[:color]         = color

  cubedata[:light_position] = Vec3(2, 2, -2)
  volume = RenderObject(cubedata, shader)

  rendertouvwtexture = () -> begin
    render(cube1)
    render(cube2)
    glBindFramebuffer(GL_FRAMEBUFFER, 0)

  end
  prerender!(volume, rendertouvwtexture, glEnable, GL_DEPTH_TEST, glDepthFunc, GL_LESS, glEnable, GL_CULL_FACE, glCullFace, GL_BACK, enabletransparency)
  postrender!(volume, render, volume.vertexarray)
  volume

end
function toopengl(dirpath::String; shader = volumeshader, stepsize=0.002f0, isovalue=0.8, algorithm=2f0, color=Vec4(0,0,1,1))
  files     = readdir(dirpath)
  imgSlice1 = imread(dirpath*files[1])
  volume    = Array(Uint16, size(imgSlice1,1), size(imgSlice1,2), length(files))
  imgSlice1 = 0
  for (i,elem) in enumerate(files)
    img = imread(dirpath*elem)
    volume[:,:, i] = img.data
  end
  max = maximum(volume)
  min = minimum(volume)

  volume = float32((volume .- min) ./ (max - min))
  volume = volume
  toopengl(volume, shader = shader, stepsize=stepsize, isovalue=isovalue, algorithm=algorithm, color=color)
end

function genuvwcube(x,y,z)
  v, uvw, indexes = gencube(x,y,z)
  cubeobj = RenderObject([
    :vertex         => GLBuffer(v, 3),
    :uvw            => GLBuffer(uvw, 3),
    :indexes        => indexbuffer(indexes),
    :projectionview => cam.projectionview
  ], uvwshader)

  frontface = Texture(GLfloat, 4, window.inputs[:window_size].value)
  backface  = Texture(GLfloat, 4, window.inputs[:window_size].value)

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

  end

  postrender!(cubeobj, rendersetup)

  cubeobj, frontface, backface
end

