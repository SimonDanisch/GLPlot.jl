using GLAbstraction, GLPlot, Reactive, ModernGL, ImmutableArrays, GLFW
window  = createdisplay(w=800, h=800, windowhints=[(GLFW.SAMPLES, 0)])


v, uvw, indexes = gencube(1f0, 1f0, 1f0)

N       = 128
volume  = Float32[sin(x / 12f0)+sin(y / 12f0)+sin(z / 12f0) for x=1:N, y=1:N, z=1:N]
max     = maximum(volume)
min     = minimum(volume)
volume  = Texture(reinterpret(Vec1, (volume .- min) ./ (max .- min), size(volume)))


function stranspose(mat)
    return Matrix4x4(
        Vector4( mat.c1[1], mat.c2[1], mat.c3[1], mat.c4[1] ),
        Vector4( mat.c1[2], mat.c2[2], mat.c3[2], mat.c4[2] ),
        Vector4( mat.c1[3], mat.c2[3], mat.c3[3], mat.c4[3] ),
        Vector4( mat.c1[4], mat.c2[4], mat.c3[4], mat.c4[4] )
    )
end

function viewmatrix{T}(position::Vector3{T}, view)
  a = Vec4(position..., one(T))
  b = stranspose(view) * a
  return Vec3(b[1:3]...)
end

lookatvec   = Vec3(0.5)
eyeposvec   = Vec3(0, 1.5, 1.5)
up          = Vec3(0,1,0)

view        = lookat(eyeposvec, lookatvec, up)
fov         = 0.7f0
projection  = perspectiveprojection(rad2deg(fov), 1f0, 1f0, 100f0)
focallength = 1.0f0 / tan(fov / 2f0)
rayorigin   = viewmatrix(eyeposvec, view)

println(rayorigin)
data = [
#Vertex Shader Data
  :vertex         => GLBuffer(v, 3),
  :indexes        => indexbuffer(indexes),
  :projection     => projection,

#Frag Shader Data
  :Density      => volume,
  :view         => view,
  :Modelview    => view,

  :FocalLength  => focallength,
  :WindowSize   => Vec2(window.inputs[:window_size].value[3:4]...),
  :RayOrigin    => rayorigin,

  :LightPosition  => Vec3(0.25, 1.0, 3.0),
  :LightIntensity => Vec3(15.0),
  :Absorption     => 1.0f0,
  :Ambient => Vec3(0.15, 0.15, 0.20)
]
shader  = TemplateProgram(joinpath(GLPlot.shaderdir, "volume.vert"), joinpath(GLPlot.shaderdir, "volume.frag"))

obj     = RenderObject(data, shader)

obj[:postrender, render] = (obj.vertexarray,)

obj[:prerender, glDisable]    = (GL_DEPTH_TEST,)
obj[:prerender, glEnable]     = (GL_BLEND,)
obj[:prerender, glEnable]     = (GL_CULL_FACE,)
obj[:prerender, glBlendFunc]  = (GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA)

glplot(obj)

renderloop(window)
