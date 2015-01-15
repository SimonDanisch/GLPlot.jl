using GLAbstraction, GLPlot, Reactive

window = createdisplay(h=1000,w=1500, eyeposition=Vec3(2,0,0))
# one way of creating different texts:
time_signal = fpswhen( window.inputs[:open], 30)
text = lift(time_signal) do x
	"time for one frame: $x"
end
# the other option would be to call push! somewhere in your renderloop:
# text = Input("start text")
# push!(text, "new text") <- can stand anywhere, but in a lift

pivot_point = lift(window.area) do x
	x.w-(x.w/2), x.h-(x.h/2)
end
counter = foldl(+, 0f0, time_signal) 
translation = lift(pivot_point, counter) do pivot, i
	x, y = pivot
    translationmatrix(Vec3(x+100*sin(i/5),y+100*cos(i/5), 0))
end
glplot(text, model=translation) 




renderloop(window)