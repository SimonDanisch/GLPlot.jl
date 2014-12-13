immutable Mesh{Attributes}
    data::Dict{Symbol, Any}
end
immutable Triangle{T <: AbstractFixedVector{3}}
    v1::T
    v2::T
    v3::T
end

immutable TextureCoordinate2{T} <: AbstractFixedVector{2}
    u::T
    v::T
end
immutable Normal3{T} <: AbstractFixedVector{3}
    x::T
    y::T
    z::T
end

immutable Material

function Mesh(data...)
    result = (Symbol => DataType)[]
    meshattributes = (Symbol => Any)[]
    for elem in data
        keyname                 = symbol(lowercase(replace(string(eltype(elem).name), r"\d", "")))
        result[keyname]         = eltype(elem)
        meshattributes[keyname] = elem
    end
    #sorting of parameters... Solution a little ugly for my taste
    result = sort(map(x->x, result))
    Mesh{tuple(map(x->x[2],result)...)}(meshattributes)
end
Base.getindex(m::Mesh, key::Symbol) = m.data[key]
function Base.show(io::IO, m::Mesh)
    println(io, "Mesh:")
    maxnamelength = 0
    maxtypelength = 0
    names = map(m.data) do x
        n = string(x[1])
        t = string(eltype(x[2]).parameters...)
        namelength = length(n)
        typelength = length(t)
        maxnamelength = maxnamelength < namelength ? namelength : maxnamelength
        maxtypelength = maxtypelength < typelength ? typelength : maxtypelength

        return (n, t, length(x[2]))
    end

    for elem in names
        kname, tname, alength = elem
        namespaces = maxnamelength - length(kname)
        typespaces = maxtypelength - length(tname)
        println(io, "   ", kname, " "^namespaces, " : ", tname, " "^typespaces, ", length: ", alength)
    end
end