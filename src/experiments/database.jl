using ModernGL, GLAbstraction, GLWindow, GLFW, Reactive, ImmutableArrays, Images, GLText, Quaternions, Color, FixedPointNumbers, ApproxFun
using GLPlot, HTTPClient


immutable Style{StyleValue}
end

window  = createdisplay(w=1920, h=1080, windowhints=[
  (GLFW.SAMPLES, 0), 
  (GLFW.DEPTH_BITS, 0), 
  (GLFW.ALPHA_BITS, 0), 
  (GLFW.STENCIL_BITS, 0),
  (GLFW.AUX_BUFFERS, 0)
])

mousepos = window.inputs[:mouseposition]
pcamera   = OrthographicPixelCamera(window.inputs)

sourcedir = Pkg.dir("GLPlot", "src", "experiments")
shaderdir = sourcedir

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


function Base.setindex!{T <: AbstractFixedVector, ElType}(a::Vector{T}, x::ElType, i::Integer, accessor::Integer)
  @assert eltype(T) == ElType # ugly workaround for not having triangular dispatch
  @assert length(a) >= i
  cardinality = length(T)
  @assert accessor <= cardinality
  ptr = convert(Ptr{ElType}, pointer(a))
  unsafe_store!(ptr, x, ((i-1)*cardinality)+accessor)
end
function Base.setindex!{T <: AbstractFixedVector, ElType}(a::Vector{T}, x::Vector{ElType}, i::Integer, accessor::UnitRange)
  @assert eltype(T) == ElType
  @assert length(a) >= i
  cardinality = length(T)
  @assert length(accessor) <= cardinality
  ptr = convert(Ptr{ElType}, pointer(a))
  unsafe_copy!(ptr + (sizeof(ElType)*((i-1)*cardinality)), pointer(x), length(accessor))
end
function Base.setindex!{T <: AbstractFixedVector, ElType, CDim}(a::Texture{T, CDim, 1}, x::ElType, i::Integer, accessor::Integer)
  a.data[i, accessor] = x
  a[i] = a.data[i]
end
function Base.setindex!{T <: AbstractFixedVector, ElType, CDim}(a::Texture{T, CDim, 1}, x::Vector{ElType}, i::Integer, accessor::UnitRange)
  a.data[i, accessor] = x
  a[i] = a.data[i]
end


function setindex1D!{T <: AbstractFixedVector, ElType}(a::Matrix{T}, x::ElType, i::Integer, accessor::Integer)
  @assert eltype(T) == ElType
  @assert length(a) >= i
  cardinality = length(T)
  @assert length(accessor) <= cardinality

  ptr = convert(Ptr{T}, pointer(a))
  unsafe_store!(ptr, x, ((i-1)*cardinality)+accessor)
end
function setindex1D!{T <: AbstractFixedVector, ElType}(a::Matrix{T}, x::Vector{ElType}, i::Integer, accessor::UnitRange)
  @assert eltype(T) == ElType
  @assert length(a) >= i
  cardinality = length(T)
  @assert length(accessor) <= cardinality

  ptr = convert(Ptr{T}, pointer(a))
  unsafe_copy!(ptr + (sizeof(T)*((i-1)*cardinality)), pointer(x), length(accessor))
end


function setindex1D!{T <: AbstractFixedVector, ElType, CDim}(a::Texture{GLGlyph{T}, CDim, 2}, x::T, i::Integer, accessor::Integer)
  a.data[i, accessor] = x
  a[i] = a.data[i]
end
function setindex1D!{T <: AbstractFixedVector, ElType, CDim}(a::Texture{GLGlyph{T}, CDim, 2}, x::Vector{T}, i::Integer, accessor::UnitRange)
  a.data[i, accessor] = x
  a[i] = a.data[i]
end







lift(x-> glViewport(0,0,x...), window.inputs[:framebuffer_size])
function renderloop()
end

selectiondata = Input(Vector2(0))
const mousehover = Vector2{GLushort}[Vector2{GLushort}(0,0)]

glClearColor(39.0/255.0, 40.0/255.0, 34.0/255.0, 1.0)

while !GLFW.WindowShouldClose(window.glfwWindow)
  yield() # this is needed for react to work
  glBindFramebuffer(GL_FRAMEBUFFER, fb)
  glDrawBuffers(2, [GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1])
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
  renderloop()

  mousex, mousey = int([window.inputs[:mouseposition].value])
  glReadBuffer(GL_COLOR_ATTACHMENT1) 
  glReadPixels(mousex, mousey, 1,1, stencil.format, stencil.pixeltype, mousehover)
  push!(selectiondata, convert(Vector2{Int}, mousehover[1]))


  glReadBuffer(GL_COLOR_ATTACHMENT0)
  glBindFramebuffer(GL_READ_FRAMEBUFFER, fb)
  glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0)
  glClear(GL_COLOR_BUFFER_BIT)

  window_size = window.inputs[:framebuffer_size].value
  glBlitFramebuffer(0,0, window_size..., 0,0, window_size..., GL_COLOR_BUFFER_BIT, GL_NEAREST)
  yield()

  GLFW.SwapBuffers(window.glfwWindow)
  GLFW.PollEvents()
  
end
GLFW.Terminate()
