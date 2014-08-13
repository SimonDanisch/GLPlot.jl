using GLText

function toopengl(text::String; 
					start=Vec3(0), scale=Vec2(1/500), color=Vec4(0,0,0,1), backgroundcolor=Vec4(0), 
					lineheight=0.1,
					rotation=Quaternion(1f0,0f0,0f0,0f0), textrotation=Quaternion(1f0,0f0,0f0,0f0)
				)
	font = getfont()
	fontprops = font.props[1] .* scale
	advance_dir = Vec3(fontprops[1], 0,0)
	newline_dir = Vec3(0, lineheight, 0)
	offset, ctext 	= textwithoffset(start, text, rotation*advance_dir, rotation*newline_dir)

	parameters 		= [(GL_TEXTURE_WRAP_S,  GL_CLAMP_TO_EDGE),(GL_TEXTURE_MIN_FILTER, GL_NEAREST)]
	texttex 		= Texture(ctext, parameters=parameters)
	offset 			= Texture(offset, parameters=parameters)
	view = [
	  "GLSL_EXTENSIONS"     => "#extension GL_ARB_draw_instanced : enable",
	  "offset_calculation"  => "texelFetch(offset, index, 0).rgb;",
	]

	data = merge([
		:index_offset		=> convert(GLint, 0),
	    :rotation 			=> Vec4(textrotation.s, textrotation.v1, textrotation.v2, textrotation.v3),
	    :text 				=> texttex,
	    :offset 			=> offset,
	    :scale 				=> scale,
	    :color 				=> color,
	    :backgroundcolor 	=> backgroundcolor,
	    :projectionview 	=> cam.projectionview
	], font.data)

	program = TemplateProgram(Pkg.dir()*"/GLText/src/textShader.vert", Pkg.dir()*"/GLText/src/textShader.frag", 
		view=view, attributes=data, fragdatalocation=[(0, "fragment_color"), (1, "fragment_id")])
	return instancedobject(data, program, length(text))
end