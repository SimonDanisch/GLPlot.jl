using Plots, GLPlot
using GLVisualize, FileIO, Colors, Images
using GeometryTypes, GLAbstraction
w = GLPlot.init()
glvisualize(size = widths(w))
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
    visualize(loadasset("cat.obj"), model = translation),
    "Noo! That\ncat again!",
    "😸$(Char(0x1F63B))",
]
scatter(x, y, m=(0.8, :diamond, 20), hover=hover)

title!("ℕ ⊆ ℕ₀ ⊂ ℤ ⊂ 2H₂ + O₂ ⇌ 2H₂O")
xaxis!(" ⠍⠊⠣ ახლავე გაიაროთ все вещи, вы можете построить")
yaxis!("Anger")
gui()
