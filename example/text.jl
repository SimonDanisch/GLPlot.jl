using GLAbstraction, GLPlot, Reactive
using ImmutableArrays

typealias Vec1 Vector1{Float64}
typealias Vec2 Vector2{Float64}
typealias Vec3 Vector3{Float64}
typealias Vec4 Vector4{Float64}

GLPlot.init()
# window = createdisplay(h=1000,w=1500, eyeposition=Vec3(2,0,0))
text = "whatup internet!?\n#Crusont"

glplot(text, scale=Vec2(1/50, 1/50), color=Vec4[Vec4(rand(), rand(), 0,1) for i=1:length(text)]) # You can either, supply a texture with colors
#glplot(text, scale=Vec2(1/50), color=Vec4(0,1,0,1)) # or just supply one color
#full api:
#=
gplot(text::AbstractString;
					start=Vec3(0), scale=Vec2(1/500), color=Vec4(0,0,1,1), backgroundcolor=Vec4(0),
					lineheight=Vec3(0,0,0), advance=Vec3(0,0,0), rotation=Quaternion(1f0,0f0,0f0,0f0), textrotation=Quaternion(1f0,0f0,0f0,0f0),
					camera=pcamera
				)
=#
# For all attributes you can either supply values per glyph with a texture, or a scalar value for the whole text.


renderloop(window)
