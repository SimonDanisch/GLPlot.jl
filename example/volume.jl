using GLPlot, GLVisualize, GLAbstraction, Colors, GeometryTypes, Plots, FileIO
using Reactive, GLWindow
GLPlot.init()
glvisualize()
# load a volume
vol = load(joinpath(homedir(), "Desktop", "brain.nii")).raw;
vol = vol ./ maximum(vol);

# plot it with blue colormap
p1 = plot(vol, fill=colormap("Blues", 7))

# prepare the slices
axes = ntuple(i-> linspace(0, 1, size(vol, i)), 3);
p2 = heatmap(vol[100, : , :], title="X Slice");
p3 = heatmap(vol[:, 100 , :], title="Y Slice", show=true);
p4 = heatmap(vol[:, : , 100], title="Z Slice");

plt = plot(p1, p2, p3, p4);

for i=1:3
    # since plots updating mechanism still doesn't work perfectly with GLVisualize
    # we need to get the raw visualization objects and gpu objects from the plots.
    # This will be exposed by a more straightforward API in the future!
    robj = plt[i+1].o.renderlist[1][end]
    tex = robj[:intensity] # image slice residing on the GPU
    range_s = play_widget(1:size(vol, i))
    preserve(map(range_s) do slice_idx
        idx = ntuple(d-> d==i ? slice_idx : (:), 3)
        # This conversion is necessary but will be automatic soon!
        slice = permutedims(map(Intensity{1, Float32}, vol[idx...]), (2,1))
        GLAbstraction.update!(tex, slice) # upload to memory
    end)
end
