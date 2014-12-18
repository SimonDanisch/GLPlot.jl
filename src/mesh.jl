import Meshes

begin 
toopengl(mesh::Meshes.Mesh) = toopengl(convert(GLMesh{(Face{GLuint}, Normal{Float32}, UV{Float32}, Vertex{Float32})}, mesh))

local const light       = Vec3[Vec3(1.0,0.9,0.8), Vec3(0.01,0.01,0.1), Vec3(1.0,0.9,0.9), Vec3(10.0, 10.0,10.0)]
local const MESH_SHADER = Any[]

function toopengl(mesh::GLMesh{(Face{GLuint}, Normal{Float32}, UV{Float32}, Vertex{Float32})}; camera=pcamera)
    if isempty(MESH_SHADER)
        push!(MESH_SHADER, TemplateProgram(Pkg.dir("GLPlot", "src", "shader", "standard.vert"), Pkg.dir("GLPlot", "src", "shader", "phongblinn.frag")))
    end
    shader = first(MESH_SHADER)
    #cam     = customizations[:camera]
    #light   = customizations[:light]
    mesh[:vertex] = unitGeometry(mesh[:vertex])
    data = merge(collect_for_gl(mesh), @compat(Dict(
        :view            => camera.view,
        :projection      => camera.projection,
        :model           => eye(Mat4),
        :eyeposition     => camera.eyeposition,
        :light           => light,
    )))
    ro = RenderObject(data, shader)
    prerender!(ro, glEnable, GL_DEPTH_TEST, glDepthFunc, GL_LEQUAL, glDisable, GL_CULL_FACE, enabletransparency)
    postrender!(ro, render, ro.vertexarray)
    ro
end
end
