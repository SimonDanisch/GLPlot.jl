using GLPlot; GLPlot.init()

@inline function mandel{T}(x0::T, y0::T, z0::T, n, iter)
    x,y,z = x0,y0,z0
    for i=1:iter
        r = sqrt(x*x + y*y + z*z )
        theta = atan2(sqrt(x*x + y*y) , z)
        phi = atan2(y,x)
        x1 = r^n * sin(theta*n) * cos(phi*n) + x0
        y1 = r^n * sin(theta*n) * sin(phi*n) + y0
        z1 = r^n * cos(theta*n) + z0
        (x1*x1 + y1*y1 + z1*z1) > n && return T(i)
        x,y,z = x1,y1,z1
    end
    T(iter)
end
using CUDAnative, CUDAdrv
dev = CuDevice(0)
ctx = CuContext(dev)

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

@target ptx function mandelmap(a, xrange, yrange, zrange)
    i = (blockIdx().x-1) * blockDim().x + threadIdx().x
    @inbounds if i <= length(a)
        ix,iy,iz = ind2sub(size(a), i)
        a[i] = mandel(xrange[ix],yrange[iy],zrange[iz], 8f0, 50)
    end
    return nothing
end
dims = (128,128,128)
d_arr = CuArray(Float32, dims);
len = prod(dims)
threads = min(len, 1024)
blocks = floor(Int, len/threads)
xrange, yrange, zrange = ntuple(i->linspace(-1f0, 1f0, dims[i]), 3)


const cu_vol = CuArray(Float32, dims)

nslider = GLPlot.play_widget(1:20)
volume = foldp(Array(cu_vol), nslider) do v0, n
    @cuda (blocks,threads) mandelmap(cu_vol, xrange, yrange, zrange)
    copy!(v0, cu_vol)
    v0
end

glplot(volume)
using Reactive, GLPlot; GLPlot.init()


# Install development version of Plots and GLPlot
Pkg.add("Plots"); Pkg.clone("GLPlot")
for p in ["GLPlot", "GLVisualize", "GeometryTypes", "GLPlot", "GLAbstraction", "GLWindow", "FixedSizeArrays"]
    Pkg.checkout(p)
end
