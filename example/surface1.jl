using GLAbstraction, GLPlot, Reactive

window = createdisplay(w=1920,h=1280)

function zdata(x1, y1, factor)
    x = (x1 - 0.5) * 15f0
    y = (y1 - 0.5) * 15f0
    R = sqrt(x^2 + y^2) * factor
    Z = sin(R)/R
    Vec1(Z)
end

const N   = 256
texdata   = [zdata(i/N, j/N, 5) for i=1:N, j=1:N]


# Color can be a single line, GLSL (C-dialekt) string.
# This will soon be extended, to support custom uploaded uniforms (values which you can update and use in your calculation)
# And will also support using more than one line.
obj     = glplot(texdata, color="vec4(1-(0.8+xyz.z), 0.2 + xyz.z, 0.5,1.0);") 

zgpu 	= obj[:z]
counter = 0f0
lift(fpswhen(window.inputs[:open], 30.0)) do x
    global counter
	zgpu[1:end, 1:end] = [zdata(i/N, j/N, sin(counter)*10f0) for i=1:N, j=1:N]
    counter += 0.01f0
end
renderloop(window)