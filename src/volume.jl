const volumevert = "
in vec3 position;

out vec3 position_o;

uniform mat4 mvp;

void main()
{
    position_o 	= position;
    gl_Position = mvp * vec4(position, 1.0);
}

"
global const volumeMIPfrag = "
uniform sampler3D volume_tex;
uniform float stepsize;
uniform vec3 normalizer;

in vec3 position_o;

out vec4 colour_output;

uniform vec3 camposition;

void main()
{
    vec3  normed_dir    = normalize(position_o - camposition) * (normalizer * stepsize);
    vec4  colorsample   = vec4(0.0);
    float alphasample   = 0.0;
    vec4  coloraccu     = vec4(0.0);
    float alphaaccu     = 0.0;
    vec3  start         = position_o;
    float maximum       = 0;
    float alpha_acc     = 0.0;  
    float alpha_sample; // The src alpha
    int i = 0;
    for(i; i < 10000; i++)
    {
        colorsample = texture(volume_tex, start / normalizer);
        
        if(colorsample.r > coloraccu.r)
        {
          coloraccu = vec4(colorsample.r,colorsample.r,colorsample.r, 1);
        }
      	start += normed_dir;

	    if(coloraccu.r >= 0.999 || start.x >= normalizer.x || start.y >= normalizer.y || start.z >= normalizer.z || start.x <= 0 || start.y <= 0 || start.z <= 0)
	    {
	       break;
	    }
    }
    float r = smoothstep(0.3, 0.8, coloraccu.r);
    float g = smoothstep(0.6, 1.0, coloraccu.r);
    float b = smoothstep(0.0, 1.0, coloraccu.r);
    float a = smoothstep(0.01, 1.0, coloraccu.r);
    colour_output = vec4(r, g, b, a);
    //colour_output = vec4(start,1);

    //colour_output =vec4(smoothstep(0.0, 0.4, coloraccu.r),  smoothstep(0.4, 0.7, coloraccu.r), smoothstep(0.7, 0.8, coloraccu.r), smoothstep(0.4, 0.5, coloraccu.r));
    //colour_output =vec4(normed_dir, 1);
}
"


global const volumefrag = "
uniform sampler3D volume_tex;
uniform float stepsize;
uniform vec3 normalizer;

in vec3 position_o;

out vec4 colour_output;

uniform vec3 camposition;

void main()
{
    vec3  normed_dir    = normalize(position_o - camposition) * (normalizer * stepsize);
    vec4  colorsample   = vec4(0.0);
    float alphasample   = 0.0;
    vec4  coloraccu     = vec4(0.0);
    float alphaaccu     = 0.0;
    vec3  start         = position_o;
    float maximum       = 0;
    float alpha_acc     = 0.0;  
    float alpha_sample; // The src alpha
    int i = 0;
    for(i; i < 10000; i++)
    {
    	colorsample = texture(volume_tex, start / normalizer);
    
    	colorsample = vec4(colorsample.r);
    	alpha_sample = colorsample.a*stepsize;
    	coloraccu += (1.0 - alpha_acc) * colorsample * alpha_sample*3;
    	alpha_acc += alpha_sample;
             
      	start += normed_dir;

	    if(coloraccu.r >= 1.0 || start.x >= normalizer.x || start.y >= normalizer.y || start.z >= normalizer.z || start.x <= 0 || start.y <= 0 || start.z <= 0)
	    {
	       break;
	    }
    }
    float r = smoothstep(0.3, 0.8, coloraccu.r);
    float g = smoothstep(0.6, 1.0, coloraccu.r);
    float b = smoothstep(0.0, 1.0, coloraccu.r);
    float a = smoothstep(0.01, 1.0, coloraccu.r);
    //colour_output = vec4(r, g, b, a);
    colour_output = coloraccu;

    //colour_output =vec4(smoothstep(0.0, 0.4, coloraccu.r),  smoothstep(0.4, 0.7, coloraccu.r), smoothstep(0.7, 0.8, coloraccu.r), smoothstep(0.4, 0.5, coloraccu.r));
    //colour_output =vec4(normed_dir, 1);
}
"
global const volumeshader   = GLProgram(volumevert, volumefrag, "volumeShader")
global const mipshader      = GLProgram(volumevert, volumeMIPfrag, "volumeMipShader")
export volumeshader,mipshader 

function createvolume(img::Image; cropDimension=1:256, shader = volumeshader )
	volume = img.data
	max = maximum(volume)
	min = minimum(volume)

	volume = float32((volume .- min) ./ (max - min))
	createvolume(volume, shader = shader)
end
function createvolume(img::Array; spacing = [1f0, 1f0, 1f0], shader = volumeshader )
	tex = Texture(img, GL_TEXTURE_3D)
	position, uv, indexes = gencube(spacing...)
	volume = RenderObject(
		[
			:volume_tex 	=> tex,
			:stepsize 		=> 0.001f0,
			:normalizer 	=> spacing, 
			:position 		=> GLBuffer(position, 3),
			:indexes 		=> GLBuffer(indexes, 1, buffertype = GL_ELEMENT_ARRAY_BUFFER),
			:mvp 			=> cam.projectionview,
			:camposition	=> cam.eyeposition
		]
		, shader)
		(GL_DEPTH_TEST)

	prerender!(volume, glEnable, GL_CULL_FACE, glCullFace, GL_BACK, enableTransparency)
	volume
end
function createvolume(dirpath::String; cropDimension = 1:256, shader = volumeshader )
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
	createvolume(volume, shader = shader)
end


#= 
x,y,z = cone.properties["pixelspacing"]
pspacing = [float64(x), float64(y), float64(z)]

cone = cone.data[1:256, :, :]
spacing = float32(pspacing .* Float64[size(cone)...] * 2000.0)
println(spacing)
=#