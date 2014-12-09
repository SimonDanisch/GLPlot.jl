function initvolume()
  const global volumeshader = TemplateProgram(shaderdir*"simple.vert"     , shaderdir*"iso.frag")
  const global uvwshader    = TemplateProgram(shaderdir*"uvwposition.vert", shaderdir*"uvwposition.frag")
   
  const global uvwposition_framebuffer = glGenFramebuffers() 
end
init_after_context_creation(initvolume)


function toopengl{T <: Real}(img::Array{T, 3}; 
      spacing = [1f0, 1f0, 1f0], stepsize=0.001f0, isovalue=0.5f0, algorithm=2f0, 
      color=Vec3(0,0,1), lightposition=Vec3(2, 2, -2),
      camera=pcamera
    )
  v, uvw, indexes = gencube(spacing...)

  cubedata = [
      :vertex         => GLBuffer(v, 3),
      :uvw            => GLBuffer(uvw, 3),
      :indexes        => GLBuffer(indexes, 1, buffertype = GL_ELEMENT_ARRAY_BUFFER),
      :projectionview => camera.projectionview
  ]
  

  cube1,frontf1, backf1 = genuvwcube(1f0, 1f0, 1f0, uvwposition_framebuffer, camera)
  cube2,frontf2, backf2 = genuvwcube(0.1f0, 1f0, 1f0, uvwposition_framebuffer, camera)

  delete!(cubedata, :uvw)

  cubedata[:frontface1]     = frontf1
  cubedata[:backface1]      = backf1
  cubedata[:backface2]      = backf2
  cubedata[:frontface2]     = frontf2
  cubedata[:volume_tex]     = Texture(img)

  cubedata[:stepsize]       = stepsize
  cubedata[:isovalue]       = isovalue
  cubedata[:algorithm]      = algorithm
  cubedata[:color]          = color

  cubedata[:light_position] = lightposition

  volume = RenderObject(cubedata, volumeshader)

  rendertouvwtexture = () -> begin
    render(cube1)
    render(cube2)
    glBindFramebuffer(GL_FRAMEBUFFER, 0)

  end
  prerender!(volume, rendertouvwtexture, glEnable, GL_DEPTH_TEST, glDepthFunc, GL_LESS, glEnable, GL_CULL_FACE, glCullFace, GL_BACK, enabletransparency)
  postrender!(volume, render, volume.vertexarray)
  volume
end



function genuvwcube(x, y, z, fb, camera)
  v, uvw, indexes = gencube(x,y,z)
  cubeobj = RenderObject(@compat(Dict(
    :vertex         => GLBuffer(v, 3),
    :uvw            => GLBuffer(uvw, 3),
    :indexes        => indexbuffer(indexes),
    :projectionview => camera.projectionview
  )), uvwshader)
  frontface = Texture(Vec4, [window.inputs[:framebuffer_size].value...])
  backface  = Texture(Vec4, [window.inputs[:framebuffer_size].value...])

  lift(window.inputs[:framebuffer_size]) do window_size
    resize!(frontface, [window_size...])
    resize!(backface, [window_size...])
    nothing
  end
  
  rendersetup = () -> begin
      glBindFramebuffer(GL_FRAMEBUFFER, fb)

      glViewport(0,0,window.inputs[:framebuffer_size].value...)
      glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, backface.id, 0)
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

