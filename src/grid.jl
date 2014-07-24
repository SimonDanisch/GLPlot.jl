function initgrid()
	gridshader = TemplateProgram(shaderdir*"grid.vert", shaderdir*"grid.frag")
	xyplane = genquad(Vec3(-1,-1, 0), Vec3(2, 0, 0), Vec3(0, 2, 0))
	zyplane = genquad(Vec3(0,-1, -1), Vec3(0, 0, 2), Vec3(0, 2, 0))
	zxplane = genquad(Vec3(-1, 0, -1), Vec3(0, 0, 2), Vec3(2, 0, 0))
	
	v,uv,n,i = mergemesh(xyplane, zyplane, zxplane)

	grid = RenderObject([
			:vertexes 			  	=> GLBuffer(v),
			:indexes			   	=> indexbuffer(i),
			#:grid_color 		  => Float32[0.1,.1,.1, 1.0],
			:bg_color 			  	=> Input(Vec4(1, 1, 1, 0.2)),
			:grid_thickness  		=> Input(Vec3(2)),
			:gridsteps  		  	=> Input(Vec3(10)),
			:mvp 				    => cam.projectionview
		], gridshader)
	prerender!(grid, glDisable, GL_DEPTH_TEST, glDisable, GL_CULL_FACE, enabletransparency)
	postrender!(grid, render, grid.vertexarray, glClear, GL_DEPTH_BUFFER_BIT)
	return grid
end

global const GRID = initgrid() 

