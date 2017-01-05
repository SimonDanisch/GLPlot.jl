using GLPlot, GLVisualize, GLAbstraction, Colors, GeometryTypes, Plots, FileIO
using Reactive, GLWindow
import Quaternions: qrotation

GLPlot.init()
# load a volume
N = 100
ranges = ntuple(i-> linspace(-2f0, 2f0, N), 3)
xr = ranges[1]
vol = map(((x, y, z) for x=xr, y=xr, z=xr)) do xyz
    RGBA(sin(xyz[1]), cos(xyz[2]), sqrt(1 + sin(xyz[3])*cos(xyz[3])))
end

# prepare the slices

slices = ntuple(3) do i
    range_s = play_widget(1:size(vol, i))
    slice = map(range_s) do j
        vol[ifelse(i == 1, j, :), ifelse(i == 2, j, :) , ifelse(i == 3, j, :)]
    end
    slice, range_s
end

rotations = (
    Mat4f0(qrotation(unit(Vec3f0, 1), Float32(pi/2))),
    rotationmatrix_x(Float32(pi/2)) * Mat4f0(qrotation(unit(Vec3f0, 2), Float32(pi/2))),
    rotationmatrix_z(Float32(pi/2))
)

plots = map(1:3) do i
    rot = rotations[i]
    slice, slider = slices[i]
    axis = unit(Vec3f0, 1)
    model = map(slider) do r
        trans = unit(Vec3f0, mod1(3-i, 3)) * ranges[i][r]
        translationmatrix(trans) * rot
    end
    rs = ranges[mod1(i + 1, 3)], ranges[mod1(i + 2, 3)]
    glplot(
        slice,
        model = model,
        primitive = SimpleRectangle(-2, -2, 4, 4), # TODO, this is an inconsistency in the API and should also just accept ranges kw_arg
        preferred_camera = :perspective,
    )
end
