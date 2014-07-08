gldisplay(x,y,z)


NUMERIC_TYPES = Union(GLDouble, GLfloat, GLint, GLuint)

#Uniform values are values, that are not part of an array.

# Maps the z value to a grid defined by xrange*yrange
# z can be single valued
# this comes with the following keyword arguments, defaults and possible types:
const ZMAP_KEY_ARGUMENTS = [
	:xrange 	=> 0:0.01:1, # Range{Real}) -> will be transformed to Float32
	:yrange 	=> 0:0.01:1, # Range{Real}),
	:zposition	=> 0.0f0 	 # GLNUMERICTYPES, Matrix{GLNUMERICTYPES}, Matrix{Vector1{GLNUMERICTYPES}})
							 # no x/yposition, as they are implicetely defined by the ranges

	:xscale		=> 0.01f0,  # GLNUMERICTYPES, Matrix{GLNUMERICTYPES}, Matrix{Vector1{GLNUMERICTYPES}})
	:yscale		=> 0.01f0,  # GLNUMERICTYPES, Matrix{GLNUMERICTYPES}, Matrix{Vector1{GLNUMERICTYPES}})
	:zscale		=> 0.0f0,   # GLNUMERICTYPES, Matrix{GLNUMERICTYPES}, Matrix{Vector1{GLNUMERICTYPES}})

	:color 		=> Vector4(0f0,0f0,0f0,1f0), #Vector1/3/4{GLNUMERICTYPES}, Matrix{GLNUMERICTYPES}, Matrix{Vector1/3/4{GLNUMERICTYPES}})
# actually, if you feel funky, you can simply hack your own attributes into the shader, and I might also add a few more later in the process

	:primitive 	=> SURFACE # Possible are CUBE, POINT, any custom Mesh, 
]
gldisplay(zheight::Matrix{Vector1{GLNUMERICTYPES}}	; parameters...) = gldisplay(zheight, merge!(parameters, ZMAP_KEY_ARGUMENTS))
gldisplay(zheight::Matrix{GLNUMERICTYPES}			; parameters...) = gldisplay(zheight, merge!(parameters, ZMAP_KEY_ARGUMENTS))
gldisplay(zheight::GLNUMERICTYPES					; parameters...) = gldisplay(zheight, merge!(parameters, ZMAP_KEY_ARGUMENTS))
	





gldisplay(Vector{Vector2{GLNUMERICTYPES}}})
gldisplay(Vector{Vector3{GLNUMERICTYPES}}})
gldisplay(Vector{Vector4{GLNUMERICTYPES}}})