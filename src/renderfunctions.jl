immutable Style{StyleValue}
end
Style(x::Symbol) = Style{x}()
mergedefault!{S}(style::Style{S}, styles, customdata) = merge!(Dict{Symbol, Any}(customdata), styles[S])

#################################################################################################################################
#Text Rendering:
TEXT_DEFAULTS = [
:Default => [
	:start 				=> Vec3(0),
	:offset 			=> Mat3x2(Vec3(getfont().props[1][1], 0, 0), Vec3(0, getfont().props[1][2], 0)), #Font advance + newline
	:color 				=> rgba(0,0,0,1),
	:backgroundcolor 	=> rgba(0,0,0,0),
	:model 				=> eye(Mat4),
]]
println(TEXT_DEFAULTS[:Default][:offset])
# High Level text rendering for one line or multi line text, which is decided by searching for the occurence of '\n' in text
GLPlot.toopengl(text::String, style=Style(:Default); customization...) 				   = toopengl(style, text, mergedefault!(style, TEXT_DEFAULTS, customization))
# Low level text rendering for one line text
GLPlot.toopengl(text::Texture{GLGlyph, 1, 1}, style=Style(:Default); customization...) = toopengl(style, text, mergedefault!(style, TEXT_DEFAULTS, customization))
# Low level text rendering for multiple line text
GLPlot.toopengl(text::Texture{GLGlyph, 1, 2}, style=Style(:Default); customization...) = toopengl(style, text, mergedefault!(style, TEXT_DEFAULTS, customization))

# END Text Rendering
#################################################################################################################################
