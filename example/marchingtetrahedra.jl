using ImmutableArrays
using GLPlot, GLAbstraction, ModernGL

immutable Face{T}
  v1::T
  v2::T
  v3::T
end
typealias IType GLuint
typealias Vertex Vector3{Float32}
#
# *** Marching Tetrahedra ***
#
# Marching Tetrahedra is an algorithm for extracting a triangular
# mesh representation of an isosurface of a scalar volumetric
# function sampled on a rectangular grid.
#
# We divide the cube into six tetrahedra. [It is possible to divide
# a cube into five tetrahedra, but not in a way that a translated
# version of the division would share face diagonals. (It reqires a
# reflection.)]
#
# Voxel corner and edge indexing conventions
#
#        Z
#        |
#  
#        5------5------6              Extra edges not drawn
#       /|            /|              -----------
#      8 |           6 |              - face diagonals
#     /  9          /  10                - 13: 1 to 3
#    8------7------7   |                 - 14: 1 to 8
#    |   |         |   |                 - 15: 1 to 6
#    |   1------1--|---2  -- Y           - 16: 5 to 7
#    12 /          11 /                  - 17: 2 to 7
#    | 4           | 2                   - 18: 4 to 7
#    |/            |/                 - body diagonal
#    4------3------3                     - 19: 1 to 7
#
#  /
# X

# (X,Y,Z)-coordinates for each voxel corner ID
const voxCrnrPos = convert(Array{(IType, IType, IType), 1}, [(0, 0, 0),
                    (0, 1, 0),
                    (1, 1, 0),
                    (1, 0, 0),
                    (0, 0, 1),
                    (0, 1, 1),
                    (1, 1, 1),
                    (1, 0, 1)])
# the voxel IDs at either end of the tetrahedra edges, by edge ID
const voxEdgeCrnrs = convert(Array{(IType, IType), 1}, [(1, 2),
                      (2, 3),
                      (4, 3),
                      (1, 4),
                      (5, 6),
                      (6, 7),
                      (8, 7),
                      (5, 8),
                      (1, 5),
                      (2, 6),
                      (3, 7),
                      (4, 8),
                      (1, 3),
                      (1, 8),
                      (1, 6),
                      (5, 7),
                      (2, 7),
                      (4, 7),
                      (1, 7)])


# direction codes:
# 0 => +x, 1 => +y, 2 => +z, 
# 3 => +xy, 4 => +xz, 5 => +yz, 6 => +xyz
const voxEdgeDir = IType[1,0,1,0,1,0,1,0,2,2,2,2,3,4,5,3,4,5,6]

# For a pair of corner IDs, the edge ID joining them
# 0 denotes a pair with no edge
const voxEdgeIx = convert(Array{IType, 2}, [[ 0  1 13  4  9 15 19 14],
                   [ 1  0  2  0  0 10 17  0],
                   [13  2  0  3  0  0 11  0],
                   [ 4  0  3  0  0  0 18 12],
                   [ 9  0  0  0  0  5 16  8],
                   [15 10  0  0  5  0  6  0],
                   [19 17 11 18 16  6  0  7],
                   [14  0  0 12  8  0  7  0]])

