begin 
	local runner 	= 1
	local wsize 	= [512, 512]
	local buffer 	= Array(RGB{Ufixed8}, wsize...)

	local imgprops 		= @compat Dict{Any, Any}("colorspace" => "RGB", "spatialorder" => ["x", "y"], "colordim" => 1)

	function screenshot(window_size, path="screenshot.png")
		if window_size != wsize
			buffer = Array(RGB{Ufixed8}, window_size...)
			wsize = window_size
		end
		glReadPixels(0, 0, window_size..., GL_RGB, GL_UNSIGNED_BYTE, buffer)
		imwrite(Image(rotl90(buffer)), path)
	end
	
	function timeseries(window_size, path="video/")
		p = abspath(path)*@sprintf("%06d.png", runner)
		screenshot(window_size, p)
		runner += 1
	end
end


