using GLPlot, GLAbstraction
f = frag"""
float function(float x) {
    return sin(x*x*x)*sin(x);
}
"""

glplot(f)