# voxel corners that comprise each of the six tetrahedra
const subTets = convert(Array{IType, 2}, [[1 3 2 7],
                 [1 8 4 7],
                 [1 4 3 7],
                 [1 2 6 7],
                 [1 5 8 7],
                 [1 6 5 7]]')
# tetrahedron corners for each edge (indices 1-4)
const tetEdgeCrnrs = convert(Array{IType, 2}, [[1 2],
                      [2 3],
                      [1 3],
                      [1 4],
                      [2 4],
                      [3 4]]')

# triangle cases for a given tetrahedron edge code
const tetTri = convert(Array{IType, 2}, [[0 0 0 0 0 0],
                [1 3 4 0 0 0],
                [1 5 2 0 0 0],
                [3 5 2 3 4 5],
                [2 6 3 0 0 0],
                [1 6 4 1 2 6],
                [1 5 6 1 6 3],
                [4 5 6 0 0 0],
                [4 6 5 0 0 0],
                [1 6 5 1 3 6],
                [1 4 6 1 6 2],
                [2 3 6 0 0 0],
                [3 2 5 3 5 4],
                [1 2 5 0 0 0],
                [1 4 3 0 0 0],
                [0 0 0 0 0 0]]')

# Checks if a voxel has faces. Should be false for most voxels.
# This function should be made as fast as possible.
function hasFaces{T<:Real}(vals::Vector{T}, iso::T)
    if vals[1] < iso
        @inbounds for i = 2:8
            if vals[i] >= iso
                return true
            end
        end
    else
        @inbounds for i = 2:8
            if vals[i] < iso
                return true
            end
        end
    end 
    false
end

# Determines which case in the triangle table we are dealing with
function tetIx{T<:Real}(tIx::IType, vals::Vector{T}, iso::T)
    ifelse(vals[subTets[1,tIx]] < iso, 1, 0) +
    ifelse(vals[subTets[2,tIx]] < iso, 2, 0) +
    ifelse(vals[subTets[3,tIx]] < iso, 4, 0) +
    ifelse(vals[subTets[4,tIx]] < iso, 8, 0) + 1
end

# Determines a unique integer ID associated with the edge. This is used
# as a key in the vertex dictionary. It needs to be both unambiguous (no
# two edges get the same index) and unique (every edge gets the same ID
# regardless of which of its neighboring voxels is asking for it) in order
# for vertex sharing to be implemented properly.
function vertId(e::IType, x::IType, y::IType, z::IType,
                nx::IType, ny::IType)
    dx = voxCrnrPos[voxEdgeCrnrs[e][1]]
    voxEdgeDir[e]+7*(x-1+dx[1]+nx*(y-1+dx[2]+ny*(z-1+dx[3])))
end

# Assuming an edge crossing, determines the point in space at which it
# occurs.
# eps represents the "bump" factor to keep vertices away from voxel
# corners (thereby preventing degeneracies).
function vertPos{T<:Real}(e::IType, x::IType, y::IType, z::IType,
                          vals::Vector{T}, iso::T, eps::T)
    ixs = voxEdgeCrnrs[e]
    srcVal = float(vals[ixs[1]])
    tgtVal = float(vals[ixs[2]])
    a = (float(iso)-srcVal)/(tgtVal-srcVal)
    a = min(max(a,float(eps)),1.0-eps)
    b = 1.0-a
    corner1 = voxCrnrPos[ixs[1]]
    corner2 = voxCrnrPos[ixs[2]]
    Vertex(x+b*corner1[1]+a*corner2[1],
           y+b*corner1[2]+a*corner2[2],
           z+b*corner1[3]+a*corner2[3])
end

# Gets the vertex ID, adding it to the vertex dictionary if not already
# present.
function getVertId{T<:Real}(e::IType, x::IType, y::IType, z::IType,
                            nx::IType, ny::IType,
                            vals::Vector{T}, iso::T,
                            vts::Dict{IType,Vertex},
                            eps::T)
    vId = vertId(e,x,y,z,nx,ny)
    if !haskey(vts,vId)
        vts[vId] = vertPos(e,x,y,z,vals,iso,eps)
    end
    vId
end

# Given a sub-tetrahedron case and a tetrahedron edge ID, determines the
# corresponding voxel edge ID.
function voxEdgeId(subTetIx::IType, tetEdgeIx::IType)
    srcVoxCrnr = subTets[tetEdgeCrnrs[1,tetEdgeIx],subTetIx]
    tgtVoxCrnr = subTets[tetEdgeCrnrs[2,tetEdgeIx],subTetIx]
    voxEdgeIx[srcVoxCrnr,tgtVoxCrnr]
end

# Processes a voxel, adding any new vertices and faces to the given
# containers as necessary.
function procVox{T<:Real}(vals::Vector{T}, iso::T,
                          x::IType, y::IType, z::IType,
                          nx::IType, ny::IType,
                          vts::Dict{IType,Vertex}, fcs::Vector{Face{IType}},
                          eps::T)

    # check each sub-tetrahedron in the voxel
    @inbounds for i::IType = 1:6
        tIx = tetIx(i,vals,iso)

        @inbounds for j::IType in 1:3:4
            e1 = tetTri[j,tIx]
            e2 = tetTri[j+1,tIx]
            e3 = tetTri[j+2,tIx]

            # bail if there are no more faces
            if e1 == 0 break end

            # add the face to the list
            fc = Face{IType}(getVertId(voxEdgeId(i,e1),x,y,z,nx,ny,vals,iso,vts,eps),
                      getVertId(voxEdgeId(i,e2),x,y,z,nx,ny,vals,iso,vts,eps),
                      getVertId(voxEdgeId(i,e3),x,y,z,nx,ny,vals,iso,vts,eps))
            push!(fcs, fc)
        end
    end
end

# Given a 3D array and an isovalue, extracts a mesh represention of the 
# an approximate isosurface by the method of marching tetrahedra.
function marchingTetrahedra{T<:Real}(lsf::AbstractArray{T,3},iso::T,eps::T)
    vts = Dict{IType,Vertex}()
    fcs = Array(Face{IType}, 0)

    # process each voxel
    (nx::IType,ny::IType,nz::IType) = size(lsf)
    vals = zeros(T, 8)
    @inbounds for k::IType = 1:nz-1, j::IType = 1:ny-1, i::IType = 1:nx-1
        for l=1:8
          vals[l] = lsf[i+voxCrnrPos[l][1],j+voxCrnrPos[l][2],k+voxCrnrPos[l][3]]
        end
        if hasFaces(vals,iso)
            procVox(vals,iso,i,j,k,nx,ny,vts,fcs,eps)
        end
    end

    (vts,fcs)
end

function isosurface(lsf,isoval,eps, index_start=zero(IType))
    # get marching tetrahedra version of the mesh
    (vts,fcs) = marchingTetrahedra(lsf,isoval,eps)

    # normalize the mesh representation
    vtD = Dict{IType,IType}()
    k = index_start
    for x in keys(vts)
        vtD[x] = k
        k += one(IType)
    end
    fcAry = Face{IType}[Face{IType}(vtD[f.v1],vtD[f.v2],vtD[f.v3]) for f in fcs]
    vtAry = collect(values(vts))

    vtAry,fcAry
end

isosurface(lsf,isoval) = isosurface(lsf,isoval, convert(eltype(lsf), 0.001))

N1 = 10
N = 400
volume1  = Float32[sin(x/15f0)+sin(y/15f0)+sin(z/15f0) for x=1:N1, y=1:N1, z=1:N1]
volume  = Float32[sin(x/15f0)+sin(y/15f0)+sin(z/15f0) for x=1:N, y=1:N, z=1:N]

@time isosurface(volume1, 0.5f0, 0.001f0)
@time isosurface(volume, 0.5f0, 0.001f0)
