using GLAbstraction, GLPlot, Reactive, Colors
GLPlot.init()

function zdata(i, j, t)
    x         = (i - 0.5)
    z         = (j - 0.5)
    radius    = sqrt((x * x) + (z * z))

    r = sin(10.0f0 * radius + t)
    Float32(r + rand(1.0:0.01:1.1))
end
function zcolor(i, j, t)
    x         = (i - 0.5)
    z         = (j - 0.5)
    radius     = sqrt((x * x) + (z * z))

    r = sin(10.0f0 * radius + t)
    g = cos(10.0f0 * radius + t)
    b = radius
    return RGBA{Float32}(r, g, b, 1)
end
t = GLPlot.play_widget(linspace(1, 50, 200))
N = 128
surf = map(t-> [zdata(i/N, j/N, t) for i = 1:N, j = 1:N], t)
color = map(t-> [zcolor(i/N, j/N, t) for i = 1:N, j = 1:N], t)
xr = linspace(-4, 4, N)
obj = glplot(
    surf, :surface, color = color, ranges = (xr, xr)
)
