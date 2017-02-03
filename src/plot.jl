function glplot(arg1, style = :default;
        screen = viewing_screen(), camera = :perspective,
        kw_args...
    )
    robj = visualize(arg1, style; kw_args...)
    _view(robj, screen, camera = camera)
    register_plot!(robj, screen)
    robj
end


function register_plot!(robj::Vector, screen = viewing_screen(); create_gizmo = false)
    vcat(map(robj) do elem
        register_plot!(elem, screen, create_gizmo = create_gizmo)
    end...)
end
function register_plot!(robj::Context, screen = viewing_screen(); create_gizmo = false)
    register_plot!(robj.children, screen, create_gizmo = create_gizmo)
end

function left_clicked(button::Set{Int})
    return GLAbstraction.singlepressed(button, GLFW.MOUSE_BUTTON_LEFT)
end

function to_clip(p, width, proj_view)
    clip = proj_view * Vec4f0(p, 1f0)
    clip = clip ./ clip[4]
    nv = (clip + 1f0) * 0.5f0
    Point2f0(nv[1], nv[2]) .* Point2f0(width-1)
end

function gizmo(w, is_selected)
    colors = Array(RGBA{Float32}, 6)
    positions = Array(Point3f0, 6)
    for axis in 1:3
        c = RGBA{Float32}(ntuple(i->i==axis ? 1f0 : 0f0, 3)...)
        v = unit(Vec3f0, axis)
        positions[2(axis-1)+1] = Point3f0(0)
        positions[2(axis-1)+2] = v
        colors[2(axis-1)+1] = RGBA{Float32}(0,0,0,1)
        colors[2(axis-1)+2] = c
    end
    robj = visualize(
        positions, :linesegment,
        color = colors,
        prerender = ()->glDisable(GL_DEPTH_TEST), # draw over other items
        postrender = ()->glEnable(GL_DEPTH_TEST),
        thickness = 10f0
    ).children[]
    _view(robj, camera = :perspective)
    @materialize mouseposition, mouse_buttons_pressed, buttons_pressed = w.inputs
    m2id = mouse2id(w)
    show_gizmo = map(buttons_pressed) do bp
        GLAbstraction.singlepressed(bp, GLFW.KEY_M) && value(is_selected)
    end
    set_arg!(robj, :visible, show_gizmo)
    start_drag = foldp((false, 0), m2id) do v0, id
        ison = id.id == robj.id && id.index > 0 && id.index <= 6 && value(show_gizmo)
        if ison
            return (true, id.index)
        else
            return (false, v0[2])
        end
    end
    left_pressed = const_lift(GLAbstraction.pressed, mouse_buttons_pressed, GLFW.MOUSE_BUTTON_LEFT)
    view = w.cameras[:perspective].projectionview
    ddiff = GLAbstraction.dragged_diff(mouseposition, left_pressed, map(first, start_drag))

    translation = foldp(Vec3f0(0), ddiff) do v0, diff
        idx = value(start_drag)[2]
        pv = value(view)
        if idx != 0
            i = ceil(Int, idx/2)
            uv = unit(Vec3f0, i)
            wh = widths(w)
            nv2d = to_clip(uv, wh, pv)
            origin = to_clip(Vec3f0(0), wh, pv)
            nv2d = nv2d-origin
            mv = -Vec2f0(diff).*10f0
            return v0 + (uv * (dot(mv, normalize(nv2d)) ./ (norm(wh))))
        end
        v0
    end
    model = map(translationmatrix, translation)
    set_arg!(robj, :model, model)
    model
end

"""
There's a lot of noise if we just go through all parameters of a `RenderObject`.
This function filters out the internal values
"""
function is_editable(k, v_v)
    v = value(v_v)
    !(
        k == :objectid ||
        k == :is_fully_opaque ||
        k == :instances ||
        k == Symbol("position.multiplicator") ||
        k == Symbol("position.dims") ||
        k == Symbol("spatialorder") ||
        k == Symbol("resolution") ||
        k == Symbol("fxaa") ||
        k == Symbol("light") ||
        k == Symbol("light") ||
        k == Symbol("doc_string") ||
        k == Symbol("faces") ||
        k == Symbol("image") ||
        k == Symbol("vertices") ||
        k == Symbol("texturecoordinates") ||
        k == Symbol("ranges") ||
        k == Symbol("model") ||
        k == :visible ||
        startswith(string(k), "boundingbox") ||
        (k == Symbol("color") && isa(v, AbstractArray)) ||
        k in fieldnames(PerspectiveCamera) ||
        k == :instances ||
        isa(v, Symbol) ||
        isa(v, Void) ||
        isa(v, NativeMesh) ||
        isa(v, Int) ||
        isa(v, Int32) ||
        isa(v, UInt32) ||
        isa(v, UInt) ||
        (isa(v, FixedVector) && eltype(v) <: Integer)
    )
end

function to_edit_dict(robj)
    filter(collect(robj.uniforms)) do kv
        is_editable(kv[1], kv[2])
    end
end

function register_plot!(
        robj::RenderObject, screen = viewing_screen();
        create_gizmo = false
    )
    left_gap = 1.5mm
    visible_button, visible_s = visible_toggle()
    set_arg!(robj, :visible, visible_s)
    delete_button, del_signal = button(imload("delete.png"), edit_screen())
    edit_button, no_edit_signal = edit_toggle()

    item_height = Signal(0)
    not_del_signal = droprepeats(foldp(false, del_signal) do deleted, to_delete
        deleted && return deleted
        if to_delete
            push!(item_height, 0)
            delete!(screen, robj)
        end
        return to_delete
    end)

    edit_signal = map(!, no_edit_signal)
    item_screen = widget_screen!(delete=not_del_signal)
    edititemarea = map(edit_item_area, item_screen.area, item_height, Signal(left_gap))
    edit_item_screen = Screen(edit_screen(), area = edititemarea)
    preserve(foldp((false, value(item_height)), edit_signal) do v0, edit
        if edit
            if !v0[1] # only do this at the first time
                dict = to_edit_dict(robj)
                nh = if !isempty(dict)
                    vis, signal_dict = extract_edit_menu(
                        dict,
                        edit_item_screen,
                        edit_signal,
                    )
                    for (k, v) in signal_dict
                        robj.uniforms[k] = v
                    end
                    _view(vis, edit_item_screen, camera = :fixed_pixel)
                    new_heights = widths(value(boundingbox(vis)))[2]
                    ceil(Int, new_heights)
                else
                    0
                end
                push!(item_height, nh)
                return true, nh
            else
                push!(item_height, v0[2])
            end
        else
            push!(item_height, 0)
        end
        return v0
    end)
    @materialize buttons_pressed, mouse_buttons_pressed, mouseinside = screen.inputs
    dc = doubleclick(mouse_buttons_pressed, 0.1)
    selected = foldp(false, mouse2id(screen), dc, mouseinside) do v0, id, dc, mi
        dc && mi && return id.id == robj.id # if double clicked and inside and hovers over robj
        return v0
    end
    color = map(selected) do s
        s ? RGBA{Float32}(0.9, 0.99, 1, 1) : RGBA{Float32}(1, 1, 1, 1)
    end
    select_icon = visualize(SimpleRectangle(0,0,1.5mm, 10mm), color=color)
    add_widget!(select_icon, visible_button, delete_button, edit_button, window=item_screen)
    if create_gizmo
        model = gizmo(screen, selected)
        set_arg!(robj, :model, model)
    end
    [del_signal]
end
