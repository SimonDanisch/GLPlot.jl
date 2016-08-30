function get_drag(w, range, point_id, slider_length, playing, startpos=Point2f0(0))
    m2id = mouse2id(w)
    # interaction
    @materialize mouse_buttons_pressed, mouseposition = w.inputs
    isoverpoint = const_lift(is_same_id, m2id, point_id)
    # single left mousekey pressed (while no other mouse key is pressed)
    key_pressed = const_lift(GLAbstraction.singlepressed, mouse_buttons_pressed, GLFW.MOUSE_BUTTON_LEFT)
    # dragg while key_pressed. Drag only starts if isoverpoint is true
    mousedragg = droprepeats(GLAbstraction.dragged(mouseposition, key_pressed, isoverpoint))
    startvalue = (0, 0, Point2f0(0), value(startpos))
    t = fpswhen(playing, 30)
    playstep = (step(range) / abs(last(range)-first(range))) * slider_length
    sig = foldp(startvalue, mousedragg, point_id, playing, t) do v0, dragg, p_id, isp, _
        id, index, p0, np = v0
        if isp
            x = mod(np[1] + playstep, slider_length)
            np = Point2f0(x, np[2])
            return id, index, np, np
        end
        if dragg == Vec2f0(0) # if drag just started. Not the best way, maybe dragged should return a tuple of (draggvalue, started)
            p0 = np # start with current value
        else
            x = clamp(p0[1] + dragg[1], 0, slider_length)
            np = Point2f0(x, np[2])
        end
        return id, index, p0, np
    end
    map(last, sig)
end

function slider(
        range, window;
        play_signal=Signal(false), slider_length=50mm
    )
    point_id = Signal((0,0))
    position = get_drag(window, range, point_id, slider_length, play_signal)
    bb = Signal(AABB{Float32}(Vec3f0(0), Vec3f0(slider_length, 10mm, 1)))
    line = visualize(
        Point2f0[(2.1mm, 5mm), (slider_length, 5mm)], :linesegment,
        boundingbox=bb, thickness=0.5mm
    ).children[]
    i = Signal(0)
    cpos = map(vcat, position)
    point_robj = visualize(
        (Circle, cpos),
        offset=Vec2f0(2.1mm, 3mm), scale=Vec2f0(4mm),
        boundingbox=bb
    ).children[]
    push!(point_id, (point_robj.id, line.id))
    range_s = map(position) do p
        zero21 = p[1] / slider_length
        i = ceil(Int, zero21 * (length(range)-1))
        range[i+1]
    end
    range_s, Context(point_robj, line)
end

function play_widget(
        range, window=widget_screen!();
        slider_length=50mm
    )
    play_button, play_stop_signal = toggle_button(
        rot180(imload("play.png")), imload("break.png"), window
    )
    play_s = map(!, play_stop_signal)
    slider_s, slider_w = slider(range, window, play_signal=play_s, slider_length=slider_length-4.2mm)
    add_widget!(play_button, slider_w, window=window)
    slider_s
end

export add_widget!
function add_widget!(widgets...;
        delete=Signal(false),
        window=widget_screen!(delete=delete),
        height=value(icon_size)
    )
    scalings = map(widgets) do widget
        bb = value(boundingbox(widget))
        w = widths(bb)
        s = height/w[2]
        w.*s, minimum(bb)
    end
    last_x = 0f0
    foreach(zip(scalings, widgets)) do scaling_widget
        scaling, widget = scaling_widget
        scale, offset = scaling
        place = SimpleRectangle{Float32}(last_x-offset[1], -offset[2], scale[1], scale[2])
        layout!(place, widget)
        _view(widget, window, camera=:fixed_pixel)
        last_x += scale[1]
    end
end

function widget_screen!(parentscreen=edit_screen; left_gap=0.7mm, delete=Signal(false))
    scroll = parentscreen.inputs[:menu_scroll]
    if isempty(parentscreen.children)
        last_area = map(parentscreen.area, icon_size, scroll) do a, ih, s
            return SimpleRectangle{Int}(left_gap, a.h-ih+s, a.w-2left_gap, ih)
        end
    else
        last_area = last(parentscreen.children).area
    end
    itemarea = map(GLPlot.item_area, last_area, delete, icon_size)
    Screen(parentscreen, area=itemarea)
end


function choices(x::Vector)
    signal, vis = GLVisualize.choice_widget(x, edit_screen, area=(48mm, 8mm))
    w = widget_screen!()
    _view(vis, w, camera=:fixed_pixel)
    signal
end


function edit_toggle()
    edit_button, no_edit_signal = toggle_button(
        imload("play.png"), rotr90(imload("play.png")), edit_screen
    )
end

function visible_toggle()
    toggle_button(
        imload("showing.png"), imload("notshowing.png"), edit_screen
    )
end
function delete_toggle()
    delete_button, del_signal = button(
        imload("delete.png"), edit_screen
    )
end
