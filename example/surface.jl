using GLAbstraction, GLPlot, React, ModernGL

window = createdisplay()


function zdata(x1, y1, factor)
    x = (x1 - 0.5) * 15
    y = (y1 - 0.5) * 15
    R = sqrt(x^2 + y^2)
    Z = sin(R)/R
    Vec1(Z)
end
function zcolor(z)
    a = Vec4(0,1,0,1)
    b = Vec4(1,0,0,1)
    return mix(a,b,z[1]*5)
end

N         = 128
texdata   = [zdata(i/N, j/N, 5) for i=1:N, j=1:N]
colordata = map(zcolor , texdata)
color     = lift(x-> Vec4(sin(x), 0,1,1), Vec4, Timing.every(0.1)) # Example on how to use react to change the color over time

color     = Texture(Pkg.dir()*"/GLPlot/docs/julia.png")


#####################################################################################################################
# This is basically what the SURFACE() function returns.
# The coordinates are in grid coordinates, meaning +1 is the next cell on the grid


verts = Vec2[Vec2(0,0), Vec2(0,1), Vec2(1,1), Vec2(1,0)]
offset = GLBuffer(verts)
custom_surface = [
    :vertex         => Vec3(0),
    :offset         => offset,
    :index          => indexbuffer(GLuint[0,1,2,2,3,0]),
    :xscale         => 1f0,
    :yscale         => 1f0,
    :zscale         => 1f0,
    :z              => 0f0,
    :drawingmode    => GL_TRIANGLES
]

glplot(texdata, primitive=custom_surface, color=color) # Color can also be a time varying value
#now you can animate the offset:
lift(x-> begin
	update!(offset, verts + [Vec2(rand(-0.2f0:0.0001f0:0.2f0)) for i=1:4])
end, Timing.every(0.2))


renderloop(window)