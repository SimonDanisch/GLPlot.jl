using GLPlot, GLAbstraction
GLPlot.init()
import GLAbstraction: @frage_str

f = frag"""
float function(float x) {
    return sin(x*x*x)*sin(x);
}
"""

glplot(f)
