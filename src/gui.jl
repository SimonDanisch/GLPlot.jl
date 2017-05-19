function add_drag(w, range, point_id, slider_length, slideridx_s)
    m2id = mouse2id(w)
    # interaction
    @materialize mouse_buttons_pressed, mouseposition = w.inputs
    isoverpoint = const_lift(is_same_id, m2id, point_id)
    # single left mousekey pressed (while no other mouse key is pressed)
    key_pressed = const_lift(GLAbstraction.singlepressed, mouse_buttons_pressed, GLFW.MOUSE_BUTTON_LEFT)
    # dragg while key_pressed. Drag only starts if isoverpoint is true
    mousedragg = GLAbstraction.dragged(mouseposition, key_pressed, isoverpoint)
    preserve(foldp(value(slideridx_s), mousedragg) do v0, dragg
        if dragg != Vec2f0(0)
            idx_steps = round(Int, (dragg[1]/slider_length)*length(range))
            new_idx = clamp(v0 + idx_steps, 1, length(range))
            push!(slideridx_s, new_idx)
            return v0
        else # dragging started
            return value(slideridx_s)
        end
    end)
    slideridx_s
end
function add_play(slideridx_s, play_signal, range, rate=30.0)
    play_s = fpswhen(play_signal, rate)
    preserve(map(play_s, init=nothing) do t
        push!(slideridx_s, mod1(value(slideridx_s)+1, length(range)))
        nothing
    end)
end

function maxdigits(range)
    if eltype(range) <: AbstractFloat
        return 7
    else
        return max(ndigits(first(range)), ndigits(last(range)))
    end
end
function play_widget(
        range, window = GLPlot.widget_screen!();
        startidx::Int = 1
    )
    numberbox = map(icon_size()) do is
        AABB(Vec3f0(0, -1mm, 0), Vec3f0(2is, is, 1))
    end
    target_s = map(x-> x * 0.4, icon_size())
    sliderlen = 70mm - (3 * value(icon_size())) - 2mm
    play_button, play_stop_signal = GLVisualize.toggle_button(
        rot180(GLPlot.imload("play.png")), GLPlot.imload("break.png"), window
    )
    play_s = map(!, play_stop_signal)
    slider_w, slider_s = GLVisualize.slider(range, window,
        startidx = startidx, play_signal = play_s,
        slider_length = sliderlen
    )
    number = visualize(
        map(GLVisualize.printforslider, slider_s),
        color = RGBA{Float32}(0.6, 0.6, 0.6,1),
        boundingbox = numberbox,
        relative_scale = target_s
    )
    add_widget!(play_button, number, slider_w, window=window)

    slider_s
end
export play_widget
export add_widget!
function add_widget!(widgets...;
        delete = Signal(false),
        window = widget_screen!(delete = delete),
        height = value(icon_size())
    )
    scalings = map(widgets) do widget
        bb = value(boundingbox(widget))
        w = widths(bb)
        if w[2] > height # only scale when to big
            s = height/w[2]
            w.*s, minimum(bb)
        else
            w, minimum(bb)
        end
    end
    last_x = 0f0
    foreach(zip(scalings, widgets)) do scaling_widget
        scaling, widget = scaling_widget
        scale, offset = scaling
        xwidth = scale[1] - 1mm
        place = SimpleRectangle{Float32}(
            last_x - offset[1] + 0.5mm, -offset[2] + 0.5mm, xwidth, scale[2] - 1mm
        )
        layout!(place, widget)
        _view(widget, window, camera = :fixed_pixel)
        last_x += xwidth
    end
end


function item_area(la, deleted, item_height)
    y = la.y - item_height - 2
    deleted && return IRect(la.x, la.y, la.w, 0)
    return IRect(la.x, y, la.w, item_height)
end

function widget_screen!(parentscreen = edit_screen();
        left_gap = 1.5mm, delete = Signal(false), height = icon_size()
    )
    scroll = parentscreen.inputs[:menu_scroll]
    if isempty(parentscreen.children)
        last_area = map(parentscreen.area, height, scroll) do a, ih, s
            return IRect(left_gap, a.h-ih+s, a.w-left_gap, ih)
        end
    else
        last_area = last(parentscreen.children).area
    end
    itemarea = map(GLPlot.item_area, last_area, delete, height)
    Screen(parentscreen, area = itemarea)
end


function choices(x::Vector)
    signal, vis = GLVisualize.choice_widget(x, edit_screen(), area=(48mm, 8mm))
    w = widget_screen!()
    _view(vis, w, camera = :fixed_pixel)
    signal
end


function edit_toggle()
    edit_button, no_edit_signal = toggle_button(
        imload("play.png"), rotr90(imload("play.png")), edit_screen()
    )
end

function visible_toggle()
    toggle_button(
        imload("showing.png"), imload("notshowing.png"), edit_screen()
    )
end
function delete_toggle()
    delete_button, del_signal = button(
        imload("delete.png"), edit_screen()
    )
end



function async_map2(f, init, inputs...; typ = typeof(init))
    node = Signal(typ, init, inputs)
    worker_task = @async init
        map(inputs...) do args...
            outer_task = current_task()
            hasworked = istaskdone(worker_task) #
            if istaskdone(worker_task) #
                worker_task = @async begin
                try
                    inner_worker = @async begin
                        x = f(args...)
                        push!(node, x)
                    end
                    wait(inner_worker)
                catch err
                    Base.throwto(outer_task, CapturedException(err, catch_backtrace()))
                end
            end
        end
         worker_task
    end, node
end
