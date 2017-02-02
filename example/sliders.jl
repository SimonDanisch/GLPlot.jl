using GLPlot, GLAbstraction, GeometryTypes, Colors; GLPlot.init()
using GLWindow, Reactive, ModernGL, GLVisualize

f(x,y,a,b,c) = sin(x * a) ./ b^cos(y / c)


function init(n, a, b, c)
    x = linspace(-4f0, 4f0, n)
    # map the slider signals and great a matrix
    # this foldp is geared towards performance, which is why it mutates v0 in place
    # it's also fairly performant to do this:
    # map((a,b,c)-> [f(x,y,a,b,c) for x=x, y=x], a,b,c)
    v0 = Float32[f(x,y,value(a),value(b),value(c)) for x=x, y=x]
    surface = foldp(v0, a,b,c) do v0, a,b,c
        @inbounds for i = 1:n, j = 1:n
            v0[i,j] = f(x[i], x[j], a, b, c)
        end
        v0
    end;
    # plots surface
    surface_robj = glplot(
        surface, :surface,
        ranges=(x,x), boundinbox=nothing # doesn't calculate boundingbox, which is faster
    ).children[]
    #plot the grid, starting at -4,-4,-2, with width 8,8,5
    glplot(AABB(Vec3f0(-4,-4,-2), Vec3f0(8,8,5)), :grid)
    # Now we draw the controle lines. This should be available as a widget in the Future!
    # allocate an array for point position (performance optimization as well)
    pos_tmp = Point3f0[0]
    w = GLPlot.viewing_screen()
    m2id = mouse2id(w)
    pin_plot = doubleclick(w.inputs[:mouse_buttons_pressed], 0.1)
    index = droprepeats(foldp(((0,0), false), m2id, pin_plot) do v0, m2id, pin
        idx, waspinned = v0
        waspinned && !pin && return v0
        if m2id.id == surface_robj.id
            if m2id.index >= 1 && m2id.index <= n*n
                return ind2sub((n,n), m2id.index), pin
            end
        end
        idx, pin
    end)
    p_l_position = map(surface, index) do data, ij_pinned
        ij, _ = ij_pinned
        if ij != (0,0)
            slicex = Point3f0[(x[_x], x[ij[2]], data[_x, ij[2]]) for _x=1:n]
            slicey = Point3f0[(x[ij[1]], x[y], data[ij[1], y]) for y=1:n]
            pos_tmp[1] = (x[ij[1]], x[ij[2]], data[ij...])
            return vcat(slicex, Point3f0(Inf), slicey), pos_tmp
        end
        Point3f0[], pos_tmp
    end
    linepos = map(first, p_l_position)
    _view(visualize(
        linepos, :lines,
        prerender = ()->glDisable(GL_DEPTH_TEST), # draw over other items
        postrender = ()->glEnable(GL_DEPTH_TEST)
    ), GLPlot.viewing_screen(), camera = :perspective)
    point = map(last, p_l_position)
    _view(visualize(
        (Circle(Point2f0(0), 0.05f0), point),
        color = RGBA{Float32}(0.99, 0, 0.1),
        billboard = true,
        prerender=()-> glDisable(GL_DEPTH_TEST), # draw over other items
        postrender=()-> glEnable(GL_DEPTH_TEST)
    ), GLPlot.viewing_screen(), camera=:perspective)
    text = map(point) do pa
        p = pa[] # is an array
        _x = @sprintf("% 0.3f", p[1])
        _y = @sprintf("% 0.3f", p[2])
        _z = @sprintf("% 0.3f", p[3])
        "x:$_x,y:$_y,z: $_z"
    end
    vis = visualize(text, color=RGBA{Float32}(0.7,0.7,0.7))
    add_widget!(vis)
end

# Create sliders for the surface
a = GLPlot.play_widget(linspace(-4f0, 4f0, 50));
b = GLPlot.play_widget(linspace(1.5f0, 6f0, 50));
c = GLPlot.play_widget(linspace(-4f0, 4f0, 50));
# create surface and controle points/lines
init(100, a, b, c)
