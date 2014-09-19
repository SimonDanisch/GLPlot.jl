begin  

local color_chooser_shader = TemplateProgram(joinpath(shaderdir, "colorchooser.vert"), joinpath(shaderdir, "colorchooser.frag"), 
	fragdatalocation=[(0, "fragment_color"),(1, "fragment_groupid")])
verts, uv, normals, indexes = genquad(Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(0, 1, 0))

local data = [

:vertex 					=> GLBuffer(verts),
:uv 						=> GLBuffer(uv),
:index 						=> indexbuffer(indexes),

:middle 					=> Vec2(0.5),
:color 						=> Vec4(0,1,0,1),

:swatchsize 				=> 0.1f0,
:border_color 				=> Vec4(1, 1, 0.99, 1),
:border_size 				=> 0.01f0,

:hover 						=> Input(false),
:hue_saturation 			=> Input(false),
:brightness_transparency 	=> Input(false),

:antialiasing_value 		=> 0.01f0,

:view 						=> ocam.view,
:projection 				=> ocam.projection,
:model 						=> scalematrix(Vec3(1))

]

GLPlot.toopengl{T}(colorinput::Input{RGB{T}}) = toopengl(lift(x->AlphaColorValue(x, one(T)), RGBA{T}, colorinput))

function GLPlot.toopengl{T <: AlphaColorValue}(colorinput::Signal{T})

	obj = RenderObject(data, color_chooser_shader)
	postrender!(obj, render, obj.vertexarray)
	color = colorinput.value

	hover = lift(selectiondata) do x
		x[1][1] == obj.id
	end
	tohsv(rgba) = AlphaColorValue(convert(HSV, rgba.c), rgba.alpha)
	torgb(hsva) = AlphaColorValue(convert(RGB, hsva.c), hsva.alpha)
	tohsv(h,s,v,a) = AlphaColorValue(HSV(float32(h), float32(s), float32(v)), float32(a))

	all_signals = foldl((tohsv(color), false, false, Vec2(0)), selectiondata) do v0, x
		hsv, hue_sat0, bright_trans0, mouse0 = v0
		mouse 			= window.inputs[:mouseposition].value
		mouse_clicked 	= window.inputs[:mousebuttonspressed].value

		hue_sat = in(0, mouse_clicked) && x[1][1] == obj.id
		bright_trans = in(1, mouse_clicked) && x[1][1] == obj.id
		

		if hue_sat && hue_sat0
			diff = mouse - mouse0
			hue = mod(hsv.c.h + diff[1], 360)
			sat = max(min(hsv.c.s + (diff[2] / 30.0), 1.0), 0.0)

			return (tohsv(hue, sat, hsv.c.v, hsv.alpha), hue_sat, bright_trans, mouse)
		elseif hue_sat && !hue_sat0
			return (hsv, hue_sat, bright_trans, mouse)
		end

		if bright_trans && bright_trans0
			diff 		= mouse - mouse0
			brightness 	= max(min(hsv.c.v - (diff[2]/100.0), 1.0), 0.0)
			alpha 		= max(min(hsv.alpha + (diff[1]/100.0), 1.0), 0.0)

			return (tohsv(hsv.c.h, hsv.c.s, brightness, alpha), hue_sat0, bright_trans, mouse)
		elseif bright_trans && !bright_trans0
			return (hsv, hue_sat0, bright_trans, mouse)
		end

		return (hsv, hue_sat, bright_trans, mouse)
	end
	color1 = lift(x -> torgb(x[1]), all_signals)
	color1 = lift(x -> Vec4(x.c.r, x.c.g, x.c.b, x.alpha), Vec4, color1)
	hue_saturation = lift(x -> x[2], all_signals)
	brightness_transparency = lift(x -> x[3], all_signals)


	obj.uniforms[:color] 					= color1
	obj.uniforms[:hover] 					= hover
	obj.uniforms[:hue_saturation] 			= hue_saturation
	obj.uniforms[:brightness_transparency] 	= brightness_transparency

	return obj
end

end # end color local



