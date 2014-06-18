using GLWindow, GLUtil, ModernGL, Meshes, Events, React, Images, ImmutableArrays
import Base.merge
import GLUtil.rotate
import GLUtil.move
import GLUtil.render
width 	= 1024
height 	= 1024

render(location::GLint, signal::Signal) = render(location, signal.value)

rotate(point::Vector3{Float32}, angleaxis::(Vector3{Float32}, Int64)) = rotate(point, angleaxis[2], angleaxis[1])
function rotate(point, angle, axis)

	if angle > 0
		rotation = rotationmatrix(float32(deg2rad(angle)), axis)
	else
		rotation = rotationmatrix(float32(deg2rad(abs(angle))), axis)

		tmp 	 	= zeros(Float32, 4,4)
		tmp[1:4, 1] = [rotation.c1...]
		tmp[1:4, 2] = [rotation.c2...]
		tmp[1:4, 3] = [rotation.c3...]
		tmp[1:4, 4] = [rotation.c4...]
		rotation = inv(tmp)
		rotation = Matrix4x4(rotation)

	end
	Vector3(rotation * Vector4(point..., 0f0))
end


immutable Cam{T}
	window_size::Signal{Vector2{Int}}
	window_ratio::Signal{T}
	nearclip::Signal{T}
    farclip::Signal{T}
    fov::Signal{T}
	view::Signal{Matrix4x4{T}}
	projection::Signal{Matrix4x4{T}} 
	projectionview::Signal{Matrix4x4{T}} 
	eyeposition::Signal{Vector3{T}} 
	lookat::Signal{Vector3{T}} 
	direction::Signal{Vector3{T}}
	right::Signal{Vector3{T}}
	up::Signal{Vector3{T}}
end


function Cam{T}(window_size::Input{Vector2{Int}}, xdiff::Input{Int}, eyeposition::Vector3{T}, _lookat::Input{Vector3{T}})
	
	nearclip 		= Input{T}(convert(T, 1))
	farclip 		= Input{T}(convert(T, 30))
	up 				= Input(Vector3{T}(0, 0, 1))
	fov 			= Input{T}(convert(T, 76))
	upvectorangle 	= lift(tuple, up, xdiff)

	_position 		= foldl(rotate, eyeposition, upvectorangle)

	direction 		= lift(-, Vector3{T}, _position, _lookat)
	right 			= lift((a,b) -> unit(cross(a,b)), Vector3{T}, direction, up)

	rightvectorangle = lift(tuple, right, xdiff)

	window_ratio 	= lift(x -> x[1] / x[2], T, window_size)

	_view 			= lift(lookat, Matrix4x4{T}, _position, _lookat, up)

	projection 		= lift(perspectiveprojection, Matrix4x4{T}, fov, window_ratio, nearclip, farclip)
	projectionview 		= lift(*, Matrix4x4{T}, projection, _view)

	Cam{T}(
			window_size, 
			window_ratio,
			nearclip,
			farclip,
			fov,
			_view, 
			projection,
			projectionview,
			_position,
			_lookat,
			direction,
			right,
			up
		)
end

function renderObject(renderObject::RenderObject)
	glEnable(GL_DEPTH_TEST)
	glEnable(GL_CULL_FACE)
	glCullFace(GL_BACK)
	enableTransparency()
	programID = renderObject.vertexArray.program.id
	glUseProgram(programID)
	render(renderObject.uniforms)
	render(renderObject.vertexArray)
end

function renderObject2(renderObject::RenderObject)
	glDisable(GL_DEPTH_TEST)
	glDisable(GL_CULL_FACE)
	enableTransparency()
	render(renderObject)
end


function gencube(x,y,z)
	vertices = Float32[
    0.0, 0.0,  z,
     x, 0.0,  z,
     x,  y,  z,
    0.0,  y,  z,
    # back
    0.0, 0.0, 0.0,
     x, 0.0, 0.0,
     x,  y, 0.0,
    0.0,  y, 0.0
	]
	uv = Float32[
    0.0, 0.0,  1.0,
     1.0, 0.0,  1.0,
     1.0,  1.0,  1.0,
    0.0,  1.0,  1.0,
    # back
    0.0, 0.0, 0.0,
     1.0, 0.0, 0.0,
     1.0,  1.0, 0.0,
    0.0,  1.0, 0.0
	]
	indexes = GLuint[
	 0, 1, 2,
    2, 3, 0,
    # top
    3, 2, 6,
    6, 7, 3,
    # back
    7, 6, 5,
    5, 4, 7,
    # bottom
    4, 5, 1,
    1, 0, 4,
    # left
    4, 0, 3,
    3, 7, 4,
    # right
    1, 5, 6,
    6, 2, 1]
    return (vertices, uv, indexes)
end


window = createWindow("Volume Display", 1000, 1000 )
#dragging = window.inputs[:mousedragged]
#println(dragging)
#lift(println,Nothing, dragging)

cam = Cam(window.inputs[:window_size], window.inputs[:scroll_y], Vector3(1f0, 0f0, 0f0), Input(Vector3(0.5f0,0.5f0, 0.5f0)))


volumeShader = GLProgram("volumeShader")



files 		= readdir("example")
imgSlice1 	= imread("example/"*files[1])
volumeScan 	= Array(Uint16, size(imgSlice1)[1], size(imgSlice1)[2], length(files))
i = 1
for elem in files
	img = imread("example/"*elem)
	volumeScan[:,:, i] = img.data
	i+=1
end

volumeScan = volumeScan[1:256, 1:256, 1:256]

max = maximum(volumeScan)
min = minimum(volumeScan)

volumeScan = float32((volumeScan .- min) ./ (max - min))

tex = Texture(volumeScan, GL_TEXTURE_3D)

volumeScan = 0
spacing = [1f0, 1f0, 1f0]
position, uv, indexes = gencube(spacing...)

cone3D = RenderObject(
	[
		:volume_tex 	=> tex,
		:stepsize 		=> 0.001f0,
		:normalizer 	=> spacing, 
		:position 		=> GLBuffer(position, 3),
		:indexes 		=> GLBuffer(indexes, 1, bufferType = GL_ELEMENT_ARRAY_BUFFER),
		:mvp 			=> cam.projectionview,
		:camposition	=> cam.eyeposition
	]
	, volumeShader)


glDisplay(:zz, renderObject, cone3D)


glClearColor(0,0,0,0)

renderloop(window)

#= 
x,y,z = cone.properties["pixelspacing"]
pspacing = [float64(x), float64(y), float64(z)]

cone = cone.data[1:256, :, :]
spacing = float32(pspacing .* Float64[size(cone)...] * 2000.0)
println(spacing)
=#
