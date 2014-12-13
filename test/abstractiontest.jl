# Dictionary for DataTypes as a key, which retrieves key which are subtypes of abstract types
immutable TypeDict
    data::Dict{(DataType...,), Any}
end
isabstractsubtype(a::Int, b::Int) = a==b
function isabstractsubtype(type1::(DataType...,), type2::(DataType...,))
    length(type1) != length(type2) && return false
    issubtype(type1, type2) && return true
    for (a,b) in zip(type1, type2)
        maintypea = eval(symbol(string(a.name)))
        maintypeb = eval(symbol(string(b.name)))
        !issubtype(maintypea, maintypeb) && return false
        paramsa = a.parameters
        paramsb = a.parameters
        all(isabstractsubtype, zip(paramsa, paramsb)) && return true
    end
end

function Base.get(x::TypeDict, key::(DataType...,), default)
    haskey(x.data, key) && return x.data[key]
    for (k, v) in x.data
        isabstractsubtype(key, k) && return v
    end
    return default
end
Base.keys(x::TypeDict) = keys(x.data)
function Base.getindex(x::TypeDict, key::(DataType...,))
    get(x, key, "key not found in TypeDict. Key: ")
end



const VIZ_DEFAULT = TypeDict(Dict(
    (Int32, Int64) => Dict(
        :lol => 10,
        :lol2 => 2333,
    ),
    (Int32, Array{Union(Real, AbstractArray)}) => Dict(
        :trol => 10,
        :google => "2333",
    )
))

const VIZ_HELP = TypeDict(Dict(
    (Int32, Int64) => """
    trolololol
    hahaha
    lolp
    """
))
_visualize(kw::Dict{Symbol, Any}, ::Int32, ::Int64) = println(kw)
_visualize(kw::Dict{Symbol, Any}, ::Int32, ::Array{Float32}) = println("wurnl")


visualize(args...; kw...) = call_with_help(_visualize, args, kw, VIZ_DEFAULT)


visualize_help(args...) = visualize_help(args)
visualize_help(args::Tuple) = visualize_help(map(typeof, args))
function visualize_help{N}(args::NTuple{N, DataType})
    println(get(VIZ_HELP, args, "No function for visualize"))
end


visualizekeywords(args...) = visualizekeywords(args)
visualizekeywords(args::Tuple) = visualizekeywords(map(typeof, args))
function visualizekeywords{N}(args::NTuple{N, DataType})
    kw = get(VIZ_DEFAULT, args, "No keywords for visualize")
    kwstring = reduce("", kw) do v0, kv
        v0*"$(kv[1]) = $(kv[2])\n"
    end
    println(kwstring)
end
function call_with_help(func::Function, args::Tuple, keywords::Array{Any,1}, defaultkwords)
    types = map(typeof, args)
    if method_exists(func, tuple(Dict{Symbol, Any}, types...))
        kwords = copy(get(defaultkwords, types," öpö"))
        merge!(kwords, Dict{Symbol, Any}(keywords))
        return func(Dict{Symbol, Any}(kwords), args...)
    else
        funcname = symbol(string(func)[2:end])
        argstring = reduce("", keys(defaultkwords)) do v0, kv
        v0*"$kv\n"
        end
        m = """$funcname doesn't have a method for the given arguments: $types.
            Try $(funcname)_help(your, types, or, values) for a help text
            or keywords(function, your, types, or, values) for the available keywords
            Available arguments for $funcname:
            $argstring
            """
            error(m)
    end
end
test(a...) = (types = map(typeof, a); VIZ_DEFAULT[types])
@show(test(int32(0), Vector{Float32}[[1f0,1f0]]))
visualizekeywords(int32(0), 0)
visualize_help(int32(0), 0)