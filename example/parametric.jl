using GLPlot, GLAbstraction
GLPlot.init()

f = """
float function(float x) {
    return sin(x*x*x) * sin(x);
}
"""

glplot(f, :shader)
