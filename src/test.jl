using Reactive, GLVisualize, GeometryTypes, Colors, GLWindow, GLAbstraction, GLFW, FileIO
w = glscreen()
@async renderloop(w)
function imload(name)
    rotr90(Matrix{BGRA{U8}}(load(Pkg.dir("GLPlot", "src", "icons", name))))
end
key_pressed = const_lift(GLAbstraction.singlepressed,
    w.inputs[:mouse_buttons_pressed],
    GLFW.MOUSE_BUTTON_LEFT
)
function button(a, window)
    robj = visualize(a).children[]
    const m2id = mouse2id(w)
    is_pressed = droprepeats(map(key_pressed) do isclicked
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


icon_percent = 1//20 # of screen

toolbar_area(pa) = SimpleRectangle(0, 0, Int(icon_percent*pa.w), pa.h)
viewing_area(area_l, area_r) = SimpleRectangle(area_l.w, 0, area_r.x-area_l.w, area_r.h)
function edit_rectangle(visible, area, tarea, arrow_pos_s)
    w = visible ? div(area.w,4) : 0
    x = area.w-w
    push!(arrow_pos_s, [Point2f0(x-tarea.w, area.h/2)])
    SimpleRectangle(x, 0, w, area.h)
end
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


viewing_screen = Screen(w,
    area=map(viewing_area, tarea, edit_screen_area),
    color=RGBA{Float32}(1,1,1,1)
)
toolbar_screen = Screen(w, area=tarea)
edit_screen = Screen(w, area=edit_screen_area, color=RGBA{Float32}(0.95,0.95,0.95,1))

#layout!(SimpleRectangle(0,0,icon_size, icon_size), cube)





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

function item_area(la, deleted)
    y = la.y-la.h-2
    deleted && return SimpleRectangle(la.x, y, la.w, 0)
    return SimpleRectangle(la.x, y, la.w, 45)
end

function glplot(arg1, style=:default; kw_args...)
    visible_button, visible_toggle = toggle_button(
        imload("showing.png"), imload("notshowing.png"), edit_screen
    )
    delete_button, del_signal = button(
        imload("delete.png"), edit_screen
    )
    robj = visualize(arg1, style; visible=visible_toggle, kw_args...).children[]
    view(robj, viewing_screen)
    not_del_signal = droprepeats(foldp(false, del_signal) do v0, x
        v0 && return v0
        if x
            for (i, r) in enumerate(viewing_screen.renderlist)
                if robj.id == r.id
                    splice!(viewing_screen.renderlist, i)
                    return x
                end
            end
        end
        return x
    end)
    icon_size = 45f0

    if isempty(edit_screen.children)
        last_area = map(edit_screen.area, not_del_signal) do a, deleted
            deleted && return SimpleRectangle(0, a.h-2, a.w, 0)
            is = Int(icon_size)
            return SimpleRectangle(0, a.h-2, a.w, is)
        end
    else
        last_area = last(edit_screen.children).area
    end
    new_item_screen = Screen(edit_screen, area=map(item_area, last_area, not_del_signal))

    robj1 = layout!(SimpleRectangle(0f0, 0f0, icon_size, icon_size), visible_button)
    robj2 = layout!(SimpleRectangle(icon_size, 0f0, icon_size, icon_size), delete_button)
    view(robj1, new_item_screen, camera=:fixed_pixel)
    view(robj2, new_item_screen, camera=:fixed_pixel)
    robj
end
glplot(rand(Float32, 32,32), ranges=((1,2), (1,2)))

glplot(rand(Float32, 32,32), ranges=((1,2), (0,1)))
glplot(rand(Float32, 32,32), ranges=((0f0,1f0), (1f0,2f0)), :surface)
