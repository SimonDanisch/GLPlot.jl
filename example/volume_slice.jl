using GLPlot, GLVisualize, GLAbstraction, Colors, GeometryTypes, Plots, FileIO
using Reactive, GLWindow
import Quaternions: qrotation

GLPlot.init()
# load a volume
vol = load(joinpath(homedir(), "Desktop", "brain.nii")).raw;
vol = vol ./ maximum(vol);

# prepare the slices
ranges = ntuple(i-> linspace(-2f0, 2f0, size(vol, i)), 3)
slices = ntuple(3) do i
    range_s = play_widget(1:size(vol, i))
    slice = map(range_s) do j
        s = vol[ifelse(i == 1, j, :), ifelse(i == 2, j, :) , ifelse(i == 3, j, :)]
        reinterpret(Intensity{1, Float32}, s)
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
        ranges = rs,
        preferred_camera = :perspective,
        stroke_width = 0.001f0,
        stroke_color = RGBA{Float32}(0,0,0,0.4),
        color_norm = Vec2f0(0, 1)
    )
end
