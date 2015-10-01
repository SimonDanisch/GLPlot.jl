VERSION >= v"0.4.0-dev+6521" && __precompile__(true)

module GLPlot

using GLVisualize, GLWindow, ModernGL, GeometryTypes, Reactive, GLAbstraction, Colors, ModernGL

export clearplot, glplot, windowroot


function project(projectionview, points, target, resolution)
	@inbounds for i=1:length(points)
		target[i] = Point{2, Float16}(projectionview*Point(points[i], 1f0)).*Point{2, Float16}(resolution)
	end
	target
end
function position_annotations(
		tick_text, startposition, step_direction, 
		projectionview, resolution, 
		tick_major_color=RGBA{U8}(0.6, 0.6, 0.6, 1.), tick_minor_color=RGBA{U8}(0.7, 0.7, 0.7, 1.)
	)
	text_length = sum(map(length, tick_text))
	positions 	= Array(Point3f0, text_length)
	glyps 		= Array(GLVisualize.GLSprite, text_length)
	styles 		= Array(GLVisualize.GLSpriteStyle, text_length)
	colors 		= Texture(RGBA{U8}[tick_major_color, tick_minor_color])
	i 		= 1
	max_y 	= 0.0
	pos 	= Point3f0(startposition)
	for (t, tick) in enumerate(tick_text)
		for glyph in tick
			glglyph 	 = GLVisualize.get_font!(glyph)
			glyps[i] 	 = GLVisualize.GLSprite(glglyph)
			styles[i] 	 = GLVisualize.GLSpriteStyle(0, 0)
			positions[i] = pos
			extend 	     = GLVisualize.FONT_EXTENDS[glglyph[1]]
			pos 		+= Point3f0(extend.advance[1]/600, 0, 0)
			max_y 		 = max(max_y, extend.scale[2])
			i+=1
		end
		pos = Point3f0(step_direction*Float32(t))
	end
	positions = lift(project, projectionview, Input(positions), Input(zeros(Point{2, Float16}, text_length)), resolution)
	ptexbuff  = texture_buffer(positions.value)
	lift(update!, Input(ptexbuff), positions)
	visualize(
		GLAbstraction.GPUVector(texture_buffer(glyps)), 
		GLAbstraction.GPUVector(ptexbuff), 
		GLAbstraction.GPUVector(texture_buffer(styles)), 
		Input(eye(Mat{4,4,Float32})), Style{:default}()
	)
end
function anotate_grid(ticks, startposition, endposition, projectionview, resolution)
	tick_text = map(UTF8String, map(string, ticks))
	step_direction = normalize(endposition-startposition) * (1f0/length(ticks))
	position_annotations(tick_text, startposition, step_direction, projectionview, resolution)
end

"""
Rounds up and down so that minimum and maximum of the grid ends in a step of the grid
"""
function round_down{T <: Vec}(toround::T, grid_steps::T)
	map(T) do i
		grid_step = (1f0/grid_steps[i])
		step = toround[i] ./ grid_step
		isinteger(step) && return toround[i]
		floor(step)*grid_step
	end
end
function round_up{T <: Vec}(toround::T, grid_steps::T)
	map(T) do i
		grid_step = (1f0/grid_steps[i])
		step = toround[i] ./ grid_step
		isinteger(step) && return toround[i]
		ceil(step)*grid_step
	end
end
"""
align the grid to end up always with on a step
"""
function align_grid(bb, grid_steps)
	mini = round_down(bb.minimum, grid_steps)
	maxi = round_up(bb.maximum, grid_steps)
	AABB{Float32}(mini, maxi)
end
function hascolormap(robj)
	(!haskey(robj.uniforms, :color) || !haskey(robj.uniforms, :color_norm)) && return false
	cmap = robj.uniforms[:color]
	isa(cmap, Texture) && eltype(cmap) <: Colorant
end


const RenderObjectDict = Dict{GLushort, RenderObject}()