addchar(s::String, char::Union(String, Char), i::Integer) = addchar(utf8(s), utf8(string(char)), int(i))
function addchar(s::UTF8String, char::UTF8String, i::Integer)
  if i == 0
    return char * s
  elseif i == length(s)
    return s * char
  elseif i > length(s) || i < 0
    return s
  end
  I       = chr2ind(s, i)
  startI  = nextind(s, I)
  return s[1:I] *char* s[startI:end]
end


function GLPlot.toopengl{T <: String}(textinput::Input{T};
          start=Vec3(0), scale=Vec2(1/500), color=Vec4(0,0,1,1), backgroundcolor=Vec4(0), 
          lineheight=Vec3(0,0,0), advance=Vec3(0,0,0), rotation=Quaternion(1f0,0f0,0f0,0f0), textrotation=Quaternion(1f0,0f0,0f0,0f0),
          camera=GLPlot.ocamera
        )
  text          = textinput.value
  font          = getfont()
  fontprops     = font.props[1] .* scale

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


  offset, ctext   = textwithoffset(text, start, rotation*advance_dir, rotation*newline_dir)

  parameters      = [(GL_TEXTURE_WRAP_S,  GL_CLAMP_TO_EDGE), (GL_TEXTURE_MIN_FILTER, GL_NEAREST)]
  textgpu         = Texture(ctext, parameters=parameters)
  offsetgpu       = Texture(offset, parameters=parameters)
  view = [
    "GLSL_EXTENSIONS"     => "#extension GL_ARB_draw_instanced : enable",
    "offset_calculation"  => "texelFetch(offset, index, 0).rgb;",
  ]
  if !isa(color, Vec4)
    view["color_calculation"] = "texelFetch(color, index, 0);"
    color = Texture(color, parameters=parameters)
  end
  data = merge([
    :index_offset       => convert(GLint, 0),
      :rotation         => Vec4(textrotation.s, textrotation.v1, textrotation.v2, textrotation.v3),
      :text             => textgpu,
      :offset           => offsetgpu,
      :scale            => scale,
      :color            => color,
      :backgroundcolor  => backgroundcolor,
      :projectionview   => camera.projectionview
  ], font.data)


  program = TemplateProgram(
    joinpath(shaderdir, "textShader.vert"),joinpath(shaderdir, "textShader.frag"), 
    view=view, attributes=data, fragdatalocation=[(0, "fragment_color"),(1, "fragment_groupid")]
  )
  obj = instancedobject(data, program, length(text))
  prerender!(obj, enabletransparency)
####################################################################

  # selection[1] <- Vector2(ObjectID, Index) for mouseposition

  # Filter events for only the one, when you select text
  textselection = lift(x -> x[2][2], filter((x)-> length(x[1]) == 1 && first(x[1]) == 0 && x[2][1] == obj.id, (IntSet(), Vector2(-1,-1)), clickedselection))

  testinput = foldl((utf8(text), textselection.value, textselection.value), window.inputs[:unicodeinput], textselection) do v0, unicode_char, selection1
    text0, selection0, selection10 = v0
    if selection10 != selection1 # if selection chaned, just update the selection
      (text0, selection1, selection1)
    else # else unicode input must have occured

      text1  = addchar(text0, unicode_char, selection0)
      offset2, ctext2 = textwithoffset(text1, start, rotation*advance_dir, rotation*newline_dir)

      if size(textgpu) != size(ctext2)
        gluniform(program.uniformloc[:text]..., textgpu)
        glTexImage1D(texturetype(textgpu), 0, textgpu.internalformat, size(ctext2, 1), 0, textgpu.format, textgpu.pixeltype, ctext2)
      end
      if size(offsetgpu) != size(offset2)
        gluniform(program.uniformloc[:offset]..., offsetgpu)
        glTexImage1D(texturetype(offsetgpu), 0, offsetgpu.internalformat, size(offset2, 1), 0, offsetgpu.format, offsetgpu.pixeltype, offset2)
      end
      update!(textgpu, ctext2)
      update!(offsetgpu, offset2)
      obj.postRenderFunctions[renderinstanced] = (obj.vertexarray, length(text1))
      (text1, selection0 + 1, selection1)
    end
  end
  obj, lift(x->x[1], testinput)  
end