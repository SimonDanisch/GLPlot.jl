function toopengl{T, D}(img::Texture{T, D, 2}; camera = ocamera, normrange=Vec2(0,1), kernel=1f0, filternorm=1f0, model=eye(Mat4))
  println("Moin")
  w, h  = img.dims
  texparams = [
     (GL_TEXTURE_MIN_FILTER, GL_NEAREST),
    (GL_TEXTURE_MAG_FILTER, GL_NEAREST),
    (GL_TEXTURE_WRAP_S,  GL_CLAMP_TO_EDGE),
    (GL_TEXTURE_WRAP_T,  GL_CLAMP_TO_EDGE)
  ]

  v, uv, indexes = genquad(0f0, 0f0, w, h)
  if typeof(kernel) <: Real
    filterkernel = float32(kernel)
  elseif eltype(kernel) <: AbstractArray
    filterkernel = Texture(kernel, parameters=texparams)
  elseif eltype(kernel) <: Float32
    filterkernel = Texture(reinterpret(Vec1, kernel), parameters=texparams)
  end

  data = [
    :vertex           => GLBuffer(v, 2),
    :index            => indexbuffer(indexes),
    :uv               => GLBuffer(uv, 2),
    :image            => img,
    :normrange        => normrange,
    :filterkernel     => filterkernel,
    :filternorm       => filternorm,
    :projectionview   => camera.projectionview,
    :model            => model
  ]

  fragdatalocation = [(0, "fragment_color"),(1, "fragment_groupid")]
  textureshader = TemplateProgram(joinpath(shaderdir, "uv_vert.vert"), joinpath(shaderdir, "texture.frag"), attributes=data, fragdatalocation=fragdatalocation)

  obj = RenderObject(data, textureshader)

  prerender!(obj, glDisable, GL_DEPTH_TEST, enabletransparency, glDisable, GL_CULL_FACE)
  postrender!(obj, render, obj.vertexarray)

  obj
end

#=
function toopengl{T, D}(img::Texture{T, D, 1}; camera = OrthographicCamera(window.inputs), kernel=1f0, filternorm=1f0, normrange=Vec2(0,1))

  c, w, h  = img.dims
  dims = w > h ? (float32((w/h)), 1f0) : (1f0, float32((h/w)))
  texparams = [
     (GL_TEXTURE_MIN_FILTER, GL_NEAREST),
    (GL_TEXTURE_MAG_FILTER, GL_NEAREST),
    (GL_TEXTURE_WRAP_S,  GL_CLAMP_TO_EDGE),
    (GL_TEXTURE_WRAP_T,  GL_CLAMP_TO_EDGE)
  ]

  v, uv, indexes = genquad(-1f0, -1f0,1f0, 1f0)
  if typeof(kernel) <: Real
    filterkernel = float32(kernel)
  elseif eltype(kernel) <: AbstractArray
    filterkernel = Texture(kernel, parameters=texparams)
  elseif eltype(kernel) <: Real
    filterkernel = Texture(float32(kernel), 1,parameters=texparams)
  end

  data = [
    :vertex           => GLBuffer(v, 2),
    :index            => indexbuffer(indexes),
    :uv               => GLBuffer(uv, 2),
    :image            => img,
    :normrange        => normrange,
    :filterkernel     => filterkernel,
    :filternorm       => filternorm,
    :projectionview   => eye(GLfloat, 4,4)
  ]

  textureshader = TemplateProgram(shaderdir*"uv_vert.vert", shaderdir*"texture.frag", attributes=data)

  obj = RenderObject(data, textureshader)
  prerender!(obj, glDisable, GL_DEPTH_TEST, enabletransparency,  glDisable, GL_CULL_FACE)
  postrender!(obj, render, obj.vertexarray)
  obj
end
=#