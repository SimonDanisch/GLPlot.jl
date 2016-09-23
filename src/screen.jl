function handle_drop(files::Vector{String})
    for f in files
        try
            glplot(load(f))
        catch e
            warn(e)
        end
    end
end

toolbar_area(pa, toolbar_width) = SimpleRectangle(0, 0, toolbar_width, pa.h)
function viewing_area(area_l, area_r)
    SimpleRectangle(area_l.x+area_l.w, 0, area_r.x-area_l.w, area_r.h)
end
function edit_rectangle(visible, area, tarea)
    w = visible ? 70mm : 1.5mm
    x = area.w-w
    SimpleRectangle(x, 0, w, area.h)
end


layout_pos_ho(i) = map(icon_size) do ip
    SimpleRectangle{Float32}(0, i*ip + i*2, ip, ip)
end
layout_pos_ver(i, border) = map(icon_size) do ip
    SimpleRectangle{Float32}(i*ip + i*border, 0, ip, ip)
end


function edit_item_area(la, item_height, left_gap)
    y = la.y-item_height-2
    return SimpleRectangle(left_gap, y, la.w, item_height)
end

function save_record(frames)
    path = joinpath(homedir(), "Desktop")
    GLVisualize.create_video(frames, "test.webm", path, 0)
end

const _compute_callbacks = []
register_compute(f) = push!(_compute_callbacks, f)
poll_reactive() = (Base.n_avail(Reactive._messages) > 1) && Reactive.run_till_now()
function glplot_renderloop(window, compute_s, record_s)
    was_recording = false
    frames = []
    i = 0
    Reactive.stop()
    yield()
    while isopen(window)
        tic()
        GLWindow.pollevents()
        record = !value(record_s)
        if isready(Reactive._messages)
            Reactive.run_till_now()
            GLWindow.render_frame(window)
            GLWindow.swapbuffers(window)
        end
        if record
            push!(frames, screenbuffer(window))
        elseif was_recording && !record
            save_record(frames)
            frames = []
            gc()
        end
        yield()
        diff = (1/60) - toq()
        while diff >= 0.001
            tic()
            sleep(0.001) # sleep for the minimal amount of time
            diff -= toq()
        end
        was_recording = record
    end
    GLWindow.destroy!(window)
    GLVisualize.cleanup_old_screens()
end


function get_dpi(window)
    monitor = GLFW.GetPrimaryMonitor()
    props = GLWindow.MonitorProperties(monitor)
    props.dpi[1]# we do not start fiddling with differently scaled xy dpi's
end


immutable Millimeter
end
const mm = Millimeter()
function Base.:(*)(x::Millimeter, y::Number)
    round(Int, y * pixel_per_mm)
end
function Base.:(*)(x::Number, y::Millimeter)
    round(Int, x * pixel_per_mm)
end


function init()

    w = glscreen("GLPlot")

    preserve(map(handle_drop, w.inputs[:dropped_files]))


    global const pixel_per_mm = get_dpi(w)/25.4


    global const icon_size = Signal(10mm)
    w.inputs[:key_pressed] = const_lift(GLAbstraction.singlepressed,
        w.inputs[:mouse_buttons_pressed],
        GLFW.MOUSE_BUTTON_LEFT
    )
    button_pos = map(w.area) do a
        Point2f0[(0, a.h/2)]
    end
    button_width = 1.5mm
    edit_screen_show_button = visualize(
        (SimpleRectangle{Float32}(0, 0, button_width, button_width*2), button_pos),
        offset=Vec2f0(0, -button_width),
        color=RGBA{Float32}(0.6,0.6,0.6,1)
    )
    tarea = map(toolbar_area, w.area, icon_size)

    show_edit_screen = toggle(edit_screen_show_button, w, false)
    edit_screen_area = map(edit_rectangle,
        show_edit_screen, w.area, tarea
    )


    global const viewing_screen = Screen(w,
        name=Symbol("Viewing Screen"),
        area=map(viewing_area, tarea, edit_screen_area),
        color=RGBA{Float32}(1,1,1,1)
    )
    global const toolbar_screen = Screen(w, area=tarea)
    global const edit_screen = Screen(
        w, area=edit_screen_area,
        color=RGBA{Float32}(0.9,0.9,0.9,1)
    )
    _view(edit_screen_show_button, edit_screen, camera=:fixed_pixel)
    play_record, record_sig = toggle_button(imload("record.png"), imload("break.png"), w)
    compute_record, compute_sig = toggle_button(imload("play.png"), imload("break.png"), w)
    persp_ortho, persp_ortho_toggle_sig = toggle_button(imload("perspective.png"), imload("ortho.png"), w)
    persp_ortho_sig = map(persp_ortho_toggle_sig) do isp
        isp && return GLAbstraction.PERSPECTIVE
        GLAbstraction.ORTHOGRAPHIC
    end
    cube = cubecamera(viewing_screen, persp_ortho_sig)

    image_names = ["center", "screenshot"]
    tools = Matrix{BGRA{U8}}[imload("$name.png") for name in image_names]
    center_b, center_s = button(tools[1], w)
    screenshot_b, screenshot_s = button(tools[2], w)

    tools = [center_b, screenshot_b, play_record, persp_ortho, compute_record]
    tools_robjs = Any[]

    i = 0
    for tool in tools
        robj = layout!(layout_pos_ho(i), visualize(tool))
        _view(robj, toolbar_screen, camera=:fixed_pixel)
        push!(tools_robjs, robj.children[])
        i += 1
    end
    preserve(map(center_s) do pressed
        if pressed
            center!(viewing_screen)
        end
        nothing
    end)
    preserve(map(screenshot_s) do pressed
        if pressed
            screenshot(viewing_screen, path=joinpath(homedir(), "Desktop", "glplot.png"))
        end
        nothing
    end)
    rot = cube.children[][:model]

    cube.children[][:model] = map(rot, icon_size) do r, ip
        half = ip/2
        translationmatrix(Vec3f0(half,i*ip + i*2 + half,0))*r*scalematrix(Vec3f0(half))
    end
    _view(cube, toolbar_screen, camera=:fixed_pixel)

    GLVisualize.add_screen(viewing_screen)
    @materialize scroll, mouseposition = edit_screen.inputs
    should_scroll = map(mouseposition) do mb
        isinside(value(w.area), mb...)
    end
    scroll = filterwhen(should_scroll, value(scroll), scroll)
    edit_screen.inputs[:menu_scroll] = foldp(0, scroll) do v0, s
        v0+(ceil(Int, s[2])*15)
    end
    global _renderloop_task = @async glplot_renderloop(w, compute_sig, record_sig)
    viewing_screen
end

function block()
    global _renderloop_task
    wait(_renderloop_task)
end
