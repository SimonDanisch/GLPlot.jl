using GLPlot;GLPlot.init()
using Plots;glvisualize()
using GLVisualize, FileIO, Colors, Images

imfolder = joinpath(homedir(), "Desktop", "animal_imgs")
images = map(readdir(imfolder)) do impath
    map(RGBA{U8}, restrict(load(joinpath(imfolder, impath)))).data
end;
filter!(x->size(x)==size(first(images)), images)
mean_colors = map(images) do img
    mean(img)
end
x = map(comp1, mean_colors); y=map(comp2, mean_colors); z=map(comp3, mean_colors);
p1=scatter(
    x,y,z, markercolor=mean_colors,
    shape=:circle, markerstrokewidth=1, markerstrokecolor="white",
    hover=images, ms=12
)
p2=scatter(x,y,z, markerstrokecolor=mean_colors, shape=images, ms=15)
plot(p1, p2)


using Plots;glvisualize()
using GLVisualize, FileIO, Colors, Images
using GeometryTypes, GLAbstraction

x = ["(｡◕‿◕｡)", "◔ ⌣ ◔","(づ｡◕‿‿◕｡)づ", "┬──┬ ノ( ゜-゜ノ)", "(╯°□°）╯︵ ┻━┻", "¯\\_(ツ)_/¯"]
y = [-4, -3, -2, -1, 6, 0]
scatter(x, y)
t = bounce(linspace(-1.0f0,1f0, 20))
translation = map(t) do t
    rotationmatrix_y(1f0)*rotationmatrix_z(deg2rad(90f0)) * translationmatrix(Vec3f0(3,3,t))
end
hover = [
    "Plotting\nsomething!",
    "Something\nscientific?",
    "For once?",
    visualize(loadasset("cat.obj"), model=translation),
    "Noo! That\ncat again!",
    "😸$(Char(0x1F63B))",
]
scatter(x, y, m=(0.8, :diamond, 20), hover=hover)

title!("ℕ ⊆ ℕ₀ ⊂ ℤ ⊂ 2H₂ + O₂ ⇌ 2H₂O")
xaxis!(" ⠍⠊⠣ ახლავე გაიაროთ все вещи, вы можете построить")
yaxis!("Anger")
