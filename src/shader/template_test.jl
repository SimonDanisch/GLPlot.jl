using Mustache, ImmutableArrays, GLUtil, GLWindow, React


global const window = createwindow("Mesh Display", 1000, 1000, debugging = false)


const ZMAP_KEY_ARGUMENTS = Input([
	#:xrange 	=> 0:0.01:1, # Range{Real}) -> will be transformed to Float32
	#:yrange 	=> 0:0.01:1, # Range{Real}),
	:zposition		=> 0.0f0, 	 # GLNUMERICTYPES, Matrix{GLNUMERICTYPES}, Matrix{Vector1{GLNUMERICTYPES}})
							 # no x/yposition, as they are implicetely defined by the ranges
	:xscale			=> 0.01f0,  # GLNUMERICTYPES, Matrix{GLNUMERICTYPES}, Matrix{Vector1{GLNUMERICTYPES}})
	:yscale			=> 0.01f0,  # GLNUMERICTYPES, Matrix{GLNUMERICTYPES}, Matrix{Vector1{GLNUMERICTYPES}})
	:zscale			=> Texture(vec1[vec1(1) for i=1:10, j=1:10]),   # GLNUMERICTYPES, Matrix{GLNUMERICTYPES}, Matrix{Vector1{GLNUMERICTYPES}})
	:normal_vector	=> Texture(vec3[vec3(2) for i=1:10, j=1:10]),
	:color 			=> Vector4(0f0,0f0,0f0,1f0), #Vector1/3/4{GLNUMERICTYPES}, Matrix{GLNUMERICTYPES}, Matrix{Vector1/3/4{GLNUMERICTYPES}})
# actually, if you feel funky, you can simply hack your own attributes into the shader, and I might also add a few more later in the process

	#:primitive 	=> "SURFACE" # Possible are CUBE, POINT, any custom Mesh, 
])



function createview(x::Dict{Symbol, Any})
	view = (ASCIIString => ASCIIString)[]
	for (key,value) in x
		keystring = string(key)
		t = toglsl(value)
		view[keystring*"_type"] = t
		if isa(value, Texture{Float32, 1, 2})
			view[keystring*"_calculation"] = "texture($(keystring), xyz.xy / vec2(rangewidth(xrange), rangewidth(yrange))).r;"
		elseif isa(value, Texture{Float32, 3, 2})
			view[keystring*"_calculation"] = "texture($(keystring), xyz.xy / vec2(rangewidth(xrange), rangewidth(yrange))).rgb;"
		elseif isa(value, Texture{Float32, 4, 2})
			view[keystring*"_calculation"] = "texture($(keystring), xyz.xy / vec2(rangewidth(xrange), rangewidth(yrange)));"
		elseif isa(value, AbstractArray) || isa(value, Real)
			view[keystring*"_calculation"] = keystring *";"
		end
	end
	view
end



additional_attributes = Input([
	"GLSL_VERSION" 			=> get_glsl_version_string(),
	"GLSL_EXTENSIONS" 		=> "#extension GL_ARB_draw_instanced : enable",
	"instance_functions" 	=> readall(open("instance_functions.vert"))
])

view = lift(createview, ZMAP_KEY_ARGUMENTS)
view2 = lift(merge, view, additional_attributes)


vert = lift(x -> replace(render_from_file("instance_template.vert", x), "&#x2F;", "/"), view2)
lift(println, vert)

frag = lift(x -> render_from_file("phongblinn.frag", x), additional_attributes)

program = lift((vert, frag) -> GLProgram(vert, frag, "vert", "frag"), vert, frag)

