using FixedPointNumbers, Color 

RGBAU8 = AlphaColorValue{RGB{Ufixed8}, Ufixed8}
Color.rgba(r::Real, g::Real, b::Real, a::Real) = AlphaColorValue(RGB{Float32}(r,g,b), float32(a))
rgbaU8(r::Real, g::Real, b::Real, a::Real)     = AlphaColorValue(RGB{Ufixed8}(ufixed8(r),ufixed8(g),ufixed8(b)), ufixed8(a))

#GLPlot.toopengl{T <: AbstractRGB}(colorinput::Input{T}) = toopengl(lift(x->AlphaColorValue(x, one(T)), RGBA{T}, colorinput))
tohsva(rgba)     = AlphaColorValue(convert(HSV, rgba.c), rgba.alpha)
torgba(hsva)     = AlphaColorValue(convert(RGB, hsva.c), hsva.alpha)
tohsva(h,s,v,a)  = AlphaColorValue(HSV(float32(h), float32(s), float32(v)), float32(a))


begin
local glsl_attributes = @compat Dict(
  "instance_functions"  => readall(open(shaderdir*"/instance_functions.vert")),
  "GLSL_EXTENSIONS"     => "#extension GL_ARB_draw_instanced : enable"
)

local const cubez = gencubenormals(Vec3(0), Vec3(0.001, 0, 0), Vec3(0,0.001, 0), Vec3(0,0,0.01))

local const parameters = [
    (GL_TEXTURE_MIN_FILTER, GL_NEAREST),
    (GL_TEXTURE_MAG_FILTER, GL_NEAREST),
    (GL_TEXTURE_WRAP_S,  GL_CLAMP_TO_EDGE),
    (GL_TEXTURE_WRAP_T,  GL_CLAMP_TO_EDGE),
    (GL_TEXTURE_WRAP_R,  GL_CLAMP_TO_EDGE),
  ]
function toopengl(
            vectorfield::Array{Vector3{Float32}, 3}; 
            primitive=CUBE(), xrange=(-1,1), yrange=(-1,1), zrange=(-1,1), colorrange=(-1,1),
            lightposition=Vec3(20, 20, -20), camera=pcamera, colormap=RGBAU8[rgbaU8(1,0,0,1), rgbaU8(1,1,0,1), rgbaU8(0,1,0,1)], rest...)

  data = merge(@compat(Dict(
    :vectorfield    => Texture(vectorfield, parameters=parameters),

    :cube_from      => Vec3(first(xrange), first(yrange), first(zrange)),
    :cube_to        => Vec3(last(xrange),  last(yrange),  last(zrange)),
    :color_range    => Vec2(first(colorrange), last(colorrange)),
    :colormap       => Texture(colormap),
    :projection     => camera.projection,
    :view           => camera.view,
    :normalmatrix   => camera.normalmatrix,
    :light_position => lightposition,
    :modelmatrix    => eye(Mat4),
    :vertex         => GLBuffer(cubez[1]),
    :index          => indexbuffer(cubez[4]),
    :normal_vector  => GLBuffer(cubez[3]),
  )), Dict{Symbol, Any}(rest), primitive)
  # Depending on what the primitivie is, additional values have to be calculated
  program = TemplateProgram(shaderdir*"vectorfield.vert", shaderdir*"phongblinn.frag", view=glsl_attributes, attributes=data)
  obj     = instancedobject(data, length(vectorfield), program, GL_TRIANGLES)
  prerender!(obj, glEnable, GL_DEPTH_TEST, glDepthFunc, GL_LEQUAL, glDisable, GL_CULL_FACE, enabletransparency)
  obj
end
end