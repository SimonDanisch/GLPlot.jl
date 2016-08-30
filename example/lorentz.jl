using GeometryTypes

v0 = Point2f0(0)

const a = 2.01
const b = -2.53
const c = 1.61
const d = -0.33
x = zeros(Point2f0, 10_1000)
for i=1:10_1000
    v0 = Point2f0(
        sin(a * v0[2]) - cos(b * v0[1]),
        sin(c * v0[1]) - cos(d * v0[1])
    )
    x[i] = v0
end
using GLPlot;GLPlot.init()
glplot((Circle(Point2f0(0), 0.1f0), x), preferred_camera=:perspective)
glplot(x, :lines, preferred_camera=:perspective)
