using GLPlot, GLVisualize, GLAbstraction, Colors, GeometryTypes, FileIO
using Reactive, GLWindow, NIfTI
const If0 = GLVisualize.Intensity{1, Float32}
window = GLPlot.init()

layout = [
    ["Volume Plot", "Slice X"],
    ["Slice Y", "Slice Z"]
]

screens = GLVisualize.layoutscreens(window, layout)
function volume_data(N)
    vol = Float32[sin(x/15.0) + sin(y/15.0) + sin(z/15.0) for x=1:N, y=1:N, z=1:N]
    max = maximum(vol); min     = minimum(vol)
    vol = (vol .- min) ./ (max .- min)
end

vol = volume_data(128)


# to change color_map use the interactive edit menu or pass an array of color
# via color_map = Vector{Colorant}
p1 = glplot(vol, screen = screens[2][1])
slice_screens = vcat(screens[2][2], screens[1]...)
for i = 1:3
    range_s = play_widget(1:size(vol, i))
    slice = map(range_s) do slice_idx
        idx = ntuple(d-> d == i ? slice_idx : (:), Val{3})
        # This conversion is necessary but will be automatic soon!
        If0.(view(vol, idx...))
    end
    plot = glplot(
        slice, screen = slice_screens[i],
        color_norm = Vec2f0(0, 1),
        camera = :orthographic_pixel
    )
    center!(slice_screens[i], :orthographic_pixel)
end
