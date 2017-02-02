using GLPlot; GLPlot.init()
using Plots; glvisualize()
using GLVisualize, FileIO, Colors, Images

imfolder = filter(readdir(GLVisualize.assetpath())) do path
    endswith(path, "jpg") || endswith(path, "png")
end
images = map(imfolder) do impath
    convert(Matrix{RGBA{N0f8}}, restrict(loadasset(impath)))
end;

mean_colors = map(mean, images)
x = map(comp1, mean_colors); y = map(comp2, mean_colors); z = map(comp3, mean_colors);
p1 = scatter(
    x,y,z, markercolor=mean_colors,
    shape = :circle, markerstrokewidth = 1, markerstrokecolor = "white",
    hover = images, ms = 12
)
p2 = scatter(x,y,z, markerstrokecolor = mean_colors, shape = images, ms = 15)
plot(p1, p2)
gui()
