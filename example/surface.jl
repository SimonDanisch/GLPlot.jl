using GLPlot, GLAbstraction, ModernGL, GeometryTypes
n = 100
h = 1./n
r = h:h:1.
t = (-1:h:1+h)*π
x = map(Float32, r*cos(t)')
y = map(Float32, r*sin(t)')

f(x,y) = exp(-10x.^2-20y.^2)  # arbitrary function of f
z      = Float32[(f(x[k,j],y[k,j])) for k=1:size(x,1),j=1:size(x,2)]
obj    = glplot((x, y, z), :surface)
