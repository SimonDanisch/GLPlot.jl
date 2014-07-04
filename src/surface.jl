const phongvert = "
#version $(GLWindow.GLSL_VERSION)
in vec3 vertex;
in vec3 normal;
out vec3 N;
out vec3 v;

uniform mat4 view, projection;
uniform mat3 normalmatrix;

void main(){

	 v = vec3(view  * vec4(vertex,1.0));       
   N = normalize(normalmatrix * normal);

   gl_Position = projection * view * vec4(vertex, 1.0);
}

"
const phongfrag = "
#version $(GLWindow.GLSL_VERSION)
in vec3 N;
in vec3 v;
out vec4 fragment_color;
uniform vec3 light_position;

void main(){
	vec3 L 		= normalize(light_position - v);
	vec3 a 		= vec3(1.0, 0.0, 0.1);
   vec3 b 		= vec3(0.0, 1.0, 0.1);
	vec4 color 	= vec4(mix(a, b, vertpos.z + 0.5), 1.0);
   vec4 Idiff 	= color * max(dot(N,L), 0.0); 
   Idiff 		= clamp(Idiff, 0.0, 1.0); 

   fragment_color = vec4(Idiff.rgb, 1.0);
}
"
const brdfvert = "
#version $(GLWindow.GLSL_VERSION)

in vec3 tangent;
in vec3 binormal;
in vec3 normal;
in vec3 vertex;

uniform vec3    light_position;  // Light direction in eye coordinates
uniform vec3    viewposition;

uniform mat4    projectionview;

uniform mat3    normalmatrix;

out vec3 N, L, H, R, T, B, xyz;

void main()
{
    vec3 V, eyeDir;
    vec4 pos;
    xyz    = vertex / 500.0;
    pos    = projectionview * vec4(vertex, 1.0);
    eyeDir = pos.xyz;

    N = normalize(normalmatrix * normal);
    L = normalize(light_position);
    V = normalize((projectionview * vec4(viewposition, 1.0)).xyz - pos.xyz);
    H = normalize(L + V);
    R = normalize(reflect(eyeDir, N));
    T = normalize(normalmatrix * tangent);
    B = normalize(normalmatrix * binormal);

    gl_Position = pos;
}
"
const brdffrag = "
#version $(GLWindow.GLSL_VERSION)

const float PI = 3.14159;
const float ONE_OVER_PI = 1.0 / PI;

uniform vec4 surfacecolor; // Base color of surface
uniform vec2 P;            // Diffuse (x) and specular reflectance (y)
uniform vec2 A;            // Slope distribution in x and y
uniform vec3 Scale;        // Scale factors for intensity computation

varying vec3 N, L, H, R, T, B, xyz;

void main()
{
    float e1, e2, E, cosThetaI, cosThetaR, brdf, intensity;

    e1 = dot(H, T) / A.x;
    e2 = dot(H, B) / A.y;
    E = -2.0 * ((e1 * e1 + e2 * e2) / (1.0 + dot(H, N)));

    cosThetaI = dot(N, L);
    cosThetaR = dot(N, R);

    brdf = P.x * ONE_OVER_PI +
           P.y * (1.0 / sqrt(cosThetaI * cosThetaR)) *
           (1.0 / (4.0 * PI * A.x * A.y)) * exp(E);

    intensity = Scale[0] * P.x * ONE_OVER_PI +
                Scale[1] * P.y * cosThetaI * brdf +
                Scale[2] * dot(H, N) * P.y;

    vec3 color = max(intensity, 0.2) * vec3(0.95, xyz.z + 0.5, 0.05);

    gl_FragColor = vec4(color, 1.0);
}

"

phongshader = GLProgram(phongvert, phongfrag,   "phong shader")
brdfshader  = GLProgram(brdfvert, brdffrag,     "BRDF shader")



