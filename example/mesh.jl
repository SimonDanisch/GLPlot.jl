using GLAbstraction, GLPlot, Reactive
using Meshes

window = createdisplay(w=1920, h=1280)

N = 10
sigma = 1.0
distance = Float32[ sqrt(float32(i*i+j*j+k*k)) for i = -N:N, j = -N:N, k = -N:N ]
distance = distance + sigma*rand(2*N+1,2*N+1,2*N+1)

# Extract an isosurface.
#
lambda = N-2*sigma # isovalue

msh = isosurface(distance,lambda)


glplot(msh)

renderloop(window)