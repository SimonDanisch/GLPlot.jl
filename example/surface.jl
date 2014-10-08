using GLAbstraction, GLPlot, Reactive, ModernGL

window = createdisplay(w=1920, h=1280)
lift(println, window.inputs[:buttonspressed])

function zdata(x1, y1, factor)
    x = (x1 - 0.5) * 15
    y = (y1 - 0.5) * 15
    R = sqrt(x^2 + y^2) * factor
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

color     = Texture(Pkg.dir()*"/GLPlot/docs/julia.png")


#####################################################################################################################
# This is basically what the SURFACE() function returns.
# The coordinates are in grid coordinates, meaning +1 is the next cell on the grid


obj = glplot(texdata, primitive=CIRCLE(), color=color) # Color can also be a time varying value
#now you can animate the offset:
counter = 0f0
zgpu = obj[:z]
lift(fpswhen(window.inputs[:open], 30.0)) do x
    global counter
	zgpu[1:end, 1:end] = [zdata(i/N, j/N, sin(counter)*10f0) for i=1:N, j=1:N]
    counter += 0.01f0
end

renderloop(window)