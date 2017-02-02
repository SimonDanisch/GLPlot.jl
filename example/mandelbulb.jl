using Plots, GLPlot; GLPlot.init()
using Reactive, GeometryTypes, Colors, GLAbstraction

function mandelbulb{T}(x0::T,y0::T,z0::T, n, iter)
    x,y,z = x0,y0,z0
    for i=1:iter
        r = sqrt(x*x + y*y + z*z)
        theta = atan2(sqrt(x*x + y*y) , z)
        phi = atan2(y,x)
        rn = r^n
        x1 = rn * sin(theta*n) * cos(phi*n) + x0
        y1 = rn * sin(theta*n) * sin(phi*n) + y0
        z1 = rn * cos(theta*n) + z0
        (x1*x1 + y1*y1 + z1*z1) > n && return T(i)
        x,y,z = x1,y1,z1
    end
    T(iter)
end
dims = (50, 50, 50)

x, y, z = ntuple(3) do i
    # linearly spaced array (not dense) from -1 to 1
    reshape(linspace(-1f0, 1f0, dims[i]), ntuple(j-> j == i ? dims[i] : 1, 3))
end
volume = zeros(Float32, dims)
# create two sliders to interact with the 2 parameters of the mandelbulb function
itslider = GLPlot.play_widget(1:15)
nslider = GLPlot.play_widget(linspace(1f0, 30f0, 100))


# register a callback to the sliders with map ("map over updates")
mandelvol_s = map(nslider, itslider) do n, it
    volume .= mandelbulb.(x, y, z, n, it)
end


glplot(mandelvol_s, color_norm = Vec2f0(0, 50))

function iso_particle(v, isoval)
    particles = Point3f0[]
    sz = 1f0 ./ (Point3f0(size(v)) - 1f0)
    @inbounds for z = 1:size(v, 3), y = 1:size(v, 2), x = 1:size(v, 1)
        if v[x, y, z] ≈ isoval
            push!(particles, (Point3f0(x, y, z) - 1f0) .* sz)
        end
    end
    particles
end
using GLAbstraction, Meshing
isoval = GLPlot.play_widget(1:20)

task, particles = GLPlot.async_map2(iso_particle, Point3f0[], mandelvol_s, isoval)

# share buffer for colors
pp = GLBuffer(particles)
glplot((Sphere(Point2f0(0), 0.005f0), pp), color = pp)

mesh = map(mandelvol_s, isoval) do vol, iso
    mesh = GLNormalMesh(vol, Float32(iso))
    if isempty(vertices(mesh))
        return GLNormalMesh(HyperRectangle(Vec3f0(0), Vec3f0(1)))
    end
    bb = AABB(mesh.vertices)
    mini = minimum(bb)
    w = widths(bb)
    map!(mesh.vertices) do v
        (v - mini) ./ w
    end
    mesh
end
glplot(mesh)
