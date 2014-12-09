using GLPlot, GLAbstraction, ModernGL 


window = createdisplay(w=1000,h=1000,eyeposition=Vec3(1.,1.,1.), lookat=Vec3(0.,0.,0.));

function funcy(x,y,z)
    Vec3(sin(x), sin(y), sin(z))
end

N = 50
directions  = Vec3[funcy(x,y,z) for x=1:N,y=1:N, z=1:N]
obj         = glplot(directions)

renderloop(window)

