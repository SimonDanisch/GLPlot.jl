using Plots, GLPlot; GLPlot.init()
using GLPlot, Reactive, GeometryTypes, Colors
using CUDAnative, GPUArrays
import GPUArrays: GPUArray, GLBackend, CUBackend, cu_map
glctx = GLBackend.init(GLVisualize.current_screen())
cuctx = CUBackend.init()

const cu = CUDAnative

function mandelbulb{T}(x0::T,y0::T,z0::T, n, iter)
    x,y,z = x0,y0,z0
    for i=1:iter
        r = cu.sqrt(x*x + y*y + z*z)
        theta = cu.atan2(cu.sqrt(x*x + y*y) , z)
        phi = cu.atan2(y,x)
        rn = cu.pow(r, n)
        x1 = rn * cu.sin(theta*n) * cu.cos(phi*n) + x0
        y1 = rn * cu.sin(theta*n) * cu.sin(phi*n) + y0
        z1 = rn * cu.cos(theta*n) + z0
        (x1*x1 + y1*y1 + z1*z1) > n && return T(i)
        x,y,z = x1,y1,z1
    end
    T(iter)
end

dims = (300,300,300)
vol_gl = GPUArray(Float32, dims, context=glctx);
xrange, yrange, zrange = ntuple(3) do i
    r = linspace(-1f0, 1f0, dims[i]) # linearly spaced array (not dense) from -1 to 1
    rs = reshape(r, ntuple(j-> j!=i ? 1 : dims[i], 3)) # still not dense
    # convert it to a dense GPU Array (optional, but due to a bug in CUDA codegen, the view doesn't always work)
    GPUArray(rs, context=cuctx)
end
# create two sliders to interact with the 2 parameters of the mandelbulb function
itslider = GLPlot.play_widget(1:50);
nslider = GLPlot.play_widget(1f0:20f0);
using GLAbstraction
tex = GPUArray(Texture(Float32, dims), dims, context=glctx);
# register a callback to the sliders with map ("map over updates")
volume = preserve(map(nslider, itslider) do n, it
    # map to cuda memory space
    cu_map(vol_gl) do vol_cu
        vol_cu .= mandelbulb.(xrange, yrange, zrange, n, it)
    end
    unsafe_copy!(tex, vol_gl)
    nothing
end);

glplot(tex, color_norm = Vec2f0(0, 50))

function iso_particle(v, isoval)
    particles = Point3f0[]
    sz = 1f0./(Point3f0(size(v))-1f0)
    @inbounds for z=1:size(v, 3), y=1:size(v, 2), x=1:size(v, 1)
        if abs(v[x,y,z] - isoval) <= 0.001f0
            push!(particles, (Point3f0(x-1f0,y-1f0,z-1f0)).*sz)
        end
    end
    particles
end
using GLAbstraction, Meshing
isoval = GLPlot.play_widget(1:50);
particles = async_map2(iso_particle, Point3f0[], volume[2], isoval);
pp = GLBuffer(particles[2])
glplot((Sphere(Point2f0(0), 0.005f0),pp), boundingbox=nothing, color=pp)
mesh = GLNormalMesh(volume[2].value, 4f0)
map!(mesh.vertices) do v
    (v-1f0) ./ 298f0
end
glplot(mesh)

using GLAbstraction
compute_context =
