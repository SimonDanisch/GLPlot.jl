using GLPlot, GLAbstraction, GeometryTypes, FileIO, GLVisualize, Colors
##########################################################
# Image

a = [RGBA{N0f8}(i/512,j/512,0,1)for i=1:512, j=1:512]
# Without ImmutableArays, the color dimension is not known and you need to supply it
b = [Gray{Float32}((i*j)/512^2) for i=1:512, j=1:512]
c = loadasset("racoon.png")
d = loadasset("kitty.png")
layout!(SimpleRectangle(0f0, 0f0, 100f0, 100f0), glplot(a))
layout!(SimpleRectangle(0f0, 100f0, 100f0, 100f0), glplot(b))
layout!(SimpleRectangle(100f0, 0f0, 100f0, 100f0), glplot(c))
layout!(SimpleRectangle(100f0, 100f0, 100f0, 100f0), glplot(d))
