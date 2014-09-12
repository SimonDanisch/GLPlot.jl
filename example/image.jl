using GLPlot, GLAbstraction

window = createdisplay()

##########################################################
# Image

# Using ImmutableArrays for colors (Vec4 --> Vector4{Float32):
a = Texture(Vec4[Vec4(i/512,j/512,0,1)for i=1:512, j=1:512])
# Without ImmutableArays, the color dimension is not known and you need to supply it
b = Texture(Float32[(i*j)/512^2 for i=1:512, j=1:512], 1) 
c = Texture("../docs/julia.png")

# default usage will just bring the texture on your screen with zooming and panning enabled:
glplot(c)
# these are the keyword arguments:
# ; camera = OrthographicCamera(window.inputs), normrange=Vec2(0,1), kernel=1f0, filternorm=1f0)
# The kernel should be a Matrix{Float32} or Matrix{Vec1}. 
# Matrix{Vec2/3/4} is currently not supported, but quite easy to implement
# normrange normalizes the values from normrange[1] to normrange[2] to 0->1

renderloop(window)


