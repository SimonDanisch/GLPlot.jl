using GLPlot, GLAbstraction, ModernGL 


window = createdisplay(w=1000,h=1000,eyeposition=Vec3(1.,1.,1.), lookat=Vec3(0.,0.,0.));

function funcy(x,y,z)
    Vec3(0,1,1)
end

N = 20
directions  = Vec3[funcy(4x/N,4y/N,4z/N) for x=1:N,y=1:N, z=1:N]
obj         = glplot(directions)

renderloop(window)

