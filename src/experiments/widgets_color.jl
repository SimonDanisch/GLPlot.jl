using ModernGL, GLAbstraction, GLWindow, GLFW, Reactive, ImmutableArrays, Images, GLText, Quaternions, Color, FixedPointNumbers, ApproxFun
using GLPlot

windowhints = [
  (GLFW.SAMPLES, 0), 
  (GLFW.DEPTH_BITS, 0), 
  (GLFW.ALPHA_BITS, 0), 
  (GLFW.STENCIL_BITS, 0),
  (GLFW.AUX_BUFFERS, 0)
]

window  = createdisplay(w=1920, h=1080, windowhints=windowhints)

mousepos = window.inputs[:mouseposition]

color_mousepos = lift(mousepos) do xy 
  if isinside(Rectangle(0f0,0f0,200f0,200f0), xy[1], xy[2])
    return Vec2(xy...)
  else
    Vec2(-1f0)
  end
end

mousepos_cam = lift(mousepos) do xy 
  if !isinside(Rectangle(0f0,0f0,200f0,200f0), xy[1], xy[2])
    return xy
  else
    Vector2(0.0)
  end
end
cam_inputs    = [
:mouseposition        => mousepos_cam,
:mousebuttonspressed  => window.inputs[:mousebuttonspressed],
:buttonspressed       => window.inputs[:buttonspressed],
:window_size          => window.inputs[:window_size],
:scroll_y             => window.inputs[:scroll_y]
]
color_inputs  = merge(window.inputs, [:mouseposition => color_mousepos, :scroll_y => Input(0f0), :scroll_x => Input(0f0)])

cam     = PerspectiveCamera(cam_inputs, Vec3(1,1,1), Vec3(0))
pcamera = OrthographicPixelCamera(color_inputs)

sourcedir = Pkg.dir("GLPlot", "src", "experiments")
shaderdir = sourcedir


include("glwidgets.jl")
parameters = [
        (GL_TEXTURE_WRAP_S,  GL_CLAMP_TO_EDGE),
        (GL_TEXTURE_WRAP_T,  GL_CLAMP_TO_EDGE ),

        (GL_TEXTURE_MIN_FILTER, GL_NEAREST),
        (GL_TEXTURE_MAG_FILTER, GL_NEAREST) 
]

fb = glGenFramebuffers()
glBindFramebuffer(GL_FRAMEBUFFER, fb)

framebuffsize = [window.inputs[:framebuffer_size].value]

color     = Texture(RGBA{Ufixed8},     framebuffsize, parameters=parameters)
stencil   = Texture(Vector2{GLushort}, framebuffsize, parameters=parameters)

glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, color.id, 0)
glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT1, GL_TEXTURE_2D, stencil.id, 0)

rboDepthStencil = GLuint[0]

glGenRenderbuffers(1, rboDepthStencil)
glBindRenderbuffer(GL_RENDERBUFFER, rboDepthStencil[1])
glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24, framebuffsize...)
glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, rboDepthStencil[1])

lift(window.inputs[:framebuffer_size]) do window_size
  resize!(color, window_size)
  resize!(stencil, window_size)
  glBindRenderbuffer(GL_RENDERBUFFER, rboDepthStencil[1])
  glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24, window_size...)
end
rgba(r::Real, g::Real, b::Real, a::Real) = AlphaColorValue(RGB{Float32}(r,g,b), float32(a))

selectiondata = Input(Vector2{GLushort}[Vector2{GLushort}(0,0)])

immutable Style{StyleValue}
end
Style(x::Symbol) = Style{x}()
mergedefault!{S}(style::Style{S}, styles, customdata) = merge!(Dict{Symbol, Any}(customdata), styles[S])


begin 
local color_chooser_shader = TemplateProgram(joinpath(shaderdir, "colorchooser.vert"), joinpath(shaderdir, "colorchooser.frag"), 
  fragdatalocation=[(0, "fragment_color"),(1, "fragment_groupid")])
verts, uv, normals, indexes = genquad(Vec3(0, 0, 0), Vec3(200, 0, 0), Vec3(0, 200, 0))

local data = [

:vertex                   => GLBuffer(verts),
:uv                       => GLBuffer(uv),
:index                    => indexbuffer(indexes),

:middle                   => Vec2(0.5),
:color                    => Vec4(0,1,0,1),

:swatchsize               => 0.1f0,
:border_color             => Vec4(1, 1, 0.99, 1),
:border_size              => 0.01f0,

:hover                    => Input(false),
:hue_saturation           => Input(false),
:brightness_transparency  => Input(false),

:antialiasing_value       => 0.01f0,
]

#GLPlot.toopengl{T <: AbstractRGB}(colorinput::Input{T}) = toopengl(lift(x->AlphaColorValue(x, one(T)), RGBA{T}, colorinput))
tohsv(rgba)     = AlphaColorValue(convert(HSV, rgba.c), rgba.alpha)
torgb(hsva)     = AlphaColorValue(convert(RGB, hsva.c), hsva.alpha)
tohsv(h,s,v,a)  = AlphaColorValue(HSV(float32(h), float32(s), float32(v)), float32(a))

