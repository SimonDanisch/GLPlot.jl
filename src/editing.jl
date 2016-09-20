"""
There's a lot of noise if we just go through all parameters of a `RenderObject`.
This function filters out the internal values
"""
function is_editable(k, v_v)
    v = value(v_v)
    !(
        k == :objectid ||
        k == :is_fully_opaque ||
        k == :instances ||
        k == Symbol("position.multiplicator") ||
        k == Symbol("position.dims") ||
        k == Symbol("resolution") ||
        k == :visible ||
        startswith(string(k), "boundingbox") ||
        (k == Symbol("color") && isa(v, AbstractArray)) ||
        k in fieldnames(PerspectiveCamera) ||
        k == :instances ||
        isa(v, Symbol) ||
        isa(v, Void) ||
        isa(v, NativeMesh) ||
        isa(v, Int) ||
        isa(v, Int32) ||
        isa(v, UInt32) ||
        isa(v, UInt) ||
        (isa(v, FixedVector) && eltype(v) <: Integer)
    )
end

makesignal2(s::Signal) = s
makesignal2(v) = Signal(v)
makesignal2(v::GPUArray) = v


function extract_edit_menu(robj::RenderObject, edit_screen, isvisible)
    extract_edit_menu(robj.uniforms, edit_screen, isvisible)
end
function extract_edit_menu(edit_dict::Dict, edit_screen, isvisible)
    lines = Point2f0[]
    screen_w = edit_screen.area.value.w
    labels = String[]
    glyph_scale = GLVisualize.glyph_scale!('X')
    pos = 1mm
    scale = 2mm ./ glyph_scale
    widget_text = scale .* 1.2f0
    glyph_height = round(Int, glyph_scale[2]*scale[2])
    atlas = GLVisualize.get_texture_atlas()
    font = GLVisualize.DEFAULT_FONT_FACE
    textpositions = Point2f0[]
    for (k,v) in edit_dict
        is_editable(k, v) || continue
        s = makesignal2(v)
        if applicable(widget, s, edit_screen)
            sig, vis = widget(s, edit_screen,
                visible=isvisible, text_scale=widget_text,
                area=(screen_w, value(icon_size)),
                knob_scale = 1.6mm
            )
            edit_dict[k] = sig
            bb = value(boundingbox(vis))
            height = widths(bb)[2]
            mini = minimum(bb)
            to_origin = -Vec3f0(mini[1], mini[2], 0)
            GLAbstraction.transform!(vis, translationmatrix(Vec3f0(2mm,pos,0)+to_origin))
            _view(vis, edit_screen, camera=:fixed_pixel)
            pos += round(Int, height) + 1mm

            label = replace(string(k), "_", " ")*":"
            push!(labels, label)
            append!(textpositions,
                GLVisualize.calc_position(label, Point2f0(1mm, pos), scale, font, atlas)
            )
            pos += glyph_height + 4mm
            push!(lines, Point2f0(0, pos-2mm), Point2f0(screen_w, pos-2mm))

        end
    end
    _view(visualize(
            join(labels), position=textpositions,
            color=RGBA{Float32}(0.8, 0.8, 0.8, 1.0),
            relative_scale=scale
        ), edit_screen, camera=:fixed_pixel
    )
    _view(visualize(
        lines, :linesegment, thickness=0.25mm, color=RGBA{Float32}(0.9, 0.9, 0.9, 1.0)
    ), edit_screen, camera=:fixed_pixel)

    pos
end
