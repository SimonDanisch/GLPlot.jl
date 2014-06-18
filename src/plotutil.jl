
volumeShader = GLProgram("volumeShader")

function createvolume(img::Image; cropDimension=1:256)
	volume = img.data[cropDimension, cropDimension, 1:end]
	max = maximum(volume)
	min = minimum(volume)

	volume = float32((volume .- min) ./ (max - min))
	createvolume(volume)
end
function createvolume(img::Array; spacing = [1f0, 1f0, 1f0])
	tex = Texture(img, GL_TEXTURE_3D)
	position, uv, indexes = gencube(spacing...)
	RenderObject(
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
end
function createvolume(dirpath::String; cropDimension = 1:256)
	files 		= readdir(dirpath)
	imgSlice1 	= imread(dirpath*files[1])
	volume 		= Array(Uint16, size(imgSlice1)[1], size(imgSlice1)[2], length(files))
	imgSlice1	= 0
	for (i,elem) in enumerate(files)
		img = imread(dirpath*elem)
		@assert any(x->x>0, img)
		volume[:,:, i] = img.data
	end
	max = maximum(volume)
	min = minimum(volume)

	volume = float32((volume .- min) ./ (max - min))
	volume = volume[cropDimension, cropDimension, cropDimension]
	createvolume(volume)
end

#= 
x,y,z = cone.properties["pixelspacing"]
pspacing = [float64(x), float64(y), float64(z)]

cone = cone.data[1:256, :, :]
spacing = float32(pspacing .* Float64[size(cone)...] * 2000.0)
println(spacing)
=#