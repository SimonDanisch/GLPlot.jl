VERSION >= v"0.4.0-dev+6521" && __precompile__(true)

module GLPlot

using GLVisualize, GLWindow, ModernGL, GeometryTypes, Reactive, GLAbstraction, Colors, ModernGL

export clearplot, glplot, windowroot



"""
Rounds up and down so that minimum and maximum of the grid ends in a step of the grid
"""
function round_down{T <: Vec}(toround::T, grid_steps::T)
    map(T) do i
        grid_step = (1f0/grid_steps[i])
        step = toround[i] ./ grid_step
        isinteger(step) && return toround[i]
        floor(step)*grid_step
    end
end
function round_up{T <: Vec}(toround::T, grid_steps::T)
    map(T) do i
        grid_step = (1f0/grid_steps[i])
        step = toround[i] ./ grid_step
        isinteger(step) && return toround[i]
        ceil(step)*grid_step
    end
end
"""
align the grid to end up always with on a step
"""
function align_grid(bb, grid_steps)
    mini = round_down(bb.minimum, grid_steps)
    maxi = round_up(bb.maximum, grid_steps)
    AABB{Float32}(mini, maxi)
end
function hascolormap(robj)
    (!haskey(robj.uniforms, :color) || !haskey(robj.uniforms, :color_norm)) && return false
    cmap = robj.uniforms[:color]
    isa(cmap, Texture) && eltype(cmap) <: Colorant
end


const RenderObjectDict = Dict{GLushort, RenderObject}()

function glplot(args...;window=WindowRoot, keyargs...)
    robj = visualize(args...;keyargs...).children[]
    RenderObjectDict[robj.id] = robj
    if hascolormap(robj)
        #cmap = colormap(robj[:color], robj[:color_norm], window)
        #view(cmap, window, camera=:fixed_pixel)
    end
    view(visualize(boundingbox(robj), :lines), window, camera=:perspective)
    view(robj, window, camera=:perspective)
    nothing
end

function align_top(top, boundingbox)
    translationmatrix(Vec3f0(top.x - minimum(boundingbox)[1], top.h-maximum(boundingbox)[2], 0))
end
function align_top_right(top::SimpleRectangle, boundingbox::AABB)
    translationmatrix(Vec3f0(top.w - maximum(boundingbox)[1], top.h-maximum(boundingbox)[2], 0))
end
function colormap(colormap, colornorm, window)
    robj = visualize(colormap)
    bb = value(robj.boundingbox)
    w = width(bb)

    text_min = visualize(@sprintf("%.4f", colornorm[1]), startposition=minimum(bb)+Vec3f0(w[1],-11,0))
    text_max = visualize(@sprintf("%.4f", colornorm[2]), startposition=maximum(bb)+Vec3f0(0,-11,0))

    bb = map(union, map(union, text_min.boundingbox, text_max.boundingbox), robj.boundingbox)
    trans = map(align_top, window.area, bb)
    Context(robj, text_min, text_max, parent=Context(trans))
end

function leftclicked(context, inputs)
    robj = context.children[]
    leftclicked = map(inputs[:mouse2id], inputs[:mouse_buttons_pressed]) do mh, mbp
        mh[1] == robj.id && mbp == [0]
    end
    leftclicked = filterwhen(leftclicked, false, leftclicked)
    map(x->robj, leftclicked)
end


function toolbar!(window)
    height = 64
    values = map(mouse2id(window)) do mh
        id, index = mh
        text = "nothing"
        if haskey(RenderObjectDict, id)
            robj = RenderObjectDict[id]
            if isa(robj.main, AbstractArray)
                sz = size(robj.main)
                indexes = ind2sub(sz, index)
                if checkbounds(Bool, sz, indexes...) # don't want to kill GLPlot if there is some glitch
                    text = string(gpu_data(robj.main)[indexes...])
                else
                    warn("indexes not in bounds in toolbar:hover tool. Indexes: $(indexes), array: $(typeof(robj.main)), $(size(robj.main))")
                end
            end
        end
        text
    end
    vr = visualize(values)
    savebutton = visualize("📷", color=RGBA{Float32}(0.9,0.9,0.9, 1.0))
    map(leftclicked(savebutton, window.inputs)) do robj
        screenshot(window)
    end
    toolbar_context = visualize([vr, savebutton], gap=5f0)
    trans = map(align_top_right, window.area, boundingbox(toolbar_context))
    view(Context(toolbar_context, parent=Context(trans)), window, camera=:fixed_pixel)
end

clearplot(w::Screen=WindowRoot) = empty!(w.renderlist)

windowroot() = WindowRoot

function __init__()
    w = glscreen()
    cubecamera(w)
    glClearColor(1,1,1,1)
    global WindowRoot = w
    toolbar!(w)
    @async renderloop(w)

end

end
