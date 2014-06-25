using GLWindow, GLUtil, ModernGL, ImmutableArrays, GLFW, React, Images


global const window = createwindow("Mesh Display", 1000, 1000, debugging = false )
const cam = Cam(window.inputs, Vector3(1.9f0, 1.9f0, 1.0f0))

const vert2 = "
#version $(GLWindow.GLSL_VERSION)
in vec2 vertex;
in vec2 uv;
out vec2 uv_frag;
uniform mat4 projectionview;

void main(){
    uv_frag = uv;
    gl_Position = projectionview * vec4(vertex, 0.0, 1.0);
}

"
const frag2 = "
#version $(GLWindow.GLSL_VERSION)
out vec4 fragment_color;
uniform sampler2D ztex;
in vec2 uv_frag;
void main(){
   fragment_color = texture(ztex, uv_frag);
}
"
const vert = "
#version $(GLWindow.GLSL_VERSION)
in vec3 vertex;
in vec3 normal;
out vec3 N;
out vec3 vert;
uniform sampler2D ztex;
uniform sampler2D colortex;
uniform vec2 texsize;
uniform mat4 view, projection;
uniform mat3 normalmatrix;
out vec4 color;
void main(){
    float u = 1 - (float((gl_InstanceID % int(texsize.x))) / texsize.x);
    float v = 1 - (float((gl_InstanceID / int(texsize.y))) / texsize.y);
    float z = texture(ztex, vec2(u,v)).r;
    color   = texture(colortex, vec2(u,v));
    mat4 model = mat4(
            vec4(1, 0, 0, 0),
            vec4(0, 1, 0, 0),
            vec4(0, 0, 1, 0),
            vec4(u * 3, v * 3, z, 1));

    N = normalize(normalmatrix * normal);

    vert = vec3(view  * vec4(vertex, 1.0));

    gl_Position = projection * view * model * vec4(vertex, 1.0);
}
"
const frag = "
#version $(GLWindow.GLSL_VERSION)
out vec4 fragment_color;
void main(){

   fragment_color = vec4(1,0,0,1);
}
"

const phongfrag = "
#version $(GLWindow.GLSL_VERSION)
in vec3 N;
in vec3 vert;
out vec4 fragment_color;
uniform vec3 light_position;
in vec4 color;
void main(){
    vec3 L      = normalize(light_position - vert);
    //vec3 a      = vec3(1.0, 0.0, 0.1);
   //vec4 b       = vec4(0.0, 0.0, 0.1, 1);
   //vec4 color  = vec4(mix(a, b, 1.0), 1.0);
   vec4 Idiff   = color * max(dot(N,L), 0.0); 
   Idiff        = clamp(Idiff, 0.0, 1.0); 

   fragment_color = Idiff;
}
"
function zdata(x1, y1, factor)
    x = (x1 - 0.5) * factor
    y = (y1 - 0.5) * factor
    Vector1(float32(sin(10(x^2+y^2))/10) * 1.5f0)
end

function update(t::Texture, data)
    glBindTexture(t.texturetype, t.id)
    glTexSubImage2D(
        GL_TEXTURE_2D,
        0,
        0,
        0,
        size(data)...,
        t.format,
        t.pixeltype,
        data
    )
    glBindTexture(t.texturetype, 0)
end
const N = 100
texsize = Vector2(N)
const texdata = [zdata(i/N, j/N, 5) for i=1:N, j=1:N]

ztex = Texture(texdata, internalformat = GL_R32F, format=GL_RED)

key             = keepwhen(lift(x -> x == 1, Bool,window.inputs[:keypressedstate]), 0, window.inputs[:keypressed])

ffactor = foldl((a,b) -> begin
                if b == GLFW.KEY_U
                    return a-0.05f0
                elseif b == GLFW.KEY_Z
                    return a+0.05f0
                end
                a
            end, 0f0, key)

imgdata = lift(x -> [zdata(i/N, j/N, x) for i=1:N, j=1:N], Array{Vector1{Float32}, 2}, ffactor)
lift(x -> update(ztex, x), imgdata)


const vertexes, uv, normals, indexes = gencubenormals(Vector3{Float32}(0,0,0), Vector3{Float32}(0.02, 0, 0), Vector3{Float32}(0, 0.02, 0), Vector3{Float32}(0,0,0.1))
#const position, uv, indexes = genquad(1f0)
const data = RenderObject([
    :vertex         => GLBuffer{Float32}(convert(Ptr{Float32}, pointer(vertexes)), sizeof(vertexes), 3, GL_ARRAY_BUFFER, GL_STATIC_DRAW),
    :normal         => GLBuffer{Float32}(convert(Ptr{Float32}, pointer(normals)), sizeof(normals), 3, GL_ARRAY_BUFFER, GL_STATIC_DRAW),
    #:uv            => GLBuffer(uv, 2),
    :index          => GLBuffer(indexes, 1, bufferType = GL_ELEMENT_ARRAY_BUFFER),
    :ztex           => ztex,
    :colortex       => Texture(imread("julia.png")),
    :texsize        => convert(Vector2{Float32}, texsize),
    :projection     => cam.projection,
    :view           => cam.view,
    :normalmatrix   => lift( x -> begin
                                 m           = Matrix3x3(x)
                                 tmp         = zeros(Float32, 3,3)
                                 tmp[1, 1:3] = [m.c1...]
                                 tmp[2, 1:3] = [m.c2...]
                                 tmp[3, 1:3] = [m.c3...]
                                 inv(tmp)'
                              end , Array{Float32, 2}, cam.projectionview),
    :light_position => Float32[-800, -800, 0]
], GLProgram(vert, phongfrag, "lol"))

window_size     = window.inputs[:window_size]
dragged         = window.inputs[:mousedragged]
const imgd = Array(Uint8, 3, window_size.value...)
const imgprops = {"colorspace" => "RGB", "spatialorder" => ["x", "y"], "colordim" => 1}
function screenshot(window_size)
    global imgd, imgprops
    glReadPixels(0, 0, window_size..., GL_RGB, GL_UNSIGNED_BYTE, imgd)
    img = Image(mapslices(reverse,imgd, [3]), imgprops)
    imgname = "test/"*string(time()) * ".png"
    imwrite(img, imgname)
end



lift((a,b) -> screenshot(a), window_size, key)





glClearColor(1,1,1,0)
glEnable(GL_DEPTH_TEST)
glDepthFunc(GL_LESS)

include("grid.jl")
glDisable(GL_CULL_FACE)
while !GLFW.WindowShouldClose(window.glfwWindow)
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    glUseProgram(data.vertexArray.program.id)
    render(data.uniforms)
    #render(data.vertexArray)
    glBindVertexArray(data.vertexArray.id)

    glDrawElementsInstanced(GL_TRIANGLES, data.vertexArray.indexlength, GL_UNSIGNED_INT, C_NULL, N*N)

    render(axis)

    GLFW.SwapBuffers(window.glfwWindow)
    GLFW.PollEvents()
end
GLFW.Terminate()