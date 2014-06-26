using GLWindow, GLUtil, ModernGL, ImmutableArrays, GLFW, React, Images

vert = "
#version $(GLWindow.GLSL_VERSION)
in vec3 vertex;
in vec3 normal;

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
vec2 getxy(vec2 uv, vec2 from, vec2 to)
 {
   return from + (uv * (to - from));
 }
void main(){

    vec2 uv = getuv(texsize, gl_InstanceID);
    vec2 xy = getxy(uv, vec2(-1,-1), vec2(1,2));
    float z = texture(ztex, uv).r;
    color   = texture(colortex, uv);

    N = normalize(normalmatrix * normal);
    vert = vec3(view  * vec4(vertex, 1.0));

    gl_Position = projection * view *  getmodelmatrix(vec3(xy, 0), 1.0, 1.0, z) * vec4(vertex, 1.0);
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
  vec4 Idiff   = color * max(dot(N, L), 0.0);
  Idiff        = clamp(Idiff, 0.0, 1.0);

  fragment_color = vec4(Idiff.rgb, 1.0);
}
"


global const window = createwindow("Mesh Display", 1000, 1000, debugging = false)
const cam = Cam(window.inputs, Vector3(1.9f0, 1.9f0, 1.0f0))

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
    x = (x1 - 0.5) * factor
    y = (y1 - 0.5) * factor

    Vector1(float32((gauss(x, y) *5f0) ))
    #Vector1(float32(sin(10(x^2+y^2))/10) * 1.5f0)
end
function zcolor(z)
    Vector4(z[1] , z[1] , z[1] * 5, 1f0)
end
const N = 25
texsize = Vector2(N)
const texdata = [zdata(i/N, j/N, 5) for i=1:N, j=1:N]
const colordata = map(zcolor, texdata)



ztex       = Texture(texdata, internalformat = GL_R32F, format=GL_RED)
colortex   = Texture(colordata)

key        = keepwhen(lift(x -> x == 1, Bool,window.inputs[:keypressedstate]), 0, window.inputs[:keypressed])



const vertexes, uv, normals, indexes = gencubenormals(
        Vector3{Float32}(0,0,0), Vector3{Float32}(0.05, 0, 0), Vector3{Float32}(0, 0.05, 0), Vector3{Float32}(0,0,1)
    )

const data = RenderObject([
    :vertex         => GLBuffer(vertexes, 3),
    :normal         => GLBuffer(normals, 3),
    :index          => GLBuffer(indexes, 1, buffertype = GL_ELEMENT_ARRAY_BUFFER),
    :ztex           => ztex,
    :colortex       => colortex,
    :texsize        => convert(Vector2{Float32}, texsize),
    :projection     => cam.projection,
    :view           => cam.view,
    :normalmatrix   => cam.normalmatrix,
    :light_position => Float32[-800, -800, 800]
], GLProgram(vert, phongfrag, "lol"))


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
