using GLPlot, GLAbstraction, ModernGL


window = createdisplay(w=1000,h=1000,eyeposition=Vec3(1.,1.,1.), lookat=Vec3(0.,0.,0.));
color  = Vec4(1,0,0,1)
n=100
h=1./n
r=h:h:1.
t=(-1:h:1+h)*π
x=float32(r*cos(t)')
y=float32(r*sin(t)')

f(x,y)  = exp(-10x.^2-20y.^2)  # arbitrary function of f
z       = Float32[float32(f(x[k,j],y[k,j])) for k=1:size(x,1),j=1:size(x,2)]
obj     = glplot(z, xrange=x, yrange=y, color="xyz.z>0 ? vec4(.1,.1,0.5+3*xyz.z, 1.0) : vec4(.1,.1-3*xyz.z,0.5,  1.0);")


renderloop(window)