ZMAP_KEY_ARGUMENTS2 = [
	:xrange 	=> 0:0.01:1, # Range{Real}) -> Real will be transformed to Float32
	:yrange 	=> 0:0.01:1, # Range{Real}),
	:zposition	=> 0.0f0, 	 # GLNUMERICTYPES, Matrix{GLNUMERICTYPES}, Matrix{Vector1{GLNUMERICTYPES}})
							 # no x/yposition, as they are implicetely defined by the ranges

	:xscale		=> 0.01f0,  # GLNUMERICTYPES, Matrix{GLNUMERICTYPES}, Matrix{Vector1{GLNUMERICTYPES}})
	:yscale		=> 0.01f0,  # GLNUMERICTYPES, Matrix{GLNUMERICTYPES}, Matrix{Vector1{GLNUMERICTYPES}})
	:zscale		=> Texture(vec1[vec1(1) for i=1:10, j=1:10]),   # GLNUMERICTYPES, Matrix{GLNUMERICTYPES}, Matrix{Vector1{GLNUMERICTYPES}})
	:color 		=> Texture(vec4[vec4(2) for i=1:10, j=1:10]), #Vector1/3/4{GLNUMERICTYPES}, Matrix{GLNUMERICTYPES}, Matrix{Vector1/3/4{GLNUMERICTYPES}})
# actually, if you feel funky, you can simply hack your own attributes into the shader, and I might also add a few more later in the process

	#:primitive 	=> "SURFACE" # Possible are CUBE, POINT, any custom Mesh, 
]
push!(ZMAP_KEY_ARGUMENTS, ZMAP_KEY_ARGUMENTS2)

test = Mustache.parse(readall(open("instance_template.vert"))) 
mustachekeys(mustache::Mustache.MustacheTokens) = map(x->x[2], filter(x-> x[1] == "name", mustache.tokens))


global const SURFACE = [
	:vertex 		=> vec3(0) # For surfaces the vertex is zero, as they are generated from the texture
    :offset         => GLBuffer(Float32[0,0, 0,1, 1,1, 1,0], 2), # Texture look up offset establishes basically a 4 neighbourhood, to draw a quad 
    				#the coordinates are grid coordinates, but can also be floating points, as the texture lookup uses biliniar interpolation
    :index          => indexbuffer(GLuint[0,1,2,2,3,0]),
	:normal_vector	=> Texture(vec3[vec3(2) for i=1:10, j=1:10])
]
const vertexes, uv, normals, indexes = gencubenormals(Vector3{Float32}(0,0,0), Vector3{Float32}(0.05, 0, 0), Vector3{Float32}(0, 0.05, 0), Vector3{Float32}(0,0,1))
global const CUBE = [
    :vertex        	=> GLBuffer(vertexes),
    :offset         => vec2(0), # For other geometry, the texture lookup offset is zero
    :index          => indexbuffer(indexes),
	:normal_vector	=> normals
]

environment = [
    :projection     => cam.projection,
    :view           => cam.view,
    :normalmatrix   => cam.normalmatrix,
    :light_position => Float32[20, 20, 20]
]
function checkandtransform(shaderattributes::Dict{Symbol, Any}, shaderkeys, templatekeys)
	resultshaderdict = (Symbol => Any)[]
	resulttemplateview = (String => Any)[]
	for (key, value) in shaderattributes
		if in(shaderkeys, key)
			if isa(value, Range)
				value = vec3(first(value), step(value), last(value))
				shaderattributes[key] = value
			elseif !isa(value, AbstractArray) || !isa(value, Real)
				error("not able to upload this value to video memory. Value: ", value)
			end
			if in(templatekeys, key)
				resulttemplateview[string(key)] = value
			end
			resultshaderdict[key] = value
		end
	end
	resultshaderdict, resulttemplateview
end
function gldipslay(x::Matrix{Float32}, primtive=SURFACE; keyargs...) = gldisplay(:zposition, x, primitive; keyargs...)


function gldipslay(key::symbol, x::Matrix{Float32}, primtive=SURFACE; keyargs...)

	result = merge(ZMAP_KEY_ARGUMENTS, keyargs, environment, primtive)
	result[key] = Texture(x, 1)
	template = Mustache.parse(readall(open("instance_template.vert"))) 
	templatekeys = mustachekeys(template)
	shaderkeys = 
	shaderdict, template = checkandtransform(result, shaderkeys, templatekeys)
end