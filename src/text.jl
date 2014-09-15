function textwithoffset{T}(text::String, start::Vector3{T}, advance::Vector3{T}, lineheight::Vector3{T})
	resulttext 	= Vec1[]
	offset 		= Vec3[start]
	newlines    = one(T)

	for elem in text
		offset1 = last(offset)
		if elem == '\t'
        	offset[end] = offset1 + (advance*3)
        elseif  elem == ' '
        	offset[end] = offset1 + advance
        elseif elem == '\r' || elem == '\n'
        	offset[end] = start + (newlines*lineheight)
        else
        	glchar = float32(elem)
        	if glchar > 256 
        		glchar = float32(0)
        	end
			push!(offset, offset1 + advance)
			push!(resulttext, Vec1(glchar))
        end
	end
	offset, resulttext
end

function toopengl(text::String;
					start=Vec3(0), scale=Vec2(1/500), color=Vec4(0,0,1,1), backgroundcolor=Vec4(0), 
					lineheight=Vec3(0,0,0), advance=Vec3(0,0,0), rotation=Quaternion(1f0,0f0,0f0,0f0), textrotation=Quaternion(1f0,0f0,0f0,0f0),
					camera=ocamera
				)

	font 			= getfont()
	fontprops 		= font.props[1] .* scale

	if lineheight == Vec3(0)
		newline_dir = -Vec3(0, fontprops[2], 0)
	else
		newline_dir = -lineheight
	end
	if advance == Vec3(0)
		advance_dir = Vec3(fontprops[1], 0,0)
	else
		advance_dir = advance
	end


	offset, ctext 	= textwithoffset(text, start, rotation*advance_dir, rotation*newline_dir)

	parameters 		= [(GL_TEXTURE_WRAP_S,  GL_CLAMP_TO_EDGE), (GL_TEXTURE_MIN_FILTER, GL_NEAREST)]
	texttex 		= Texture(ctext, parameters=parameters)
	offset 			= Texture(offset, parameters=parameters)
	view = [
	  "GLSL_EXTENSIONS"     => "#extension GL_ARB_draw_instanced : enable",
	  "offset_calculation"  => "texelFetch(offset, index, 0).rgb;",
	]
	if !isa(color, Vec4)
		view["color_calculation"] = "texelFetch(color, index, 0);"
		color = Texture(color, parameters=parameters)
	end
	data = merge([
		:index_offset		=> convert(GLint, 0),
	    :rotation 			=> Vec4(textrotation.s, textrotation.v1, textrotation.v2, textrotation.v3),
	    :text 				=> texttex,
	    :offset 			=> offset,
	    :scale 				=> scale,
	    :color 				=> color,
	    :backgroundcolor 	=> backgroundcolor,
	    :projectionview 	=> camera.projectionview
	], font.data)

	program = TemplateProgram(
		Pkg.dir()*"/GLText/src/textShader.vert", Pkg.dir()*"/GLText/src/textShader.frag", 
		view=view, attributes=data, fragdatalocation=[(0, "fragment_color"),(1, "fragment_groupid")]
	)
	obj = instancedobject(data, program, length(text))
	prerender!(obj, enabletransparency)
	return obj
end