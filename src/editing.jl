
function is_editable(k, v_v)
    v = value(v_v)
    !(
        k == :objectid ||
        k == :is_fully_opaque ||
        k == :instances ||
        k == Symbol("position.multiplicator") ||
        k == Symbol("position.dims") ||
        k == Symbol("resolution") ||
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
function extract_edit_menu(robj, edit_screen)
    a_w = Float32(edit_screen.area.value.w)
    pos = 45f0 + 5f0
    for (k,v) in robj.uniforms
        is_editable(k, v) || continue
        s = makesignal2(v)
        if applicable(vizzedit, s, edit_screen)
            sig, vis = vizzedit(s, edit_screen)
            robj[k] = sig
            bb = value(boundingbox(vis))
            height = widths(bb)[2]
            min = minimum(bb)
            max = maximum(bb)
            to_origin = Vec3f0(min[1], max[2], min[3])
            GLAbstraction.transform!(vis, translationmatrix(Vec3f0(20,pos,0)-to_origin))
            view(vis, edit_screen, camera=:fixed_pixel)
            pos += round(Int, height) + 10
        end
    end
    pos
end
