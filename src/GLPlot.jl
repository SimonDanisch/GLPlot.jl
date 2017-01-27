__precompile__(true)
module GLPlot


using GLVisualize, GLWindow, ModernGL, Reactive, GLAbstraction, Colors
using FixedPointNumbers, FreeType, SignedDistanceFields, Images, Packing
using GeometryTypes, GLFW, FileIO, FixedSizeArrays, Quaternions

import GLVisualize: toggle_button, toggle, button
import GLVisualize: mm, extract_edit_menu

# Some not officially supported file formats from FileIO
# FileIO.load(file::File{format"Julia"}) = include(filename(file))
# function __init__()
#     add_format(format"Julia", (), ".jl")
# end

function imload(name)
    rotl90(Matrix{BGRA{U8}}(load(Pkg.dir("GLPlot", "src", "icons", name))))
end



include("gui.jl")
export play_control
include("plot.jl")
export glplot
export register_plot!
include("screen.jl")
export register_compute


end
