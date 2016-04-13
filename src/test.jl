using Reactive, GLVisualize, GeometryTypes, Colors, GLWindow, GLAbstraction
w = glscreen();@async renderloop(w)

tarea = map(w.area) do pa
    SimpleRectangle(0, 0, 120, pa.h)
end
toolbar_screen = Screen(w, area=tarea)
tools = 5
lerp(a, b, t) = a + t*(b-a)
function update_positions(v0, mp, area)
    positions, colors = v0
    if isinside(area, mp...)
        for (i, p) in enumerate(positions)
            x = 1-(clamp(abs(p[2]+37 - mp[2]), 0, 200) / 200)
            y = clamp(abs(area.w-mp[1]), 0, 62)*x
            positions[i] = Point2f0(-60+y, p[2])
            colors[i] = RGBA{Float32}(0.9,0.1,0.9,1)
        end
    else
        for (i, p) in enumerate(linspace(0, area.h, length(positions)))
            positions[i] = Point2f0(-68, p)
            colors[i] = RGBA{Float32}(0.9,0.9,0.9,0)
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
