using GLAbstraction, GLPlot, Reactive
GLPlot.init()
text = "whatup internet!?\n#Crusont"

glplot(text, color = [RGBA(rand(), rand(), 0,1) for i=1:length(text)]) # You can either, supply a texture with colors
