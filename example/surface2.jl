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
color     = lift(x-> Vec4(sin(x), 0,1,1), Vec4, Timing.every(0.1)) # Example on how to use react to change the color over time


obj = glplot(texdata, :zscale, primitive=CUBE(), color=color, xscale=0.001f0, yscale=texdata)

# You can look at surface.jl to find out how the primitives look like, and create your own.
# Also, it's pretty easy to extend the shader, which you can find under shader/instance_template.vert
# Its also planned, that you can just upload your own functions and uniforms, to further move computations to the shader.

# you can also simply update the texture, even though it's not nicely exposed by the API yet.

zscale = obj.uniforms[:zscale]
lift(x-> begin
	update!(zscale, texdata + [Vec1((sin(x) +cos(i))/4.0) for i=1:N, k=1:N])
end, Timing.every(0.1))

renderloop(window)