function GLPlot.toopengl{X <: AbstractAlphaColorValue}(colorinput::Signal{X}; camera=pcamera)

  data[:view]       = camera.view
  data[:projection] = camera.projection
  data[:model]      = eye(Mat4)

  obj = RenderObject(data, color_chooser_shader)
  obj[:postrender, render] = (obj.vertexarray,) # Render the vertexarray
  obj[:prerender, glDisablei] = (GL_BLEND, 1) # Render the vertexarray
  obj[:prerender, glEnablei] = (GL_BLEND, 0) # Render the vertexarray
  obj[:prerender, glBlendFunc] = (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA) # Render the vertexarray

  color = colorinput.value

  # hover is true, if mouse 
  hover = lift(selectiondata) do selection
    selection[1][1] == obj.id
  end

  all_signals = foldl((tohsv(color), false, false, Vec2(0)), selectiondata) do v0, selection

    hsv, hue_sat0, bright_trans0, mouse0 = v0
    mouse           = window.inputs[:mouseposition].value
    mouse_clicked   = window.inputs[:mousebuttonspressed].value

    hue_sat = in(0, mouse_clicked) && selection[1][1] == obj.id
    bright_trans = in(1, mouse_clicked) && selection[1][1] == obj.id
    

    if hue_sat && hue_sat0
      diff = mouse - mouse0
      hue = mod(hsv.c.h + diff[1], 360)
      sat = max(min(hsv.c.s + (diff[2] / 30.0), 1.0), 0.0)

      return (tohsv(hue, sat, hsv.c.v, hsv.alpha), hue_sat, bright_trans, mouse)
    elseif hue_sat && !hue_sat0
      return (hsv, hue_sat, bright_trans, mouse)
    end

    if bright_trans && bright_trans0
      diff    = mouse - mouse0
      brightness  = max(min(hsv.c.v - (diff[2]/100.0), 1.0), 0.0)
      alpha     = max(min(hsv.alpha + (diff[1]/100.0), 1.0), 0.0)

      return (tohsv(hsv.c.h, hsv.c.s, brightness, alpha), hue_sat0, bright_trans, mouse)
    elseif bright_trans && !bright_trans0
      return (hsv, hue_sat0, bright_trans, mouse)
    end

    return (hsv, hue_sat, bright_trans, mouse)
  end
  color1 = lift(x -> torgb(x[1]), all_signals)
  hue_saturation = lift(x -> x[2], all_signals)
  brightness_transparency = lift(x -> x[3], all_signals)


  obj.uniforms[:color]                    = color1
  obj.uniforms[:hover]                    = hover
  obj.uniforms[:hue_saturation]           = hue_saturation
  obj.uniforms[:brightness_transparency]  = brightness_transparency

  return obj, color1
end

end # local begin color chooser



const h = 0.01
const u0 = TensorFun((x,y)->exp(-10x.^2-20(y-.1).^2))
const d = Interval()⊗Interval()
const L = I-h^2*lap(d)
const B = [ neumann(Interval())⊗I;
I⊗dirichlet(Interval())]
const S = schurfact([B,L],100)
const u = Array(TensorFun,10000)
u[1] = u0
u[2] = u0
n = 2
 
 
const xx =-1.:.02:1.
const yy = xx
 
const N = length(xx)
vals = evaluate(u[1],xx,yy)
vals = [
zeros(1,N+2);
zeros(N) vals zeros(N);
zeros(1,N+2)]
 
plotdata = map(Vec1,vals)


colorobj, colorlol = toopengl(Input(rgba(1,0,0,1)))
 
obj = glplot(plotdata, primitive=SURFACE(), color=colorlol, camera=cam)
 
 
# this is probably a little opaque, but plotdata ends up in :z, as :z is the default attribute for the data you upload
zvalues = obj.uniforms[:z]
# Like this you get a reference to the gpu memory object (a texture in this case)
 
m = 1000
counter = 2
 



glClearColor(1,1,1,1)
const mousehover = Array(Vector2{GLushort}, 1)
lift(x-> glViewport(0,0,x...), window.inputs[:framebuffer_size])
function renderloop()
  glBindFramebuffer(GL_FRAMEBUFFER, fb)
  glDrawBuffers(2, [GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1])
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
  render(obj)
  render(colorobj)

  mousex, mousey = int([color_mousepos.value])
  if (mousex > 0 && mousey > 0)
    glReadBuffer(GL_COLOR_ATTACHMENT1) 
    glReadPixels(mousex, mousey, 1,1, stencil.format, stencil.pixeltype, mousehover)
    @async push!(selectiondata, mousehover)
  end

  glReadBuffer(GL_COLOR_ATTACHMENT0)
  glBindFramebuffer(GL_READ_FRAMEBUFFER, fb)
  glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0)
  glClear(GL_COLOR_BUFFER_BIT)

  window_size = window.inputs[:framebuffer_size].value
  glBlitFramebuffer(0,0, window_size..., 0,0, window_size..., GL_COLOR_BUFFER_BIT, GL_NEAREST)
  global counter, u, xx,yy, zvalues,n,m

  counter += 1
  k = mod1(counter, length(u))
  u[k] = (S\[zeros(4),2u[k-1]-u[k-2]])
  vals = evaluate(u[k],xx,yy)
  vals = [vals[:,1] vals vals[:,end]];
  vals = [vals[1,:]; vals; vals[end,:]]
  zvalues[1:end, 1:end] = map(Vec1,vals)
end



while !GLFW.WindowShouldClose(window.glfwWindow)
  yield() # this is needed for react to work
  renderloop()
  yield()

  GLFW.SwapBuffers(window.glfwWindow)
  GLFW.PollEvents()
end
GLFW.Terminate()
