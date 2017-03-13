# To fully work, needs GLVisualize sd/thaxis

module GLImshow

    using GLPlot, GLVisualize, GLAbstraction, Colors, GeometryTypes
    using Reactive, GLWindow, FileIO, FixedSizeArrays, AxisArrays, GLFW
    import GLVisualize: IRect, mm, toggle_button, button, slider
    import GLAbstraction: imagespace
    using NIfTI

    function IRect(xy::FixedVector, w, h)
        IRect(xy[1], xy[2], w, h)
    end
    function IRect(x, y, wh::FixedVector)
        IRect(x, y, wh[1], wh[2])
    end
    function IRect(xy::FixedVector, wh::FixedVector)
        IRect(xy[1], xy[2], wh[1], wh[2])
    end
    function FRect(x, y, w, h)
        SimpleRectangle{Float32}(x, y, w, h)
    end
    function FRect(r::SimpleRectangle)
        SimpleRectangle{Float32}(r.x, r.y, r.w, r.h)
    end
    function FRect(xy::FixedVector, w, h)
        SimpleRectangle{Float32}(xy[1], xy[2], w, h)
    end
    function FRect(x, y, wh::FixedVector)
        SimpleRectangle{Float32}(x, y, wh[1], wh[2])
    end
    function FRect(xy::FixedVector, wh::FixedVector)
        SimpleRectangle{Float32}(xy[1], xy[2], wh[1], wh[2])
    end

    global const iconsize = 5mm
    global const path_s = Signal("")
    global const loaded_image = Signal(Any, nothing)

    const screens = []
    screen() = (init(); screens[1])
    editscreen() = (init(); screens[2])

    function imshow(path::AbstractString)
        init()
        isfile(path) || error("no file found at $path")
        push!(path_s, path)
    end
    function imshow(image)
        init()
        push!(loaded_image, image)
    end


    function init()
        if isempty(screens) || !(isopen(first(screens)))
            global loaded_image
            global path_s
            push!(loaded_image, nothing)
            push!(path_s, "")
            empty!(screens)
            rootscreen = glscreen()
            @async GLWindow.waiting_renderloop(rootscreen)

            area1, area2 = y_partition_abs(rootscreen.area, 3iconsize + 6mm)
            edit_screen = Screen(rootscreen, area = area1, stroke = (1, RGBA(0.9f0, 0.9f0, 0.9f0, 1f0)))
            screen = Screen(rootscreen, area = area2)
            push!(screens, screen, edit_screen)
            area = Signal(FRect(value(screen.inputs[:window_area])))
            cam = DummyCamera(area, Signal(eye(Mat4f0)), Signal(eye(Mat4f0)), Signal(eye(Mat4f0)))
            @materialize mouseposition, mouse_buttons_pressed, buttons_pressed, scroll = screen.inputs
            mouseposition = map(Vec2f0, mouseposition)
            left_pressed = const_lift(GLAbstraction.pressed, mouse_buttons_pressed, GLFW.MOUSE_BUTTON_LEFT)
            pan = const_lift(==, buttons_pressed, Set([GLFW.KEY_SPACE]))
            mousepan = GLAbstraction.dragged_diff(mouseposition, left_pressed, pan)
            proportion_v, preserveratio_s = toggle_button(
                "●", "⬬",
                edit_screen, relative_scale = iconsize
            )
            preserveratio = map(preserveratio_s) do preserveratio
                if value(preserveratio_s)
                    a = value(area)
                    w1 = Vec2f0(widths(a))
                    w2 = Vec2f0(widths(screen))
                    ratio = w2 ./ w1
                    w1 = if ratio[1] > ratio[2]
                        s = w2[1] ./ w2[2]
                        Vec2f0(s * w1[2], w1[2])
                    else
                        s = w2[2] ./ w2[1]
                        Vec2f0(w1[1], s * w1[1])
                    end
                    update_cam!(cam, FRect(a.x, a.y, w1))
                end
                nothing
            end
            preserve(preserveratio)
            rect = selection_rect(screen)

            rect_camspace = map(rect) do rect
                mini = minimum(rect)
                maxi = maximum(rect)
                _mini = Vec2f0(min(mini[1], maxi[1]), min(mini[2], maxi[2]))
                _maxi = Vec2f0(max(mini[1], maxi[1]), max(mini[2], maxi[2]))
                rect = FRect(_mini, _maxi - _mini)
                oldarea = value(area)
                screenarea = value(screen.area)
                iscale = wscale(screenarea, oldarea)
                whold = widths(oldarea)
                xy = (minimum(rect) .* iscale) .+ minimum(oldarea)
                w1 = widths(rect) .* iscale
                if value(preserveratio_s)
                    w2 = Vec2f0(widths(screen))
                    ratio = w2 ./ w1
                    w1 = if ratio[1] > ratio[2]
                        s = w2[1] ./ w2[2]
                        Vec2f0(s * w1[2], w1[2])
                    else
                        s = w2[2] ./ w2[1]
                        Vec2f0(w1[1], s * w1[1])
                    end
                end
                update_cam!(cam, FRect(xy, w1))
                nothing
            end
            preserve(rect_camspace)
            translate_s = map(mousepan) do t
                a = value(area)
                st = t .* wscale(value(screen.area), a)
                update_cam!(cam, FRect(minimum(a) .+ st, widths(a)))
                nothing
            end
            preserve(translate_s)
            zoom_s = map(scroll) do x
                zoom = Float32(x[2])
                if zoom != 0
                    a = value(area)
                    z = 1 + (zoom * 0.10)
                    mp = value(mouseposition)
                    mp = (mp .* wscale(value(screen.area), a)) + minimum(a)
                    p1, p2 = minimum(a), maximum(a)
                    p1, p2 = p1 - mp, p2 - mp # translate to mouse position
                    p1, p2 = z * p1, z * p2
                    p1, p2 = p1 + mp, p2 + mp
                    update_cam!(cam, FRect(p1, p2 - p1))
                    z
                end
                0f0
            end
            preserve(zoom_s)
            reset_v, reset_s = button("⛶", edit_screen, relative_scale = iconsize)
            # obviously doesn't work with multiple images!
            preserve(map(screen.inputs[:dropped_files]) do x
                if !isempty(x)
                    push!(path_s, first(x))
                    yield()
                end
            end)

            path_load_s = map(path_s) do path
                if isfile(path)
                    try
                        f, ext = splitext(path)
                        im = if ext == ".nii" # hack for nii not being part of FileIO yet
                            x = niread(path).raw
                            a, b = extrema(x)
                            x .= (x .- a) ./ (b -a)
                            Gray.(x)
                        else
                            load(path)
                        end
                        push!(loaded_image, im)
                    catch e
                        warn(e)
                    end
                end
                nothing
            end
            preserve(path_load_s)

            img_s = foldp(value(loaded_image), loaded_image, typ = Any) do v0, im
                if im != nothing
                    if v0 != nothing
                        delete!(screen, v0[2].children[])
                        for comp in v0[3], elem in comp.children # TODO define a delete for Composables
                            delete!(edit_screen, elem)
                        end
                    end
                    slideraxis = if ndims(im) <= 2
                    elseif isa(im, AxisArray)
                        axisnames(im)[3:end]
                    elseif ndims(im) == 3
                        ["z"]
                    elseif ndims(im) == 4
                        ["z", "time"]
                    end
                    slider_list = GLAbstraction.Composable[]
                    slider_signals = []
                    for i = 1:(ndims(im) - 2)
                        label = slideraxis[i]
                        slider_v, slider_s = slider(1:size(im, 2+i), edit_screen, icon_size = iconsize, knob_scale = 3mm)
                        label_v = visualize(
                            map(z-> @sprintf("%s: %5d ", label, z), slider_s),
                            color = RGBA(0f0, 0f0, 0f0, 1f0), relative_scale = iconsize
                        )
                        push!(slider_signals, slider_s)
                        push!(slider_list, label_v, slider_v)
                    end
                    img_s = map(Signal(im), slider_signals...) do img, idx...
                        if isempty(idx)
                            img
                        else
                            img[:, :, idx...]
                        end
                    end
                    if !isempty(slider_list)
                        gui_list = visualize(
                            slider_list,
                            gap = 3mm, lastposition = Vec3f0(1mm, 1mm + iconsize, 0),
                            direction = 1
                        )
                        _view(gui_list, edit_screen, camera = :fixed_pixel)
                    end
                    imvis = visualize(img_s)
                    _view(imvis, screen, camera = cam)
                    reset_to_img!(imvis, cam, preserveratio_s)
                    return img_s, imvis, slider_list
                end
                return v0
            end
            preserve(img_s)
            current_value = map(mouseposition, img_s) do mp, imgvis
                if imgvis != nothing
                    a = value(area)
                    mp = mp - 0.5
                    mp = (mp .* wscale(value(screen.area), a)) + minimum(a)
                    bb = value(boundingbox(imgvis[2]))
                    img = value(imgvis[1])
                    w1 = Vec2f0(widths(bb))
                    j, i = round(Int, (mp ./ w1) .* Vec2f0(size(img, 2), size(img, 1)))
                    i = size(img, 1) - i
                    if checkbounds(Bool, img, i, j) && value(screen.inputs[:mouseinside])
                        color = img[i, j]
                        return sprint() do io
                            print(io, "value at ")
                            print(io, "$i $j : ")
                            showcompact(io, color)
                            # img[i, j] = RGB(1, 0, 0)
                            # push!(imgvis[1], img)
                        end, RGBA{Float32}(color)
                    end
                end
                " ", RGBA{Float32}(1,1,1,0)
            end
            preserve(current_value)
            current_valuestr_vis = visualize(
                map(first, current_value), color = RGBA(0f0, 0f0, 0f0, 1f0),
                relative_scale = iconsize
            )
            current_value_vis = visualize(
                (ROUNDED_RECTANGLE, [Point2f0(0)]),
                color = map(last, current_value),
                scale = Vec2f0(iconsize),
                offset = Vec2f0(0)
            )

            list = GLAbstraction.Composable[
                proportion_v, reset_v,
                current_valuestr_vis, current_value_vis
            ]

            gui_list1 = visualize(
                list,
                gap = 2mm, lastposition = Vec3f0(1mm, 1mm, 0),
                direction = 1
            )
            _view(gui_list1, edit_screen, camera = :fixed_pixel)

            resetcam = map(reset_s, img_s) do reset, img_vis
                if reset && img_vis != nothing
                    reset_to_img!(img_vis[2], cam, preserveratio_s)
                end
                nothing
            end
            preserve(resetcam)
        end
    end

    function reset_to_img!(imrobj, cam, preserveratio_s)
        bb = value(boundingbox(imrobj))
        w1 = Vec2f0(widths(bb))
        if value(preserveratio_s)
            w2 = Vec2f0(widths(screen()))
            ratio = w2 ./ w1
            w1 = if ratio[1] > ratio[2]
                s = w2[1] ./ w2[2]
                Vec2f0(s * w1[2], w1[2])
            else
                s = w2[2] ./ w2[1]
                Vec2f0(w1[1], s * w1[1])
            end
        end
        p = minimum(w1) .* 0.001 # 2mm padding
        update_cam!(cam, FRect(-p, -p, w1 .+ 2p))
        nothing
    end

    function selection_rect(
            screen,
            key = GLFW.MOUSE_BUTTON_LEFT,
            button = Set([GLFW.KEY_LEFT_CONTROL, GLFW.KEY_SPACE])
        )
        @materialize mouseposition, mouse_buttons_pressed, buttons_pressed = screen.inputs
        is_dragging = false
        rect = IRect(0,0,0,0)

        dragged_rect = foldp(
                (is_dragging, rect),
                mouse_buttons_pressed, mouseposition, buttons_pressed
            ) do v0, m_pressed, m_pos, bpressed

            was_dragging, rect = v0
            keypressed = (length(m_pressed) == 1) && (key in m_pressed) && button == bpressed
            p = Vec2f0(m_pos)
            if was_dragging
                min = minimum(rect)
                wh = p - min
                rect = IRect(min, wh)
                if keypressed # was dragging and still dragging
                    return true, rect
                else
                    return false, rect # anything else will stop the dragging
                end
            elseif keypressed # was not dragging, but now key is pressed
                return true, IRect(p, 0, 0)
            end
            return v0
        end
        lw = 2f0
        rect = map(last, dragged_rect)
        visible = map(first, dragged_rect)
        prim = map(rect) do r
            x = AABB{Float32}(r)
            AABB(minimum(x) .+ Vec3f0(0,0,1), widths(x))
         end
        rect_vis = visualize(
            prim, :lines,
            visible = visible,
            pattern = [0.0, lw, 2lw, 3lw, 4lw],
            thickness = lw,
            color = RGBA(0.7f0, 0.7f0, 0.7f0, 0.9f0)
        )
        _view(rect_vis, screen, camera = :fixed_pixel)
        released = foldp((false, false), visible) do v0, v
            v, v0[1] && !v
        end
        filterwhen(map(last, released), value(screen.area), rect)
    end

    function update_cam!(cam, area)
        x, y = minimum(area)
        w, h = widths(area) ./ 2f0
        cam.window_size.value = FRect(area)
        cam.projection.value = orthographicprojection(-w, w, -h, h, -10_000f0, 10_000f0)
        cam.view.value = translationmatrix(Vec3f0(-x - w, -y - h, 0))
    end

    wscale(screenrect, viewrect) = widths(viewrect) ./ widths(screenrect)

end

using .GLImshow: imshow
using Colors
GLImshow.imshow(rand(RGBA{Float32}, 10, 10, 10))


# or try drag and drop!
