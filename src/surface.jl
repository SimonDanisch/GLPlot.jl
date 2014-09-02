export mix, SURFACE, CIRCLE, CUBE, POINT


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
const vertexes, uv, normals, indexes = gencubenormals(Vec3(0), Vec3(1, 0, 0), Vec3(0,1, 0), Vec3(0,0,1))

CUBE() = [
  :vertex         => GLBuffer(vertexes),
  :offset         => Vec2(0), # For other geometry, the texture lookup offset is zero
  :index          => indexbuffer(indexes),
  :normal_vector  => GLBuffer(normals),
  :zscale         => 1f0,
  :z              => 0f0,
  :drawingmode    => GL_TRIANGLES
]
POINT() = [
  :vertex         => GLBuffer(Vec3[Vec3(0)]),
  :offset         => Vec2(0), # For other geometry, the texture lookup offset is zero
  :index          => indexbuffer(GLuint[0]),
  :normal_vector  => GLBuffer(Vec3[Vec3(0,0,1)]),
  :zscale         => 1f0,
  :z              => 0f0,
  :drawingmode    => GL_POINTS
]

parameters = [
    (GL_TEXTURE_MIN_FILTER, GL_NEAREST),
    (GL_TEXTURE_MAG_FILTER, GL_NEAREST),
    (GL_TEXTURE_WRAP_S,  GL_REPEAT),
    (GL_TEXTURE_WRAP_T,  GL_REPEAT),
  ]
function toopengl{T <: AbstractArray}(
			attributevalue::Matrix{T}, attribute::Symbol=:z; 
			primitive=SURFACE(), xrange=(-1,1), yrange=(-1,1), color=Vec4(0,0,0,1), 
			lightposition=Vec3(20, 20, -20), camera=pcamera, rest...)
  
  
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
  push!(rest, (:color, color))
  custom = Dict{Symbol, Any}(map((kv) -> begin 
    if isa(kv[2], Matrix)
      (kv[1], Texture(kv[2], parameters=parameters))
    else
      kv #todo: check for unsupported types
    end
  end, rest))
  data = merge( [
    attribute       => Texture(attributevalue, parameters=parameters),
    :xrange         => Vec3(first(xrange), xn, last(xrange)),
    :yrange         => Vec3(first(yrange), yn, last(yrange)),
    :projection     => camera.projection,
    :view           => camera.view,
    :normalmatrix   => camera.normalmatrix,
    :light_position => lightposition,
    :modelmatrix    => eye(Mat4)
  ], custom)
  # Depending on what the primitivie is, additional values have to be calculated
  if !haskey(primitive, :normal_vector)
    primitive[:normal_vector] = Vec3(0)
  end
  if !haskey(primitive, :xscale)
    primitive[:xscale] = float32(1 / xn)
  end
  if !haskey(primitive, :yscale)
    primitive[:yscale] = float32(1 / yn)
  end
  merged = merge(primitive, data)

  program = TemplateProgram(shaderdir*"instance_template.vert", shaderdir*"phongblinn.frag", view=glsl_attributes, attributes=merged)
  obj = instancedobject(merged, program, xn*yn-xn, primitive[:drawingmode])
  prerender!(obj, glEnable, GL_DEPTH_TEST)
  obj
end



