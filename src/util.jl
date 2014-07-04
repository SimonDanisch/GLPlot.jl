
function screenshot(window_size)
	const imgd = Array(Uint8, 3, window_size...)
	const imgprops = {"colorspace" => "RGB", "spatialorder" => ["x", "y"], "colordim" => 1}
    glReadPixels(0, 0, window_size..., GL_RGB, GL_UNSIGNED_BYTE, imgd)
    img = Image(mapslices(reverse,imgd, [3]), imgprops)
    imgname = "test/"*string(time()) * ".png"
    imwrite(img, imgname)
end
