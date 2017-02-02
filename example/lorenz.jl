using GeometryTypes, Reactive, GLVisualize
using GLPlot


"""
Lorenz function
"""
function lorenz(t0, a, b, c, h)
    Point3f0(
        t0[1] + h * a * (t0[2] - t0[1]),
        t0[2] + h * (t0[1] * (b - t0[3]) - t0[2]),
        t0[3] + h * (t0[1] * t0[2] - c * t0[3]),
    )
end
# step through the `time`
function lorenz(array::Vector, a=5.0,b=2.0,c=6.0,d=0.01)
    t0 = Point3f0(0.1, 0, 0)
    for i=eachindex(array)
        t0 = lorenz(t0, a,b,c,d)
        array[i] = t0
    end
    array
end

# create sliders to interact with the parameters of the lorenz function
slidera = GLPlot.play_widget(linspace(0.1f0, 40f0, 30))
sliderb = GLPlot.play_widget(linspace(0.1f0, 40f0, 30))
sliderc = GLPlot.play_widget(linspace(0.1f0, 40f0, 30))
sliderd = GLPlot.play_widget(linspace(0.001f0, 0.5f0, 30))


# N time steps
n = 10_000
# foldp registers a callback (in this case lorenz), which updates the points
# whenever the slider changes.
points = foldp(lorenz, Array(Point3f0, n), slidera, sliderb, sliderc, sliderd)
# we set the boundingbox to nothing, since we don't need it and don't want to
# calculate it for every update (which is the default)
glplot(points, :lines, preferred_camera = :perspective)
# you can also visualize the points
glplot(
    (Circle(Point2f0(0), 0.01f0), points),
    preferred_camera = :perspective
)
# the above renders an antia aliased nice looking circle which could have outlines and glows.
# this makes it relatively slow. For optimal performance, one might need the command below
# which draws one (or n) pixel per point
#glplot(points, :speed, boundingbox=nothing, preferred_camera=:perspective)
