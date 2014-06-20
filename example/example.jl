using GLPlot
using Base.Test


sampleMesh = createSampleMesh()
gldisplay(sampleMesh)



#=
sz 		= [256, 256, 256]
center 	= iceil(sz/2)
C3 		= Bool[(i-center[1])^2 + (j-center[2])^2 <= (k^2) / 3 for i = 1:sz[1], j = 1:sz[2], k = sz[3]:-1:1]
cone 	= C3*uint8(255)
volume 	= createvolume(cone, shader = mipshader)

gldisplay(volume, shader=mipshader)
#gldisplay("path to folder with identically dimensioned images")
#dldisplay(imread("3d volume image"),  shader=volumeshader)

=#

gldisplay(:xyzaxis, GLPlot.axis)
startplot()