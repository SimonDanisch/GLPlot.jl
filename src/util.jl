function screenshot(size, key, path="screenshot.png")
	imgdata = Array(Uint8, 3, size...)
	imgprops = {"colorspace" => "RGB", "spatialorder" => ["x", "y"], "colordim" => 1}
	if key == GLFW.KEY_S
		glReadPixels(0, 0, size..., GL_RGB, GL_UNSIGNED_BYTE, imgdata)
		img = Image(mapslices(reverse, imgdata, [3]), imgprops)
		imwrite(img, path)
		img = 0
		gc()
		println("written: $(screenshot)")
	end
end
