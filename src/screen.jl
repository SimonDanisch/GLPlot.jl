function handle_drop(files::Vector{String})
    for f in files
        try
            glplot(load(f))
        catch e
            warn(e)
        end
    end
end

toolbar_area(pa, toolbar_width) = IRect(0, 0, toolbar_width, pa.h)

function viewing_area(area_l, area_r)
    IRect(area_l.x+area_l.w, 0, area_r.x-area_l.w, area_r.h)
end

function edit_rectangle(visible, area, tarea)
    w = visible ? 70mm : 1.5mm
    x = area.w - w
    IRect(x, 0, w, area.h)
end

function edit_item_area(la, item_height, left_gap)
    y = la.y - item_height-2
    return IRect(left_gap, y, la.w, item_height)
end

layout_pos_ho(i) = map(icon_size()) do ip
    SimpleRectangle{Float32}(0, i*ip + i*2, ip, ip)
end
layout_pos_ver(i, border) = map(icon_size()) do ip
    SimpleRectangle{Float32}(i*ip + i*border, 0, ip, ip)
end


function save_record(frames)
    path = joinpath(homedir(), "Desktop")
    GLVisualize.create_video(frames, "test.webm", path, 0)
end

const _compute_callbacks = []
register_compute(f) = push!(_compute_callbacks, f)
poll_reactive() = (Base.n_avail(Reactive._messages) > 1) && Reactive.run_till_now()

const plotting_screens = Screen[]

viewing_screen() = (init(); plotting_screens[1])
edit_screen() = (init(); plotting_screens[2])
tool_screen() = (init(); plotting_screens[3])

function glplot_renderloop(window, compute_s, record_s)
    frames = []
    i = 0
    Reactive.stop()
    while isopen(window)
        tic()
        GLWindow.poll_glfw() # GLFW poll
        if Base.n_avail(Reactive._messages) > 0
            GLWindow.poll_reactive() # reactive poll
            record = !value(record_s)
            GLWindow.render_frame(window)
            GLWindow.swapbuffers(window)
        end
        yield()
        diff = (1 / 60) - toq()
        while diff >= 0.001
            tic()
            sleep(0.001) # sleep for the minimal amount of time
            diff -= toq()
        end
        yield()
    end
    GLWindow.destroy!(window)
end

const _icon_size = Signal(10mm)
icon_size() = _icon_size

global set_screenshotpath!, get_screenshotpath

let

    const screenshotpath = Ref(joinpath(homedir(), "Desktop", "glplot.png"))
    """
    Sets the current screen shot/recording path. Default is on users desktop
    """
    function set_screenshotpath!(path)
        screenshotpath[] = path
    end

    """
    Gets the current screen shot/recording path. Default is on users desktop
    """
    function get_screenshotpath()
        screenshotpath[]
    end

end


function init()
    if !isempty(plotting_screens) && isopen(first(plotting_screens))
        return # already initialized
    end
    empty!(plotting_screens)
    w = glscreen("GLPlot")

    preserve(map(handle_drop, w.inputs[:dropped_files]))

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
        offset = Vec2f0(0, -button_width),
        color = RGBA{Float32}(0.6,0.6,0.6,1)
    )
    tarea = map(toolbar_area, w.area, icon_size())

    show_edit_screen = toggle(edit_screen_show_button, w, false)
    edit_screen_area = map(edit_rectangle,
        show_edit_screen, w.area, tarea
    )


    viewing_screen = Screen(w,
        name = Symbol("Viewing Screen"),
        area = map(viewing_area, tarea, edit_screen_area),
        color = RGBA{Float32}(1,1,1)
    )
    toolbar_screen = Screen(w, area = tarea)
    edit_screen = Screen(
        w, area = edit_screen_area,
        color = RGBA{Float32}(0.9, 0.9, 0.9)
    )
    push!(plotting_screens, viewing_screen)
    push!(plotting_screens, edit_screen)
    push!(plotting_screens, toolbar_screen)

    _view(edit_screen_show_button, edit_screen, camera = :fixed_pixel)
    play_record, record_sig = toggle_button(imload("record.png"), imload("break.png"), w)
    compute_record, compute_sig = toggle_button(imload("play.png"), imload("break.png"), w)
    persp_ortho, persp_ortho_toggle_sig = toggle_button(imload("perspective.png"), imload("ortho.png"), w)

    persp_ortho_sig = map(persp_ortho_toggle_sig) do isp
        isp && return GLAbstraction.PERSPECTIVE
        GLAbstraction.ORTHOGRAPHIC
    end
    cube = cubecamera(viewing_screen, persp_ortho_sig)

    image_names = ["center", "screenshot"]
    tools = Matrix{BGRA{N0f8}}[imload("$name.png") for name in image_names]
    center_b, center_s = button(tools[1], w)
    screenshot_b, screenshot_s = button(tools[2], w)

    tools = [center_b, screenshot_b, play_record, persp_ortho, compute_record]
    tools_robjs = Any[]

    i = 0
    for tool in tools
        robj = layout!(layout_pos_ho(i), visualize(tool))
        _view(robj, toolbar_screen, camera = :fixed_pixel)
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
            screenshot(viewing_screen, path = get_screenshotpath())
        end
        nothing
    end)
    rot = cube.children[][:model]

    cube.children[][:model] = map(rot, icon_size()) do r, ip
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
        v0 + (ceil(Int, s[2]) * 15)
    end
    global _renderloop_task = @async glplot_renderloop(w, compute_sig, record_sig)
    viewing_screen
end

"""
Blocks the julia process as long as a window is open.
Usefull when running a GLPlot script not within some REPL.
"""
function block()
    global _renderloop_task
    wait(_renderloop_task)
end