function glplot(args...;window=WindowRoot, keyargs...)
	robj = visualize(args...;keyargs...)
	RenderObjectDict[robj.id] = robj
	if hascolormap(robj) 
		#cmap = colormap(robj[:color], robj[:color_norm], window)
		#view(cmap, window, method=:fixed_pixel)
	end
	grid_steps = Input(Vec3f0(5))
	bb = lift(align_grid, robj.boundingbox, grid_steps) 
	view(visualize(bb.value, :grid), window)
	view(robj, window, method=:perspective)
	#=
	stepsize = 0.25
	mini,maxi = bb.value.minimum, bb.value.maximum
	view(
		anotate_grid(
			mini[1]:stepsize:maxi[1], Vec3f0(mini[1],0,0), Vec3f0(maxi[1],0,0), 
			window.cameras[:perspective].projectionview, window.inputs[:framebuffer_size]
		), 
		window, method=:fixed_pixel
	)
	i = 1
	ranges = map(zip(bb.value.minimum, bb.value.maximum)) do mini_maxi
		mini, maxi = mini_maxi
		range = Float64(mini):stepsize:Float64(maxi)
		view(anotate_grid(range, unit(Vec3f0, i)*Float32(stepsize), bb.value.minimum), window, method=:perspective)
		i+=1
	end
	=#
	robj
end

function align_top(top, boundingbox)
	translationmatrix(Vec3f0(top.x - minimum(boundingbox)[1], top.h-maximum(boundingbox)[2], 0))
end
function align_top_right(top, boundingbox)
	translationmatrix(Vec3f0(top.w - maximum(boundingbox)[1], top.h-maximum(boundingbox)[2], 0))
end
function colormap(colormap, colornorm, window)
	robj = visualize(colormap)
	bb = value(robj.boundingbox)
	w = width(bb)
	
	text_min = visualize(@sprintf("%.4f", colornorm[1]), startposition=minimum(bb)+Vec3f0(w[1],-11,0))
	text_max = visualize(@sprintf("%.4f", colornorm[2]), startposition=maximum(bb)+Vec3f0(0,-11,0))

	bb = lift(union, lift(union, text_min.boundingbox, text_max.boundingbox), robj.boundingbox)
	trans = lift(align_top, window.area, bb)
	Context(robj, text_min, text_max, parent=Context(trans))
end

function leftclicked(robj, inputs)
	leftclicked = lift(inputs[:mouse_hover], inputs[:mousebuttonspressed]) do mh, mbp
		mh[1] == robj.id && mbp == [0]
	end
	leftclicked = keepwhen(leftclicked, false, leftclicked)
	lift(x->robj, leftclicked)
end


function toolbar!(window)
	height = 64
	mh = window.inputs[:mouse_hover]
	values = lift(mh) do mh
		text = "nothing"
		if haskey(RenderObjectDict, mh[1])
			robj = RenderObjectDict[mh[1]]
			if isa(robj.main, AbstractArray)
				sz = size(robj.main)
				indexes = ind2sub(sz, mh[2])
				if checkbounds(Bool, sz, indexes...) # don't want to kill GLPlot if there is some glitch
					text = string(gpu_data(robj.main)[indexes...])
				else
					warn("indexes not in bounds in toolbar:hover tool. Indexes: $(indexes), array: $(typeof(robj.main)), $(size(robj.main))")
				end
			end
		end
		text
	end
	vr = visualize(values)
	savebutton = visualize(Rectangle{Float32}(0,0,height, height), style=Cint(5), color=RGBA{Float32}(0.4,0.2,0.7, 1.0))
	lift(leftclicked(savebutton, window.inputs)) do robj
		screenshot(window)
	end
	toolbar_context = visualize([vr, savebutton], gap=5f0)
	trans = lift(align_top_right, window.area, boundingbox(toolbar_context))
	view(Context(toolbar_context, parent=Context(trans)), window, method=:fixed_pixel)
end

clearplot(w::Screen=WindowRoot) = empty!(w.renderlist)

windowroot() = WindowRoot

function __init__()
	w, r = glscreen()
	global trans = Input(Vec3f0(0))
	cubecamera(w, trans=trans)
	glClearColor(1,1,1,1)
	global WindowRoot = w
	toolbar!(w)
	@async r()

end

end
