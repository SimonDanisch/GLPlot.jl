using Reactive, GLVisualize, GeometryTypes, Colors, GLWindow, GLAbstraction, GLFW, FileIO
w = glscreen()
icon_size = 74
toolbar_area(pa) = SimpleRectangle(0, 0, 120, pa.h)
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
function edit_rectangle(visible, area, arrow_pos_s)
    w = visible ? div(area.w,4) : 0
    x = area.w-w
    push!(arrow_pos_s, [Point2f0(x, area.h/2)])
    SimpleRectangle(x, 0, w, area.h)
end
viewing_area(area) = SimpleRectangle(0, 0, area.x, area.h)
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
        for (i, p) in enumerate(linspace(74, area.h-74*2, length(positions)))
            positions[i] = Point2f0(-68, p)
            colors[i] = RGBA{Float32}(0.8,0.8,0.8,0)
        end
    end
    positions, colors
end
function on_click(isclicked, m2id, scalzies, scale, scaleclick, tools)
    id, index = value(m2id)
    if isclicked && id==robj.children[].id && tools >= index
        s = value(scalzies)
        s[index] = Vec2f0(scaleclick)
        push!(scalzies, s)
        return index
    end
    push!(scalzies, fill(Vec2f0(scale), tools))
    return 0
end

glload(name) = load(Pkg.dir("GLPlot", "src", "icons", name))
images = Matrix{BGRA{U8}}[glload("cube_camera.png").data, glload("screenshot.png").data, glload("wasd_camera.png").data]

tools = length(images)
tarea = map(toolbar_area, w.area)
button_pos = Signal([Point2f0(w.area.value.w, w.area.value.h/2)])
edit_screen_show_button = visualize(
    (SimpleRectangle(-10,-10,10,20), button_pos),
    color=RGBA{Float32}(0.6,0.6,0.6,1)
)

show_edit_screen = toggle(edit_screen_show_button, w)
edit_screen_area = map(edit_rectangle,
    show_edit_screen, w.area, Signal(button_pos)
)

viewing_screen = Screen(w,
    area=map(viewing_area, edit_screen_area),
    color=RGBA{Float32}(1,1,1,0)
)

toolbar_screen = Screen(w, area=tarea)
edit_screen    = Screen(w, area=edit_screen_area, color=RGBA{Float32}(0,0,0,1))
cam, button_pers, cube = cubecamera(viewing_screen)
layout!(SimpleRectangle(0,0,icon_size, icon_size), cube)

ma_posis = zeros(Point2f0, tools)
ma_colsis = zeros(RGBA{Float32}, tools)
scalzies = Signal(fill(Vec2f0(74), tools))

ps = foldp(update_positions,
    (ma_posis, ma_colsis),
    w.inputs[:mouseposition], tarea
)

key_pressed = const_lift(GLAbstraction.singlepressed,
    w.inputs[:mouse_buttons_pressed],
    GLFW.MOUSE_BUTTON_LEFT
)
const m2id = mouse2id(w)

robj = visualize(
    (Circle, map(first, ps)),
    image=Texture(images),
    scale=scalzies, glow_width=2f0,
    glow_color=map(last, ps)
)


tool_clicked = map(
    on_click,
    key_pressed, Signal(m2id), Signal(scalzies),
    Signal(icon_size), Signal(icon_size+2), Signal(tools)
)

view(robj, toolbar_screen, camera=:fixed_pixel)
view(cube, toolbar_screen, camera=:fixed_pixel)
view(edit_screen_show_button, camera=:fixed_pixel)
view(visualize(rand(Float32, 32,32)), viewing_screen)

renderloop(w)
