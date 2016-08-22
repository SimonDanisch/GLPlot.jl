function image(img, kw_args)
  visualize(img, Style(:default), kw_args)
end

function handle_segment{P}(lines, line_segments, points::Vector{P}, segment)
    (isempty(segment) || length(segment) < 2) && return
    if length(segment) == 2
         append!(line_segments, view(points, segment))
    elseif length(segment) == 3
        p = view(points, segment)
        push!(line_segments, p[1], p[2], p[2], p[3])
    else
        append!(lines, view(points, segment))
        push!(lines, P(NaN))
    end
end
function lines(points, kw_args)
  result = []
  isempty(points) && return result
  P = eltype(points)
  lines = P[]
  line_segments = P[]
  last = 1
  for (i,p) in enumerate(points)
      if p == P(NaN) || i==length(points)
          handle_segment(lines, line_segments, points, last:(i-1))
          last = i+1
      end
  end
  if !isempty(lines)
      push!(result, visualize(lines, Style(:lines), kw_args))
  end
  if !isempty(line_segments)
      push!(result, visualize(line_segments, Style(:linesegment), kw_args))
  end
  return result
end
function shape(points, kw_args)
    result = []
    last = 1
    for (i,p) in enumerate(points)
        if p == P(NaN) || i==length(points)
            mesh = GLNormalMesh(view(points, last:(i-1)))
            if !isempty(GeometryTypes.faces(mesh))
                vis = GLVisualize.visualize(mesh, Style(:default), kw_args)
                push!(result, vis)
            end
        end
    end
    result
end

function scatter(points, kw_args)
    prim = get(kw_args, :primitive, Circle)
    visualize(prim, points), Style(:default), kw_args)
end


function poly(points, kw_args)
    push!(points, Point2f0(last(points)[1], 0), Point2f0(0)) # fill shape
    mesh = GLNormalMesh(points) # make polygon
    if !isempty(GeometryTypes.faces(mesh)) # check if polygonation has any faces
        return GLVisualize.visualize(mesh, Style(:default), kw_args)
    end
    []
end

function surface(x,y,z, kw_args)
    if isa(x, AbstractMatrix) && isa(y, AbstractMatrix)
        main = map(s->map(Float32, s), (x, y, z))
    elseif isa(x, Range) && isa(y, Range)
        main = z
        kw_args[:ranges] = (x, y)
    end
    #TODO wireframe
    return visualize(main, Style(:surface), kw_args)
end

function contour(x,y,z, kw_args)
    delete!(kw_args, :color)
    if d[:fillrange] != nothing
        main = map(z) do val
            GLVisualize.Intensity{1, Float32}(val)
        end
        GLVisualize.visualize(main, Style(:default), kw_args)
    else
        h = kw_args[:levels]
        levels = Contour.contours(x, y, z, h)
        result = Point2f0[]
        for c in levels
            for elem in c.lines
                push!(result, Point2f0(NaN32))
                append!(result, elem.vertices)
            end
        end
    return GLVisualize.visualize(result, Style(:lines),kw_args)
    end
end


function heatmap(x,y,z, kw_args)
    zmin, zmax = get(kw_args, :limits, Vec2f0(extrema(z)))
    cmap = get(kw_args, :color_map, get(kw_args, :color, RGBA{Float32}(0,0,0,1)))
    heatmap = map(z) do val
        color_lookup(cmap, val, zmin, zmax)
    end
    tex = Texture(heatmap, minfilter=:nearest)
    visualize(tex, Style(:default), kw_args)
end
function alignment2num(x::Symbol)
    (x == :hcenter || :vcenter)  && return 0.5
    (x == :left || :bottom) && return 0.0
    (x == :right || :top) && return 1.0
    0.0 # 0 default, or better to error?
end
function alignment2num(font)
    Vec2f0(map(alignment2num, (font.valign, font.halign)))
end
function text(position, text, kw_args)
    text_align = alignment2num(text.font)
    text_offset = Vec2f0(position)
    hyper_align = HyperCube(text_offset, text_align)
    text_plot(text, hyper_align, kw_args)
end
function text_plot(text, alignment, kw_args)
    transmat = kw_args[:model]
    obj = visualize(text, Style(:default), kw_args)
    bb = value(GLAbstraction.boundingbox(obj))
    w,h,_ = widths(bb)
    x,y,_ = minimum(bb)
    pivot = origin(alignment)
    pos = pivot - (Point2f0(x, y) .* widths(alignment))
    if kw_args[:rotation] != 0.0
        rot = GLAbstraction.rotationmatrix_z(Float32(font.rotation))
        transmat *= translationmatrix(pivot)*rot*translationmatrix(-pivot)
    end

    transmat *= GLAbstraction.translationmatrix(Vec3f0(pos..., 0))
    GLAbstraction.transformation(obj, transmat)
    view(obj, img.screen, camera=:orthographic_pixel)
end
