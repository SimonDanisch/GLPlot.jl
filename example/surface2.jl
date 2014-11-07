using GLAbstraction, GLPlot, Reactive

window = createdisplay(eyeposition=Vec3(4,4,3), w=1000, h=800)

function zdata(i, j, t)
    x 		= float32(i - 0.5)
	z 		= float32(j - 0.5)
	radius 	= sqrt((x * x) + (z * z))

	r = sin(10.0f0 * radius + t)
    Vec1(r + rand(1.0:0.01:1.1))
end
function zcolor(i, j, t)
	x 		= float32(i - 0.5)
	z 		= float32(j - 0.5)
	radius 	= sqrt((x * x) + (z * z))

	r = sin(10.0f0 * radius + t)
    g = cos(10.0f0 * radius + t)
    b = radius
    return Vec4(r,g,b, 1)
end

N         = 128
texdata   = [zdata(i/N, j/N, 15) for i=1:N, j=1:N]
color     = [zcolor(i/N, j/N, 15) for i=1:N, j=1:N] # Example on how to use react to change the color over time


obj = glplot(texdata, :zscale, primitive=CUBE(), color=color, xscale=0.05f0, yscale=0.05f0, xrange=(-4, 4), yrange=(-4, 4))

# You can look at surface.jl to find out how the primitives look like, and create your own.
# Also, it's pretty easy to extend the shader, which you can find under shader/instance_template.vert
# Its also planned, that you can just upload your own functions and uniforms, to further move computations to the shader.

# you can also simply update the texture, even though it's not nicely exposed by the API yet.

zscale = obj[:zscale]
tcolor = obj[:color]


lift(x-> begin
	update!(zscale, [zdata(i/N, k/N, sin(x/10)*15) for i=1:N, k=1:N])
	update!(tcolor, [zcolor(i/N, k/N, (sin(x)+1f0)*4) for i=1:N, k=1:N])
end, every(0.01))

renderloop(window)
