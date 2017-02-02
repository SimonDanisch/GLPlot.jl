__precompile__(true)
module GLPlot

# GLVisualize Packages
using GLVisualize, GLWindow, GeometryTypes, GLAbstraction, GLFW

# dependencies
using Reactive, Colors, FixedPointNumbers, Images, FileIO

import GLVisualize: toggle_button, toggle, button
import GLVisualize: mm, extract_edit_menu, IRect, N0f8

# Some not officially supported file formats from FileIO
# FileIO.load(file::File{format"Julia"}) = include(filename(file))
# function __init__()
#     add_format(format"Julia", (), ".jl")
# end

function imload(name)
    im = load(joinpath(dirname(@__FILE__), "icons", name))
    convert(Matrix{BGRA{N0f8}}, im)
end


include("gui.jl")
export play_control

include("plot.jl")
export glplot
export register_plot!

include("screen.jl")
export register_compute

end
