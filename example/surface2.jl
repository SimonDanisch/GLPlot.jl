using GLAbstraction, GLPlot, Reactive

window = createdisplay(eyeposition=Vec3(4,4,3), w=1920, h=1280)

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

N         = 80
texdata   = [zdata(i/N, j/N, 15) for i=1:N, j=1:N]
color     = [zcolor(i/N, j/N, 15) for i=1:N, j=1:N] # Example on how to use react to change the color over time


obj = glplot(texdata, :zscale, primitive=CUBE(), color=color, xscale=0.05f0, yscale=0.05f0, xrange=(-4, 4), yrange=(-4, 4))

# You can look at surface.jl to find out how the primitives look like, and create your own.
# Also, it's pretty easy to extend the shader, which you can find under shader/instance_template.vert
# Its also planned, that you can just upload your own functions and uniforms, to further move computations to the shader.

# you can also update the texture which resides on the GPU.
# you fetch the texture like this:
const zscale = obj[:zscale]
const tcolor = obj[:color]
counter = 0.0f0
lift(fpswhen(window.inputs[:open], 30f0)) do x
	global counter
	# updating the texture works like this:
	zscale[1:end, 1:end] = [zdata(i/N, k/N, sin(counter/10)*15) for i=1:N, k=1:N]
	tcolor[1:end, 1:end] = [zcolor(i/N, k/N, (sin(counter)+1f0)*4) for i=1:N, k=1:N]
	counter += 0.07f0
end

renderloop(window)
