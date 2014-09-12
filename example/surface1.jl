using GLAbstraction, GLPlot, React

window = createdisplay()


function zdata(x1, y1, factor)
    x = (x1 - 0.5) * 15
    y = (y1 - 0.5) * 15
    R = sqrt(x^2 + y^2)
    Z = sin(R)/R
    Vec1(Z)
end
function zcolor(z)
    a = Vec4(0,1,0,1)
    b = Vec4(1,0,0,1)
    return mix(a,b,z[1]*5)
end

N         = 128
texdata   = [zdata(i/N, j/N, 5) for i=1:N, j=1:N]
colordata = map(zcolor , texdata)
color     = lift(x-> Vec4(sin(x), 0,1,1), Vec4, Timing.every(0.1)) # Example on how to use react to change the color over time

#color     = Texture(Pkg.dir()*"/GLPlot/docs/julia.png") # example for using an image for the color channel

obj       = glplot(texdata, primitive=CUBE(), color=color) # Color can be any matrix or a Vec3

renderloop(window)