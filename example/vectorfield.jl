using GLPlot, GLAbstraction, ModernGL, GeometryTypes
GLPlot.init()

function funcy(x,y,z)
    Vec3f0
end

N = 10
r = linspace(0, 6, N)
directions = Vec3f0[(sin(x),cos(y),sin(z)) for x=r,y=r, z=r]
obj        = glplot(directions)
