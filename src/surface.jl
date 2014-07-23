shaderdir = Pkg.dir()*"/GLPlot/src/shader/"


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

    #Construct the full surrounding difference Vectors with x,y,z coordinates
    differenceVecs = map(elem -> begin
      xx    = stretch(float32(elem[1]), xrange, w) # treat indexes as coordinates by stretching them to the correct range
      yy    = stretch(float32(elem[2]), yrange, h)
      cVec  = current - Vector3(xx, yy, A[elem...][1])
    end, indexes)

    #get the sum of the cross with the current Vector and normalize
    normalVec = unit(reduce((v0, a) -> begin
      a1 = a[2]
      a2 = differenceVecs[mod1(a[1] + 1, length(differenceVecs))]
      v0 + cross(a1, a2)
    end, Vec3(0), enumerate(differenceVecs)))

    result[x,y] = normalVec
  end
  result
end

function stretch(x, r::Range, normalizer = 1)
  T = typeof(x)
  convert(T, first(r) + ((x / normalizer) * (last(r) - first(r))))
end




function createview(x::Dict{Symbol, Any}, keys)
  view = (ASCIIString => ASCIIString)[]
  for (key,value) in x
    keystring = string(key)
    typekey = keystring*"_type"
    calculationkey = keystring*"_calculation"
    if in(typekey, keys)
      view[keystring*"_type"] = toglsltype_string(value)
    end
    if in(calculationkey, keys)
        view[keystring*"_calculation"] = glsl_variable_access(keystring, value)
    end
  end
  view
end
mustachekeys(mustache::Mustache.MustacheTokens) = map(x->x[2], filter(x-> x[1] == "name", mustache.tokens))

const ENVIRONMENT = [
    :projection     => cam.projection,
    :view           => cam.view,
    :normalmatrix   => cam.normalmatrix,
    :light_position => Vec3(20, 20, -20)
]

glsl_attributes = [
  "instance_functions"  => readall(open(shaderdir*"/instance_functions.vert")),
  "GLSL_EXTENSIONS"     => "#extension GL_ARB_draw_instanced : enable"
]
SURFACE(scale=1) = [
    :vertex         => Vec3(0),
    :offset         => GLBuffer(Float32[0,0, 0,1, 1,1, 1,0] * scale, 2),
    :index          => indexbuffer(GLuint[0,1,2,2,3,0]),
    :xscale         => 1f0,
    :yscale         => 1f0,
    :zscale         => 1f0,
    :z              => 0f0,
    :drawingmode    => GL_TRIANGLES
]

CIRCLE(r=0.4, x=0, y=0, points=6) = [
    :vertex         => Vec3(0),
    :offset         => GLBuffer(gencircle(r, x, y, points) , 2),
    :index          => indexbuffer(GLuint[i for i=0:points + 1]),
    :xscale         => 1f0,
    :yscale         => 1f0,
    :zscale         => 1f0,
    :z              => 0f0,
    :drawingmode    => GL_TRIANGLE_FAN
]
const vertexes, uv, normals, indexes = gencubenormals(Vector3{Float32}(0,0,0), Vector3{Float32}(1, 0, 0), Vector3{Float32}(0, 1, 0), Vector3{Float32}(0,0,1))
CUBE() = [
  :vertex         => GLBuffer(vertexes, 3),
  :offset         => Vec2(0), # For other geometry, the texture lookup offset is zero
  :index          => indexbuffer(indexes),
  :normal_vector  => GLBuffer(normals, 3),
  :zscale         => 1f0,
  :z              => 0f0,
  :drawingmode    => GL_TRIANGLES
]


function mix(x,y,a)
  return (x * (1-a[1])) + (y * a[1])
end

GRID_DEFAULTS = [
  :color => Vec4(1)
]
function toopengl{T <: AbstractArray}(attributevalue::Matrix{T}, attribute::Symbol=:z; primitive=SURFACE(), xrange::Range=0:1, yrange::Range=0:1, rest...)
  if isa(xrange, StepRange)
    xn = length(xrange)
  else
    xn = size(attributevalue, 1)
  end
  if isa(yrange, StepRange)
    yn = length(yrange)
  else
    yn = size(attributevalue, 2)
  end
  custom = Dict{Symbol, Any}(map((kv) -> begin 
    if isa(kv[2], Matrix)
      (kv[1], Texture(kv[2]))
    else
      kv #todo: unsupported type check
    end
  end, rest))
  data = merge( [
    attribute       => Texture(attributevalue),
    :xrange         => Vec3(first(xrange), xn, last(xrange)),
    :yrange         => Vec3(first(yrange), yn, last(yrange)),
  ], custom)
  # Depending on what the primitivie is, additional values have to be calculated
  if !haskey(primitive, :normal_vector)
    normaldata = normal(attributevalue, xrange, yrange)
    primitive[:normal_vector] = Texture(normaldata)
  end
  if !haskey(primitive, :xscale)
    primitive[:xscale] = float32(1 / xn)
  end
  if !haskey(primitive, :yscale)
    primitive[:yscale] = float32(1 / yn)
  end
  merged = merge(primitive, ENVIRONMENT, data)

  program = TemplateProgram(shaderdir*"instance_template.vert", shaderdir*"phongblinn.frag", glsl_attributes, merged)

  instancedobject(merged, program, xn*yn, primitive[:drawingmode])

end



function zdata(x1, y1, factor)
    x = (x1 - 0.5) * 15
    y = (y1 - 0.5) * 15

    Vec1((sin(x) + cos(y)) / 10)
end
function zcolor(z)
    a = Vec4(0,1,0,1)
    b = Vec4(1,0,0,1)
    return mix(a,b,z[1]*5)
end
