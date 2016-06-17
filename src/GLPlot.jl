VERSION >= v"0.4.0-dev+6521" && __precompile__(true)

module GLPlot

export glplot

using GLVisualize, GLWindow, ModernGL, Reactive, GLAbstraction, Colors
using GeometryTypes, GLFW, FileIO, FixedSizeArrays
include("editing.jl")
function imload(name)
    rotl90(Matrix{BGRA{U8}}(load(Pkg.dir("GLPlot", "src", "icons", name))))
end

function button(a, window)
    robj = visualize(a).children[]
    const m2id = mouse2id(window)
    is_pressed = droprepeats(map(window.inputs[:key_pressed]) do isclicked
        isclicked && value(m2id).id == robj.id
    end)

    robj[:model] = const_lift(is_pressed, robj[:model], boundingbox(robj)) do ip, old, bb
        ip && return old
        scalematrix(Vec3f0(0.95))*old
    end
    robj, is_pressed
end

function toggle_button(a, b, window)
    id = Signal(0)
    ab_bool = toggle(id, window)
    a_b = map(ab_bool) do aORb
        aORb ? a : b
    end
    robj = visualize(a_b)
    push!(id, robj.children[].id)
    robj, ab_bool
end
function toggle(id1::Union{Signal{Int}, Int}, window, default=true)
    droprepeats(foldp(default, window.inputs[:mouse_buttons_pressed]) do v0, mbp
        if GLAbstraction.singlepressed(mbp, GLFW.MOUSE_BUTTON_LEFT)
            id2, index = value(mouse2id(window))
            if value(id1)==id2
                return !v0
            end
        end
        v0
    end)
end
function toggle(robj::RenderObject, window, default=true)
    toggle(Int(robj.id), window, default)
end
function toggle(robj::Context, window, default=true)
    toggle(robj.children[], window, default)
end


toolbar_area(pa) = SimpleRectangle(0, 0, round(Int, icon_percent*pa.w), pa.h)
viewing_area(area_l, area_r) = SimpleRectangle(area_l.w, 0, area_r.x-area_l.w, area_r.h)
function edit_rectangle(visible, area, tarea, arrow_pos_s)
    w = visible ? div(area.w,4) : 0
    x = area.w-w
    push!(arrow_pos_s, [Point2f0(x-tarea.w, area.h/2)])
    SimpleRectangle(x, 0, w, area.h)
end

function item_area(la, deleted, item_height)
    y = la.y-item_height-2
    deleted && return SimpleRectangle(la.x, la.y, la.w, 0)
    return SimpleRectangle(la.x, y, la.w, item_height)
end

function edit_item_area(la, item_height)
    y = la.y-item_height-2
    return SimpleRectangle(la.x+3, y, la.w-6, item_height)
end

function glplot(arg1, style=:default; kw_args...)
    visible_button, visible_toggle = toggle_button(
        imload("showing.png"), imload("notshowing.png"), edit_screen
    )
    delete_button, del_signal = button(
        imload("delete.png"), edit_screen
    )
    edit_button, no_edit_signal = toggle_button(
        imload("play.png"), rotr90(imload("play.png")), edit_screen
    )
    icon_size = 45f0
    item_height = Signal(0)
    robj = visualize(arg1, style; visible=visible_toggle, kw_args...).children[]
    view(robj, viewing_screen)
    not_del_signal = droprepeats(foldp(false, del_signal) do v0, to_delete
        v0 && return v0
        to_delete && delete!(viewing_screen, robj)
        return to_delete
    end)
    scroll = edit_screen.inputs[:menu_scroll]
    if isempty(edit_screen.children)
        last_area = map(edit_screen.area, not_del_signal, Signal(Int(icon_size)), scroll) do a, deleted, ih, s
            deleted && return SimpleRectangle(0, a.h+s, a.w, 0)
            return SimpleRectangle(0, a.h-ih+s, a.w, ih)
        end
    else
        last_area = last(edit_screen.children).area
    end
    edit_signal = map(!, no_edit_signal)
    itemarea = map(item_area, last_area, not_del_signal, Signal(Int(icon_size)))
    edititemarea = map(edit_item_area, itemarea, item_height)
    new_item_screen = Screen(edit_screen, area=itemarea)
    edit_item_screen = Screen(edit_screen, area=edititemarea)
    offset = 0f0
    for elem in (visible_button, delete_button, edit_button)
        layout!(SimpleRectangle(offset*icon_size, 0f0, icon_size, icon_size), elem)
        view(elem, new_item_screen, camera=:fixed_pixel)
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

    robj
end



function __init__()

    w = glscreen()
    @async renderloop(w)

    global const icon_percent = 1//20 # of screen

    w.inputs[:key_pressed] = const_lift(GLAbstraction.singlepressed,
        w.inputs[:mouse_buttons_pressed],
        GLFW.MOUSE_BUTTON_LEFT
    )
    button_pos = Signal([Point2f0(w.area.value.w, w.area.value.h/2)])
    edit_screen_show_button = visualize(
        (SimpleRectangle(-10,-10,10,20), button_pos),
        color=RGBA{Float32}(0.6,0.6,0.6,1)
    )
    tarea = map(toolbar_area, w.area)

    show_edit_screen = toggle(edit_screen_show_button, w, false)
    edit_screen_area = map(edit_rectangle,
        show_edit_screen, w.area, tarea, Signal(button_pos)
    )


    global const viewing_screen = Screen(w,
        area=map(viewing_area, tarea, edit_screen_area),
        color=RGBA{Float32}(1,1,1,1)
    )
    global const toolbar_screen = Screen(w, area=tarea)
    global const edit_screen = Screen(
        w, area=edit_screen_area, 
        color=RGBA{Float32}(0.95,0.95,0.95,1)
    )



    play_record, record_sig = toggle_button(imload("record.png"), imload("break.png"), w)
    persp_ortho, persp_ortho_toggle_sig = toggle_button(imload("perspective.png"), imload("ortho.png"), w)
    persp_ortho_sig = map(persp_ortho_toggle_sig) do isp
        isp && return GLAbstraction.PERSPECTIVE
        GLAbstraction.ORTHOGRAPHIC
    end
    cube = cubecamera(viewing_screen, persp_ortho_sig)

    map(record_sig) do should_record
        if should_record

        end

    end
    image_names = ["center", "screenshot"]
    tools = Matrix{BGRA{U8}}[imload("$name.png") for name in image_names]
    center_b, center_s = button(tools[1], w)
    screenshot_b, screenshot_s = button(tools[2], w)

    tools = [center_b, screenshot_b, play_record, persp_ortho]
    tools_robjs = Any[]
    pos = 50f0
    for tool in tools
        robj = layout!(SimpleRectangle(0f0, pos, 45f0, 45f0), visualize(tool))
        view(robj, toolbar_screen, camera=:fixed_pixel)
        push!(tools_robjs, robj.children[])
        pos += 49
    end
    pos += 20
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

    cube.children[][:model] = map(rot) do r
        translationmatrix(Vec3f0(21,pos,0))*r*scalematrix(Vec3f0(17))
    end
    view(cube, toolbar_screen, camera=:fixed_pixel)
    view(edit_screen_show_button, viewing_screen, camera=:fixed_pixel)
    @materialize scroll, mouseposition = edit_screen.inputs
    should_scroll = map(mouseposition) do mb
        isinside(value(w.area), mb...)
    end
    scroll = filterwhen(should_scroll, value(scroll), scroll)
    edit_screen.inputs[:menu_scroll] = foldp(0, scroll) do v0, s
        v0+(ceil(Int, s[2])*15)
    end
end
end
