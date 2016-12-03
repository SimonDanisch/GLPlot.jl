__precompile__(true)
module GLPlot


using GLVisualize, GLWindow, ModernGL, Reactive, GLAbstraction, Colors
using FixedPointNumbers, FreeType, SignedDistanceFields, Images, Packing
using GeometryTypes, GLFW, FileIO, FixedSizeArrays, Quaternions
import GLVisualize: toggle_button, toggle, button
import Plots
import NIfTI
import GLVisualize: mm, extract_edit_menu

# Some not officially supported file formats from FileIO
FileIO.load(file::File{format"Julia"}) = include(filename(file))
FileIO.load(file::File{format"NIfTI"}) = NIfTI.niread(filename(file))
function GLVisualize.visualize(v::NIfTI.NIfTI.NIVolume, style::Symbol=:default; kw_args...)
    visualize(v.raw, style; kw_args...)
end

function imload(name)
    rotl90(Matrix{BGRA{U8}}(load(Pkg.dir("GLPlot", "src", "icons", name))))
end

function __init__()
    add_format(format"Julia", (), ".jl")
    add_format(format"NIfTI", (), ".nii")
end


include("editing.jl")
include("gui.jl")
export play_control
include("plot.jl")
export glplot
export register_plot!
include("screen.jl")
export register_compute


#include("glp_userimg.jl")

end
