
function glplot(p::Plots.Plot, style::Symbol=:default;kw_args...)
    show(p)
end

function glplot(arg1, style=:default; kw_args...)
    robj = visualize(arg1, style; kw_args...)
    _view(robj, viewing_screen, camera=:perspective)
    center!(viewing_screen)
    register_plot!(robj)
    robj
end



function register_plot!(robj::Vector, screen=viewing_screen)
    vcat(map(robj) do elem
        register_plot!(elem, screen)
    end...)
end
function register_plot!(robj::Context, screen=viewing_screen)
    register_plot!(robj.children, screen)
end

function left_clicked(button::Set{Int})
    return GLAbstraction.singlepressed(button, GLFW.MOUSE_BUTTON_LEFT)
end
function register_plot!(robj::RenderObject, screen=viewing_screen)
    left_gap = round(Int, 7dpi)
    visible_button, visible_toggle = toggle_button(
        imload("showing.png"), imload("notshowing.png"), edit_screen
    )
    set_arg!(robj, :visible, visible_toggle)
    delete_button, del_signal = button(
        imload("delete.png"), edit_screen
    )
    edit_button, no_edit_signal = toggle_button(
        imload("play.png"), rotr90(imload("play.png")), edit_screen
    )
    item_height = Signal(0)
    not_del_signal = droprepeats(foldp(false, del_signal) do v0, to_delete
        v0 && return v0
        if to_delete
            push!(item_height, 0)
            delete!(screen, robj)
        end
        return to_delete
    end)

    scroll = edit_screen.inputs[:menu_scroll]
    icon_size = map(Int, icon_percent)
    last_area = if isempty(edit_screen.children)
        map(edit_screen.area, not_del_signal, icon_size, scroll) do a, deleted, ih, s
            deleted && return SimpleRectangle(left_gap, a.h+s, a.w-2left_gap, 0)
            return SimpleRectangle{Int}(left_gap, a.h-ih+s, a.w-2left_gap, ih)
        end
    else
        last(edit_screen.children).area
    end
    edit_signal = map(!, no_edit_signal)
    itemarea = map(item_area, last_area, not_del_signal, icon_size)
    edititemarea = map(edit_item_area, itemarea, item_height, Signal(left_gap))
    new_item_screen = Screen(edit_screen, area=itemarea)
    edit_item_screen = Screen(edit_screen, area=edititemarea)
    offset = 0f0
    for elem in (visible_button, delete_button, edit_button)
        layout!(layout_pos_ver(offset, 2), elem)
        _view(elem, new_item_screen, camera=:fixed_pixel)
        offset += 1
    end
    preserve(foldp((false, value(item_height)), edit_signal) do v0, edit
        if edit
            if !v0[1] # only do this at the first time
                new_heights = extract_edit_menu(robj, edit_item_screen, edit_signal)
                nh = ceil(Int, new_heights)
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
    selected = foldp(false, mouse2id(screen), mouse_buttons_pressed, mouseinside) do v0, id, mc, mi
        if left_clicked(mc) && mi
            new_item_screen.color = if id.id == robj.id
                RGBA{Float32}(0.9, 0.99, 1, 1)
            else
                RGBA{Float32}(1, 1, 1, 1)
            end
            return id.id == robj.id
        end
        return v0
    end
    preserve(selected)
    [del_signal]
end
