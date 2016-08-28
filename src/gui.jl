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


function play_control(
        range;
        slider_length=round(Int, 300dpi-50dpi)
    )
    window = new_controle_screen()
    point_id = Signal((0,0))
    play_button, play_stop_signal = toggle_button(
        rot180(imload("play.png")), imload("break.png"), window
    )
    play_s = map(!, play_stop_signal)
    layout!(GLPlot.layout_pos_ver(0, 0), play_button)
    position = get_drag(window, range, point_id, slider_length, play_s)
    model = translationmatrix(Vec3f0(60dpi, round(Int, 50dpi/2), 0))
    line = visualize(
        Point2f0[(0,0), (slider_length, 0)], :linesegment,
        model=model
    ).children[]
    i = Signal(0)
    cpos = map(vcat, position)
    point_robj = visualize(
        (Circle{Float32}(Point2f0(0), 10dpi)),
        position=cpos, model=model
    ).children[]
    push!(point_id, (point_robj.id, line.id))
    _view(point_robj, window, camera=:fixed_pixel)
    _view(line, window, camera=:fixed_pixel)
    _view(play_button, window, camera=:fixed_pixel)

    return map(position) do p
        zero21 = p[1] / slider_length
        i = ceil(Int, zero21 * (length(range)-1))
        range[i+1]
    end
end


function new_controle_screen()
    scroll = edit_screen.inputs[:menu_scroll]
    icon_size = map(Int,  GLPlot.icon_percent)
    if isempty( GLPlot.edit_screen.children)
        last_area = map(GLPlot.edit_screen.area, icon_size, scroll) do a, ih, s
            return SimpleRectangle{Int}(left_gap, a.h-ih+s, a.w-2left_gap, ih)
        end
    else
        last_area = last(GLPlot.edit_screen.children).area
    end
    itemarea = map(GLPlot.item_area, last_area, Signal(false), icon_size)
    Screen(GLPlot.edit_screen, area=itemarea)
end
