using GLWindow, GLUtil, ModernGL, ImmutableArrays, GLFW, React, Images




global const window = createwindow("Mesh Display", 1000, 1000, debugging = false)
const cam = Cam(window.inputs, Vector3(1.9f0, 1.9f0, 1.0f0))
vert =  "
#version $(GLWindow.GLSL_VERSION)
in vec2 offset;

out vec3 N;
out vec3 vert;
out vec4 color;

uniform sampler2D ztex;
uniform sampler2D colortex;
uniform vec2 texsize;

uniform mat4 view, projection;
uniform mat3 normalmatrix;

mat4 getmodelmatrix(vec3 xyz, float xscale, float yscale, float zscale)
{
   return mat4(
      vec4(xscale, 0, 0, 0),
      vec4(0, yscale, 0, 0),
      vec4(0, 0, zscale, 0),
      vec4(xyz, 1));
}

vec2 getuv(vec2 texdim, int index)
{
  float u = float((index % int(texdim.x))) / texdim.x;
  float v = float((index / int(texdim.y))) / texdim.y;
  return vec2(u,v);
}
vec2 getuv(vec2 texdim, int index, vec2 offset)
{
  float u = float((index % int(texdim.x)));
  float v = float((index / int(texdim.y)));
  return (vec2(u,v) + offset) / texdim;
}
vec2 getxy(vec2 uv, vec2 from, vec2 to)
 {
   return from + (uv * (to - from));
 }
void main(){

    vec2 uv = getuv(texsize, gl_InstanceID, offset);
    vec2 xy = getxy(uv, vec2(0,0), vec2(1,1));
    vec4 zdata = texture(ztex, uv);
    vec3 xyz = vec3(xy, zdata.x);

    color   = texture(colortex, uv);

    N = normalize(normalmatrix * zdata.yzw);
    //N = zdata.yzw;

    vert = vec3(view  * vec4(xyz, 1.0));

    gl_Position = projection * view *  getmodelmatrix(xyz, 1.0, 1.0, 1.0) * vec4(0,0,0, 1.0);
}
"

phongfrag = "
#version $(GLWindow.GLSL_VERSION)
in vec3 N;
in vec3 vert;
out vec4 fragment_color;
uniform vec3 light_position;
in vec4 color;
void main(){
  vec3 L       = normalize(light_position - vert);
  vec4 Idiff   = vec4(0.8,0,0,1) * max(dot(N, L), 0.0);
  Idiff        = clamp(Idiff, 0.0, 1.0);

  fragment_color = vec4(1,0,0, 1.0);
}
"
function gauss(x, y)
    factor = 1 / (2*pi)
    exponent = -( ((x^2) + (y^2))/ 2)
    factor * exp(exponent)
end
function gauss(x, mu, sigma)
    factor = 1 / (2*pi*sigma^2)
    exponent = -((x - mu)^2 / 2*(sigma^2))
    factor * exp(exponent)
end
function zdata(x1, y1, factor)
    x = (x1 - 0.5) * 2
    y = (y1 - 0.5) * 2

    Vector4(float32(sin(10(x^2+y^2))/10) * 1.5f0,  0f0, 0f0, 0f0)
end
function zcolor(z)
    Vector4(z[1] , z[1] , z[1] * 5, 1f0)
end


N = 250
texsize = Vector2(N)
texdata = [zdata(i/N, j/N, 5) for i=1:N, j=1:N]
typeof(texdata)
colordata = map(zcolor, texdata)
w, h = size(texdata)
#=
for x=1:w, y=1:h
  xf = float32(x / w)
  yf = float32(y / h)
  zf = float32(texdata[x,y][1])
  current = Vector3(xf, yf, zf)
  #calculate indexes for surrounding zvalues
  indexes = [(x+1,y), (x,y+1), (x+1,y+1),
             (x-1,y), (x,y-1), (x-1,y-1)]
  #Remove out of bounds
  filter!(elem -> elem[1] >= 1 && elem[2] >= 1 && elem[1] <= w && elem[2] <= h, indexes)
  #Construct the full surrounding vectors with x,y,z coordinates
  kneighbours = map(elem -> Vector3(xf+ float32(elem[1] / w), yf+ float32(elem[2] / h), texdata[elem...][1]), indexes)
  kdiffs = map(elem -> current - elem, kneighbours)
  #normals = reduce((v0, a) -> push!(v0, cross(a,v0[end])), Vector3{Float32}[kdiffs[end]], kdiffs[1:end-1])

  #get the some of the cross with the current vector and normalize
  #normal = unit(sum(map(x -> cross(current,x), kneighbours)))
  #normal = unit( cross(kdiffs[1],kdiffs[2]))
  println(length(kdiffs))
  normal = unit( reduce( (v0, a) -> begin
                              res = cross(a, v0[end])
                              push(v0, a)

                            end, Vector3{Float32}[kdiffs[1]], kdiffs[2:end]))

  println(normal)
  texdata[x,y] = Vector4(zf, normal...)
end
=#

texparams = [
   (GL_TEXTURE_MIN_FILTER, GL_NEAREST),
  (GL_TEXTURE_MAG_FILTER, GL_NEAREST),
  (GL_TEXTURE_WRAP_S,  GL_CLAMP_TO_EDGE),
  (GL_TEXTURE_WRAP_T,  GL_CLAMP_TO_EDGE)
 ]

ztex       = Texture(texdata, internalformat = GL_RGBA32F, format=GL_RGBA, parameters = texparams)
colortex   = Texture(colordata, parameters = texparams)


const data = RenderObject([
    :offset         => GLBuffer(Float32[0,0, 0,1, 1,1, 1,0], 2),
    :index          => GLBuffer(GLuint[0,1,2,2,3,0], 1, buffertype = GL_ELEMENT_ARRAY_BUFFER),
    :ztex           => ztex,
    :colortex       => colortex,
    :texsize        => convert(Vector2{Float32}, texsize),
    :projection     => cam.projection,
    :view           => cam.view,
    #:normalmatrix   => cam.normalmatrix,
    #:light_position => Float32[800, 800, -800]
], GLProgram(vert, phongfrag, "lol"))

function renderinstanced(vao::GLVertexArray, amount)
    glBindVertexArray(vao.id)
    glDrawElementsInstanced(GL_TRIANGLES, vao.indexlength, GL_UNSIGNED_INT, C_NULL, amount)
end
postrender!(data, renderinstanced, data.vertexarray, N*N)

include("grid.jl")

glClearColor(1,1,1,0)

glEnable(GL_DEPTH_TEST)
glDepthFunc(GL_LESS)

glDisable(GL_CULL_FACE)
while !GLFW.WindowShouldClose(window.glfwWindow)

  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

  render(data)
  render(axis)

  GLFW.SwapBuffers(window.glfwWindow)
  GLFW.PollEvents()

end
GLFW.Terminate()
