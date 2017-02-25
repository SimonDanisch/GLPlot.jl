using GLPlot, GLVisualize, GLAbstraction, Colors, GeometryTypes, FileIO
using Reactive, GLWindow, NIfTI
window = GLPlot.init()

layout = [
    ["Volume Plot", "Slice X"],
    ["Slice Y", "Slice Z"]
]

screens = GLVisualize.layoutscreens(window, layout)
vol = niread(joinpath(homedir(), "Desktop", "brain.nii")).raw;
vol = vol ./ maximum(vol)
const If0 = GLVisualize.Intensity{1, Float32}

# to change color_map use the interactive edit menu or pass an array of color
# via color_map = Vector{Colorant}
p1 = glplot(vol, screen = screens[2][1])
slice_screens = vcat(screens[2][2], screens[1]...)
for i = 1:3
    range_s = play_widget(1:size(vol, i))
    slice = map(range_s) do slice_idx
        idx = ntuple(d-> d == i ? slice_idx : (:), 3)
        # This conversion is necessary but will be automatic soon!
        permutedims(If0.(view(vol, idx...)), (2, 1))
    end
    plot = glplot(slice, screen = slice_screens[i], camera = :orthographic_pixel)
    center!(slice_screens[i],:orthographic_pixel)
end
