using GLAbstraction, GLPlot, Reactive
using Meshes

window = createdisplay(w=1920, h=1280)



N = 50
const vol = Float32[sin(x/15f0)+sin(y/15f0)+sin(z/15f0) for x=1:N, y=1:N, z=1:N]
const msh = Meshes.isosurface(vol, 0.5f0, 0.001f0)

glplot(msh)

renderloop(window)