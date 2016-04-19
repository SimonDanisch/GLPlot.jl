using Reactive, GLVisualize, GeometryTypes, Colors, GLWindow, GLAbstraction
w = glscreen()

tarea = map(w.area) do pa
    SimpleRectangle(0, 0, 120, pa.h)
end

function toggle(robj::Context, window)
    foldp(false, window.inputs[:mouse_buttons_pressed]) do v0, mbp
        if GLAbstraction.singlepressed(mbp, GLFW.MOUSE_BUTTON_LEFT)
            id, index = value(mouse2id(window))
            if id==robj.children[].id
                return !v0
            end
        end
        v0
    end
end
edit_screen_show_button = layout(w.area,
    visualize(
        Rectangle(1-0.01,0.5,0.01, 0.01), color=RGBA{Float32}(0,0,0,1)
    )
)
edit_screen_show_button = edit_screen_show_button[1]
show_edit_screen = toggle(edit_screen_show_button, w)
view(edit_screen_show_button, camera=:fixed_pixel)
edit_screen_area = map(show_edit_screen, w.area) do visible, area
    w = visible ? 160 : 0
    SimpleRectangle(area.w-w, 0, w, area.h)
end
toolbar_screen = Screen(w, area=tarea)

edit_screen_area

edit_screen = Screen(w, area=edit_screen_area, color=RGBA{Float32}(0,0,0,1))

tools = 5
function update_positions(v0, mp, area)
    positions, colors = v0
    if isinside(area, mp...)
        for (i, p) in enumerate(positions)
            x = 1-(clamp(abs(p[2]+37 - mp[2]), 0, 200) / 200)
            y = clamp(abs(area.w-mp[1]), 0, 62)*x
            positions[i] = Point2f0(-60+y, p[2])
            alpha = 1-(clamp(abs(p[2]+37 - mp[2]), 0, 100) / 100)
            colors[i] = RGBA{Float32}(0.8,0.8,0.8,alpha)
        end
    else
        for (i, p) in enumerate(linspace(0, area.h, length(positions)))
            positions[i] = Point2f0(-68, p)
            colors[i] = RGBA{Float32}(0.8,0.8,0.8,0)
        end
    end
    positions, colors
end
ma_posis = zeros(Point2f0, tools)
ma_colsis = zeros(RGBA{Float32}, tools)

ps = foldp(update_positions,
    (ma_posis, ma_colsis),
    w.inputs[:mouseposition], tarea
)
using GLFW
key_pressed = const_lift(GLAbstraction.singlepressed, w.inputs[:mouse_buttons_pressed], GLFW.MOUSE_BUTTON_LEFT)
const m2id = mouse2id(w)
scale = Signal(Vec2f0(74))
robj = visualize((Circle, map(first, ps)), scale=scale, glow_width=2f0, glow_color=map(last, ps))

function on_click(isclicked)
    id, index = value(m2id)
    if isclicked && id==robj.children[].id && tools >= index
        push!(scale, Vec2f0(76))
        return index
    end
    push!(scale, Vec2f0(74))
    return 0
end
tool_clicked = map(on_click, key_pressed)


view(robj, toolbar_screen, camera=:fixed_pixel)
view(visualize(rand(Float32, 32,32)))
@async renderloop(w)



tarea = map(toolbar_area, w.area)
button_pos = Signal(Point2f0(w.area.value.w, w.area.value.h/2))
edit_screen_show_button = visualize(
    (Rectangle(10,10,10,20), button_pos), 
    color=RGBA{Float32}(0.6,0.6,0.6,1)
)

show_edit_screen = toggle(edit_screen_show_button, w)
view(edit_screen_show_button, camera=:fixed_pixel)
edit_screen_area = map(edit_rectangle, 
    show_edit_screen, w.area, Signal(button_pos)
)

toolbar_screen = Screen(w, area=tarea)

edit_screen = Screen(w, area=edit_screen_area, color=RGBA{Float32}(0,0,0,1))

tools = 5

ma_posis = zeros(Point2f0, tools)
ma_colsis = zeros(RGBA{Float32}, tools)

ps = foldp(update_positions,
    (ma_posis, ma_colsis),
    w.inputs[:mouseposition], tarea
)

key_pressed = const_lift(GLAbstraction.singlepressed, w.inputs[:mouse_buttons_pressed], GLFW.MOUSE_BUTTON_LEFT)
const m2id = mouse2id(w)
scale = Signal(Vec2f0(74))
robj = visualize((Circle, map(first, ps)), scale=scale, glow_width=2f0, glow_color=map(last, ps))


tool_clicked = map(on_click, key_pressed)
view(robj, toolbar_screen, camera=:fixed_pixel)
view(visualize(rand(Float32, 32,32)))
