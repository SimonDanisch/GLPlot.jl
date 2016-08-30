using GeometryTypes, Colors

function loop{T}(point::T, radius, imax, i=1, points=Point3f0[], scales=Vec3f0[])
    i == imax && return points, scales
    push!(points, point);push!(scales, radius)
    for point in decompose(T, Sphere(point, radius), 4)
        loop(point, radius/2, imax, i+1, points, scales)
    end
    points, scales
end
const cmap2 = map(RGBA{Float32}, colormap("RdBu", 3))
function loop2{T}(point::T, normal, radius, imax, mesh=loadasset("cat.obj"), i=1, points=Point3f0[], scales=Vec3f0[], rotations=Vec3f0[], colors=RGBA{Float32}[])
    i > imax && return points, scales, rotations, colors
    push!(points, point);push!(scales, radius);push!(rotations, normal);push!(colors, cmap2[i])
    for (point, normal) in zip(decompose(T, mesh), decompose(Normal{3, Float32}, mesh))
        loop2(point, normal, radius/10f0, imax, mesh, i+1, points, scales, rotations, colors)
    end
    points, scales, rotations, colors
end
using GLVisualize
p, s, r, c = loop2(Point3f0(0), Normal{3,Float32}(0,0,1), 1f0, 3, loadasset("cat.obj"));


@code_warntype loop2(Point3f0(0), Normal{3,Float32}(0,0,1), 1f0, 3, loadasset("cat.obj"),
    Point3f0[], Vec3f0[], Vec3f0[], RGBA{Float32}[]
)


using GLPlot;GLPlot.init()
glplot((loadasset("cat.obj"), p), scale=s, rotation=r, color=c)
c
