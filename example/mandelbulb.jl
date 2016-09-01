using GLPlot, Reactive, GeometryTypes, Colors; GLPlot.init()

using CUDAnative, CUDAdrv
dev = CuDevice(0)
ctx = CuContext(dev)
function async_map2(f, init, inputs...; typ=typeof(init))
    node = Signal(typ, init, inputs)
    worker_task = @async init
    map(inputs...) do args...
        outer_task = current_task()
        hasworked = istaskdone(worker_task) #
        if istaskdone(worker_task) #
            worker_task = @async begin
                try
                    inner_worker = @async begin
                        x = f(args...)
                        push!(node, x)
                    end
                    while !istaskdone(inner_worker)
                        yield()
                    end
                catch err
                    Base.throwto(outer_task, CapturedException(err, catch_backtrace()))
                end
            end
        end
        worker_task
    end, node
end
@target ptx function mandel{T}(x0::T, y0::T, z0::T, n, iter)
    x,y,z = x0,y0,z0
    for i=1:iter
        r = CUDAnative.sqrt(x*x + y*y + z*z )
        theta = CUDAnative.atan2(CUDAnative.sqrt(x*x + y*y) , z)
        phi = CUDAnative.atan2(y,x)
        x1 = CUDAnative.pow(r, n) * CUDAnative.sin(theta*n) * CUDAnative.cos(phi*n) + x0
        y1 = CUDAnative.pow(r, n) * CUDAnative.sin(theta*n) * CUDAnative.sin(phi*n) + y0
        z1 = CUDAnative.pow(r, n) * CUDAnative.cos(theta*n) + z0
        (x1*x1 + y1*y1 + z1*z1) > n && return T(i)
        x,y,z = x1,y1,z1
    end
    T(iter)
end

@target ptx function mandelmap(a, xrange, yrange, zrange, n)
    i = (blockIdx().x-1) * blockDim().x + threadIdx().x
    @inbounds if i <= length(a)
        ix,iy,iz = ind2sub(size(a), i)
        a[i] = mandel(xrange[ix],yrange[iy],zrange[iz], Float32(n), 50)
    end
    return nothing
end
dims = (300,300,300)
d_arr = CuArray(Float32, dims);
len = prod(dims)
threads = min(len, 1024)
blocks = floor(Int, len/threads)
xrange, yrange, zrange = ntuple(i->linspace(-1f0, 1f0, dims[i]), 3)

const cu_vol = CuArray(Float32, dims);
nslider = GLPlot.play_widget(1:20);
const init = Array(cu_vol)
volume = async_map2(Array(cu_vol), nslider) do n
    @cuda (blocks,threads) mandelmap(cu_vol, xrange, yrange, zrange, Float32(n))
    copy!(init, cu_vol)
    init
end;

glplot(volume, color_norm = Vec2f0(0, 50))

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
isoval = GLPlot.play_widget(1:50);
particles = async_map2(iso_particle, Point3f0[], volume[2], isoval);
glplot((Sphere(Point2f0(0), 0.005f0), particles[2]), boundingbox=nothing)
glplot(volume[2])
