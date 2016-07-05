
function is_editable(k, v_v)
    v = value(v_v)
    !(
        k == :objectid ||
        k == :is_fully_opaque ||
        k == :instances ||
        k == Symbol("position.multiplicator") ||
        k == Symbol("position.dims") ||
        k == Symbol("resolution") ||
        startswith(string(k), "boundingbox") ||
        (k == Symbol("color") && isa(v, AbstractArray)) ||
        k in fieldnames(PerspectiveCamera) ||
        k == :instances ||
        isa(v, Symbol) ||
        isa(v, Void) ||
        isa(v, NativeMesh) ||
        isa(v, Bool) ||
        isa(v, Integer) ||
        (isa(v, FixedVector) && eltype(v) <: Integer)
    )
end
makesignal2(s::Signal)   = s
makesignal2(v)           = Signal(v)
makesignal2(v::GPUArray) = v

function mytransform!(vis::RenderObject, mat)
    vis[:model] = const_lift(*, mat, vis[:model])
end
function mytransform!(vis::Context, mat)
    for elem in vis.children
        mytransform!(elem, mat)
    end
end
function extract_edit_menu(robj, edit_screen, isvisible)
    pos = 1f00
    lines = Point2f0[]
    screen_w = edit_screen.area.value.w
    labels = String[]
    scale = Vec2f0(1)
    atlas = GLVisualize.get_texture_atlas()
    font = GLVisualize.DEFAULT_FONT_FACE
    textpositions = Point2f0[]
    for (k,v) in robj.uniforms
        is_editable(k, v) || continue
        s = makesignal2(v)
        if applicable(vizzedit, s, edit_screen)

            sig, vis = vizzedit(s, edit_screen, visible=isvisible)
            robj[k] = sig
            bb = value(boundingbox(vis))
            height = widths(bb)[2]
            mini = minimum(bb)
            to_origin = -Vec3f0(mini[1], mini[2], 0)
            GLAbstraction.transform!(vis, translationmatrix(Vec3f0(20,pos,0)+to_origin))
            _view(vis, edit_screen, camera=:fixed_pixel)
            pos += round(Int, height) + 10

            label = string(k)*":"
            push!(labels, label)
            append!(textpositions,
                GLVisualize.calc_position(label, Point2f0(10, pos), scale, font, atlas)
            )
            pos += 40
            push!(lines, Point2f0(0, pos-10), Point2f0(screen_w, pos-10))

        end
    end
    _view(visualize(
            join(labels), position=textpositions,
            color=RGBA{Float32}(0.8, 0.8, 0.8, 1.0)
        ), edit_screen, camera=:fixed_pixel
    )
    _view(visualize(
        lines, :linesegment, thickness=1f0, color=RGBA{Float32}(0.9, 0.9, 0.9, 1.0)
    ), edit_screen, camera=:fixed_pixel)

    pos
end
