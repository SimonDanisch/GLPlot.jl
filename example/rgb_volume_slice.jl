using GLPlot, GLVisualize, GLAbstraction, Colors, GeometryTypes, Plots, FileIO
using Reactive, GLWindow
import Quaternions: qrotation

# create a mandelbulb volume
N = 400
dims = (N, N, N)

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
        (x1 * x1 + y1 * y1 + z1 * z1) > n && return T(i)
        x, y, z = x1,y1,z1
    end
    T(iter)
end

x, y, z = ntuple(3) do i
    # linearly spaced array (not dense) from -1 to 1
    reshape(linspace(-1f0, 1f0, dims[i]), ntuple(j-> j == i ? dims[i] : 1, 3))
end
# change value for different results!
volume = mandelbulb.(x, y, z, 3f0, 22)
# create two sliders to interact with the 2 parameters of the mandelbulb function
maxi = maximum(volume)
const cmap = RGBA{Float32}.(colormap("RdBu", 100))
vol = map(volume) do level
    idx = floor(Int, ((level / maxi) * (length(cmap) - 1))) + 1
    cmap[idx]
end

# prepare the slices

slices = ntuple(3) do i
    range_s = play_widget(1:size(vol, i))
    slice = map(range_s) do j
        vol[ifelse(i == 1, j, :), ifelse(i == 2, j, :) , ifelse(i == 3, j, :)]
    end
    slice, range_s
end;

rotations = (
    Mat4f0(qrotation(unit(Vec3f0, 1), Float32(pi/2))),
    rotationmatrix_x(Float32(pi/2)) * Mat4f0(qrotation(unit(Vec3f0, 2), Float32(pi/2))),
    rotationmatrix_z(Float32(pi/2))
)
const ranges = (x, y, z)

plots = map(1:3) do i
    rot = rotations[i]
    slice, slider = slices[i]
    axis = unit(Vec3f0, 1)
    model = map(slider) do r
        trans = unit(Vec3f0, mod1(3-i, 3)) * ranges[i][r]
        translationmatrix(trans) * rot
    end
    rs = ranges[mod1(i + 1, 3)], ranges[mod1(i + 2, 3)]
    mini, maxi = extrema(ranges[i])
    glplot(
        slice,
        model = model,
        primitive = SimpleRectangle(-1, -1, 2, 2), # TODO, this is an inconsistency in the API and should also just accept ranges kw_arg
        preferred_camera = :perspective,
    )
end