function creategrid{T}(x::AbstractArray{T}, y::AbstractArray{T}, z::AbstractArray{T}, color::AbstractArray{T},)
    combined = [x, y, z, color]
    dims     = map(ndims, combined)
    @assert all(x-> x<=2, dims) #can't handle 3D arrays
    sizes    = map(size,  combined)
    dim2d    = filter(x-> lenght(x) == 2, sizes)

end
function creategrid(;dim = (250,250), x = 1:dim[1], y = 1:dim[1], z = zeros(Float32, dim...), color = Vector4(0.4,0.4,0.4,1))

end

function createSampleMesh()
   const N = 100
   xyz = Array(Vector3{Float32}, N*N)
   index = 1
   for x=1:N, y=1:N
      x1 = (x / N) 
      y1 = (y / N)
      xyz[index] = Vector3{Float32}(x1, y1, sin(10f0*((((x1- 0.5f0) * 2)^2) + ((y1 - 0.5f0) * 2)^2))/10f0)
      index += 1
   end
   normals     = Array(Vector3{Float32}, N*N)
   binormals   = Array(Vector3{Float32}, N*N)
   tangents    = Array(Vector3{Float32}, N*N)
   indices  = Vector3{GLuint}[]
   for i=1:(N*N) - N - 1
      if i%N != 0
         a = Vector3{GLuint}(i    , i+N, i+N+1) - 1
         b = Vector3{GLuint}(i+N+1, i+1, i   ) - 1
         push!(indices, a)
         push!(indices, b)
      end
   end
   for i=1:length(normals)
      #indices = [i-1, i+1, i-N, i+N, i-1 + N, i+1 +N, i-1 - N, i+1-N]
      a = xyz[i]
      b = i > 1 ? xyz[i-1] : xyz[i+1]
      c = i + N > N*N ? xyz[i-N] : xyz[i+N]

      Tt = a-b
      Bt = a-c
      Nt = cross(Tt, Bt)

      tangents[i]    = Tt / norm(Tt)
      binormals[i]   = Bt / norm(Bt)
      normals[i]     = Nt / norm(Nt)
   end
   mesh =
      [
         :indexes       => GLBuffer{GLuint}(convert(Ptr{GLuint},   pointer(indices)),   sizeof(indices),    1, GL_ELEMENT_ARRAY_BUFFER, GL_STATIC_DRAW),
         :vertex        => GLBuffer{Float32}(convert(Ptr{Float32}, pointer(xyz)),       sizeof(xyz),        3, GL_ARRAY_BUFFER, GL_STATIC_DRAW),
         :normal        => GLBuffer{Float32}(convert(Ptr{Float32}, pointer(normals)),   sizeof(normals),    3, GL_ARRAY_BUFFER, GL_STATIC_DRAW),
         #:tangent       => GLBuffer{Float32}(convert(Ptr{Float32}, pointer(tangents)),  sizeof(tangents),   3, GL_ARRAY_BUFFER, GL_STATIC_DRAW),
         #:binormal      => GLBuffer{Float32}(convert(Ptr{Float32}, pointer(binormals)), sizeof(binormals),  3, GL_ARRAY_BUFFER, GL_STATIC_DRAW),

         :view          => cam.view,
         :projection    => cam.projection,
         #:projectionview=> cam.projectionview,
         #:viewposition  => cam.eyeposition,
         :normalmatrix  => lift( x -> begin
                                 m = Matrix3x3(x)
                                 tmp    = zeros(Float32, 3,3)
                                 tmp[1, 1:3] = [m.c1...]
                                 tmp[2, 1:3] = [m.c2...]
                                 tmp[3, 1:3] = [m.c3...]
                                 inv(tmp)'
                              end , Array{Float32, 2}, cam.projectionview),
         :light_position   => Float32[-800, -800, 0],
         #:P                => Float32[0.9, 0.9],
         #:A                => Float32[0.8, 0.8],
         #:Scale            => Float32[0.9, 0.9, 0.9],
      ]
   # The RenderObject combines the shader, and Integrates the buffer into a VertexArray
   mesh = RenderObject(mesh, phongshader)
   prerender!(mesh, enableTransparency)
   mesh
end
