using Base.Test
using GLPlot, GLAbstraction

window = createdisplay()

glplot(Vec1[Vec1(sin(i)*sin(j) / 4f0) for i=0:0.1:10, j=0:0.1:10])
glplot(Texture(Vec4[Vec4(sin(i), sin(j), cos(i), sin(j)*cos(i)) for i=1:0.1:12, j=1:0.1:12]))
N = 128
volume = Float32[sin(x / 12f0)+sin(y / 12f0)+sin(z / 12f0) for x=1:N, y=1:N, z=1:N]
glplot(volume)

renderloop(window)

