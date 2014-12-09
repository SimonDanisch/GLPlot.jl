import VideoIO
using GLPlot, React, GLAbstraction
 
 
device  = VideoIO.DEFAULT_CAMERA_DEVICE
format  = VideoIO.DEFAULT_CAMERA_FORMAT
camera  = VideoIO.opencamera(device, format)
img   = VideoIO.read(camera)
 
# Just for fun, lets apply a laplace filter:
 
#async=true, for REPL use. Then you don't have to call renderloop(window)
window  = createdisplay(#=async=true =#) 
img     = glplot(Texture(img, 3))
 
#Get Gpu memory object
glimg   = img.uniforms[:image]
 
#Asynchronous updating with React:
lift(Timing.fpswhen(window.inputs[:open], 30.0)) do x
  newframe = VideoIO.read(camera)
  update!(glimg,  mapslices(reverse, newframe, 3)) # needs to be mirrored :(
end
 
renderloop(window)