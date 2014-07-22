shaderdir = Pkg.dir()*"/GLPlot/src/shader/"


const textureshader = TemplateProgram(shaderdir*"uv_vert.vert", shaderdir*"texture.frag")

clicked     = lift(tuple, window.inputs[:mousepressed], window.inputs[:mouseposition])

#Really ugly way of diffing and adding up the mouseposition
camposition = keepwhen(window.inputs[:mousepressed], Vec2(0), lift(x->x[1], Vec2, foldl((v0,v1)-> begin 
  if v0[2][1] #-> last position mousebuttondown
    return (v0[1] + Vec3(((v1[2]-v0[2][2])/1000f0)..., 0), v1)
  end
  (v0[1], v1)
end, (Vec3(0), (false, Vector2(0.0))), clicked)))


camdims    = window.inputs[:window_size]
lift(x -> glViewport(0,0, x...) ,camdims)
projection = lift(wh -> begin
  @assert wh[2] > 0
  @assert wh[1] > 0
  wh = wh[1] > wh[2] ? ((wh[1]/wh[2]), 1f0) : (1f0,(wh[2]/wh[1]))
  orthographicprojection(0f0, float32(wh[1]), 0f0, float32(wh[2]), -1f0, 10f0)
end, Mat4, camdims)

zoom = foldl((a,b) -> float32(a+(b*0.1f0)) , 1.0, window.inputs[:scroll_y])

#Should be rather in Image coordinates
normedmouse = lift(./, window.inputs[:mouseposition], window.inputs[:window_size])

scale             = lift(x -> scalematrix(Vec3(x,x,1f0)), zoom)
translate         = lift(x -> translatematrix(Vec3(x..., 0)), camposition)

view = lift((s, t) -> begin
  pivot = Vec3((s*Vec4((normedmouse.value)..., 0f0, 1f0))[1:3]...)
  translatematrix(pivot)*s*translatematrix(-pivot)*t
end, scale, translate)

projectionview = @lift projection * view


function toopengl{T, D}(img::Texture{T, D, 2})
  c, w, h  = img.dims
  dims = w > h ? (float32((w/h)), 1f0) : (1f0, float32((h/w)))
  v, uv, indexes = genquad(0f0, 0f0,dims...)
  data = RenderObject([
    :vertex           => GLBuffer(v, 2),
    :index            => indexbuffer(indexes),
    :uv               => GLBuffer(v, 2),
    :image            => img,
    :projectionview   => projectionview,
  ], textureshader)

  prerender!(data, glDisable, GL_DEPTH_TEST, enabletransparency)
  postrender!(data, render, data.vertexarray)
  data
end
