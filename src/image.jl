const textureshader = TemplateProgram(shaderdir*"uv_vert.vert", shaderdir*"texture.frag")


function toopengl{T, D}(img::Texture{T, D, 2}; camera = OrthographicCamera(window.inputs))

  c, w, h  = img.dims
  dims = w > h ? (float32((w/h)), 1f0) : (1f0, float32((h/w)))
  v, uv, indexes = genquad(0f0, 0f0,dims...)
  data = RenderObject([
    :vertex           => GLBuffer(v, 2),
    :index            => indexbuffer(indexes),
    :uv               => GLBuffer(v, 2),
    :image            => img,
    :projectionview   => camera.projectionview,
  ], textureshader)

  prerender!(data, glDisable, GL_DEPTH_TEST, enabletransparency,  glDisable, GL_CULL_FACE)
  postrender!(data, render, data.vertexarray)
  data
end
