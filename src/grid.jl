function creategrid(; bg_color=Vec4(1, 1, 1, 0.01), grid_color=Vec4(0,0,0,0.2),
		xrange::(Real, Real)=(-1,1), yrange::(Real, Real)=(-1,1), zrange::(Real, Real)=(-1,1), 
		grid_thickness::Vec3 = Vec3(2), gridsteps::Vec3 = Vec3(10), 
		camera=pcamera
	)
	xyplane = genquad(Vec3(xrange[1], yrange[1], zrange[1]), Vec3(xrange[1], yrange[2], zrange[1]), Vec3(xrange[2], yrange[1], zrange[1]))
	zyplane = genquad(Vec3(xrange[1], yrange[1], zrange[1]), Vec3(xrange[1], yrange[2], zrange[1]), Vec3(xrange[1], yrange[1], zrange[2]))
	zxplane = genquad(Vec3(xrange[1], yrange[1], zrange[1]), Vec3(xrange[2], yrange[1], zrange[1]), Vec3(xrange[1], yrange[1], zrange[2]))
	
	v,uv,n,i = mergemesh(xyplane, zyplane, zxplane)

	grid = RenderObject(@compat(Dict(
			:vertexes 			  	=> GLBuffer(v),
			:indexes			   	=> indexbuffer(i),
			:grid_color 		  	=> grid_color,
			:bg_color 			  	=> bg_color,
			:grid_thickness  		=> grid_thickness,
			:gridsteps  		  	=> float32(gridsteps),
			:mvp 				    => camera.projectionview
		)), gridshader)
	prerender!(grid, glDisable, GL_DEPTH_TEST, glDisable, GL_CULL_FACE, enabletransparency)
	postrender!(grid, render, grid.vertexarray)
	return grid
end

initgrid() = global gridshader = TemplateProgram(shaderdir*"grid.vert", shaderdir*"grid.frag")
init_after_context_creation(initgrid)

export creategrid