function toopengl{T <: AbstractArray}(
          array::Dict{Symbol, Dict{Symbol, T}}, attribute::Symbol=:zscale; 
          xscale=0.08f0, yscale=0.03f0, textscale = Vec2(1/200f0),
          xrange=(0,1), yrange=(0,1), xborder=0.05, yborder=0.05, gap=0.2, color=Vec4(0,0,0,1), 
          camera=pcamera
        )
  result    = RenderObject[]

  mappedresult  = map(res->hcat( collect(values(res))...), values(array))

  xrangestart = first(xrange) + xborder
  xrangeend = last(xrange) - xborder

  yrange    = (first(yrange) + yborder, last(yrange) - yborder)

  L = length(mappedresult)
  xstep     = ((xrangeend-xrangestart) - ((L-1)*gap)) / L
  step      = 0f0

  for elem in mappedresult
    plot = map(x->Vector1{Float32}((x/10^8)/2), elem)

    start1 = xrangestart + (step*xstep) + (step*gap)
    xrange = (start1, (start1 + xstep))
    push!(result, toopengl(
      plot, 
      attribute, primitive=CUBE(), xscale=xscale, 
      yscale=yscale, color=color, xrange=xrange, 
      yrange=yrange, camer=camera
    ))

    step += 1f0
  end

  rotq    = qrotation(Float32[0,0,1], pi/2f0)
  rotdir  = qrotation(Float32[0,0,1], -pi/2f0)

  ytext = foldl((v0,v1)-> v0*"\n"*v1, map(string, keys(results)))
  xtext = foldl((v0,v1)-> v0*"\n"*v1, map(string, keys(first(results)[2])))

  
  push!(result, toopengl(
    reverse(ytext), start=Vec3(xrangestart + (xstep/2),-0.1,0), 
    scale=textscale, rotation=rotdir, 
    textrotation=rotq, lineheight=xstep+gap, camer=camera
  ))
  push!(result, toopengl(
    string(xtext), start=Vec3(1,0f0,0), camer=camera, scale=textscale,
    lineheight=(rangelength(yrange) / (size((mappedresult[1]), 2)-1)),
  ))
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

function mix(x,y,a)
  return (x * (1-a[1])) + (y * a[1])
end


Base.middle(x::(Real, Real)) = (first(x)+last(x)) /2 
rangelength(x::(Real, Real)) = abs(last(x)-first(x))

function normal(A, xrange, yrange)
  w,h = size(A)
  result = Array(Vector3{eltype(A[1])}, w,h)
  for x=1:w, y=1:h
    xs = stretch(float32(x), xrange, w)
    ys = stretch(float32(y), yrange, h)
    zs = A[x,y][1]

    current = Vector3(xs, ys, zs)
    
    #calculate indexes for surrounding zvalues
    indexes = reverse([(x-1,y-1), (x-1,y), (x-1,y+1), (x,y+1), 
                (x+1,y+1), (x+1,y), (x+1,y-1), (x,y-1)])

    #Remove out of bounds
    indextmp = (Int, (Int,Int))[]
    holes = 0
    for (ind,(x1,y1)) in enumerate(indexes)
      if x1 >= 1 && x1 <= w && y1 >= 1 && y1 <= h
        push!(indextmp, (ind,(x1, y1)))
      else
        holes += 1
      end
    end
    #Put back into order, solving one special case (edges (N,N.  )
    if length(indextmp)==3 && holes > 0 && indextmp[1][1] == 1
      indextmp[1] = (999, indextmp[1][2])
    end
    indexes = map(x->x[2], sort(indextmp))
    #Construct the full surrounding difference Vectors with x,y,z coordinates
    differenceVecs = map(indexes) do elem
      xx    = stretch(float32(elem[1]), xrange, w) # treat indexes as coordinates by stretching them to the correct range
      yy    = stretch(float32(elem[2]), yrange, h)
      cVec  = current - Vector3(xx, yy, A[elem...][1])
    end

    #get the sum of the cross with the current Vector and normalize
    normalVec = unit(reduce((v0, a) -> begin
      a1 = a[2]
      a2 = differenceVecs[a[1] + 1]
      v0 + cross(a1, a2)
    end, Vec3(0), enumerate(differenceVecs[1:end-1])))

    result[x,y] = normalVec

  end
  result
end

function stretch(x, r::Range, normalizer = 1)
  T = typeof(x)
  convert(T, first(r) + ((x / normalizer) * (last(r) - first(r))))
end

function stretch(x, r::(Real, Real), normalizer = 1)
  T = typeof(x)
  convert(T, first(r) + ((x / normalizer) * (last(r) - first(r))))
end

