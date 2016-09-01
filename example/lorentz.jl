using GeometryTypes, Reactive, GLVisualize
using GLPlot;GLPlot.init()

function async_map2(f, init, inputs...; typ=typeof(init))
    node = Signal(typ, init, inputs)
    worker_task = @async init
    map(inputs...) do args...
        outer_task = current_task()
        hasworked = istaskdone(worker_task) #
        if istaskdone(worker_task) #
            worker_task = @async begin
                try
                    inner_worker = @async begin
                        @time x = f(args...)
                        push!(node, x)
                    end
                    while !istaskdone(inner_worker)
                        yield()
                    end
                catch err
                    Base.throwto(outer_task, CapturedException(err, catch_backtrace()))
                end
            end
        end
        worker_task
    end, node
end

slidera = GLPlot.play_widget(linspace(0.1f0, 40f0, 30))
sliderb = GLPlot.play_widget(linspace(0.1f0, 40f0, 30))
sliderc = GLPlot.play_widget(linspace(0.1f0, 40f0, 30))
sliderd = GLPlot.play_widget(linspace(0.1f0, 40f0, 30))

function lorentz(v0, a, b, c, d)
    Point2f0(
        sin(a * v0[2]) - cos(b * v0[1]),
        sin(c * v0[1]) - cos(d * v0[1])
    )
end
function lorentz3d(v0, a, b, c, h)
    Point3f0(
        v0[1] + h * a * (v0[2] - v0[1]),
        v0[2] + h * (v0[1] * (b - v0[3]) - v0[2]),
        v0[3] + h * (v0[1] * v0[2] - c * v0[3]),
    )
end
function lorentz_map(array, a,b,c,d)
    v0 = first(array)
    for i=eachindex(array)
        v0 = lorentz3d(v0, a,b,c,d)
        @inbounds array[i] = v0
    end
    array
end
const tmp2 = zeros(Point3f0, 10000)
function lol(a,b,c,d)
    fill!(tmp2, Point3f0(0.1, 0,0))
    lorentz_map(tmp2, a,b,c,d)
end
points = map(lol, slidera, sliderb, sliderc, sliderd)
glplot((Circle(Point2f0(0), 0.01f0), points), boundingbox=nothing, preferred_camera=:perspective)
glplot(points, :lines, boundingbox=nothing, preferred_camera=:perspective)
