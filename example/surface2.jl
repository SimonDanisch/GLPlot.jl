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

N         = 128
texdata   = [zdata(i/N, j/N, 15) for i=1:N, j=1:N]
color     = [zcolor(i/N, j/N, 15) for i=1:N, j=1:N] # Example on how to use react to change the color over time


obj = glplot(texdata, :surface, color = color)
