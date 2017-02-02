using VideoIO, Colors, GLVisualize, Reactive, Images, GLAbstraction, GeometryTypes
using ImageFeatures
using GLPlot, Plots, GLWindow; GLPlot.init(); glvisualize()

function playv(buffer, video_stream, t)
    eof(video_stream) && seekstart(video_stream)
    _,w,h = size(buffer)
    read!(video_stream, buffer)
    return map(RGB{Float32}, restrict(restrict(reinterpret(RGB{N0f8}, buffer, (w,h)))))
end
function topoints(v0, img)
    @inbounds for i in eachindex(img)
        x = img[i]
        v0[i] = Point3f0(x.r, x.g, x.b)
    end
    v0
end


function setup_pipeline()
    window = GLPlot.viewing_screen
    f = VideoIO.opencamera()
    img1 = read(f)
    vw,vh = size(img1, 2), size(img1, 3)
    img_scaled = map(RGB{Float32}, restrict(restrict(reinterpret(RGB{N0f8}, img1, (vw, vh)))))
    imw, imh = size(img_scaled)
    buffer = zeros(UInt8, 3, vw,vh)
    t = bounce(1:10)
    imstream = map(playv, Signal(buffer), Signal(f), t)
    imw *= 2
    img_area = map(window.area) do x
        SimpleRectangle(x.w-imw, 0, imw, x.h)
    end
    point_area = map(window.area) do x
        w,h = x.w-imw, div(x.h, 2)
        SimpleRectangle(0, x.h-h, w, h)
    end
    plot_area = map(window.area) do x
        w,h = x.w-imw, div(x.h, 2)
        SimpleRectangle(0, 0, w, h)
    end

    point_screen = Screen(window, area=point_area)
    plot_screen = Screen(window, area=plot_area)
    img_screen = Screen(window, area=img_area)
    GLVisualize.add_screen(plot_screen)
    s1 = play_widget(linspace(1f0, 10f0, 50))
    s2 = play_widget(linspace(0f0, 1f0, 100))
    s3 = play_widget(linspace(0f0, 1f0, 100))
    keypoint_thresh = play_widget(linspace(0.0, 1.0, 100))


    points = foldp(topoints, zeros(Point3f0, length(value(imstream))), imstream);
    colors = map(vec, imstream);
    glplot(points, :speed, screen=point_screen, color=colors, boundingbox=nothing);


    grayed = map(imstream) do img
        convert(Matrix{Gray{Float32}}, img)
    end

    keypoints = map(grayed, keypoint_thresh) do img, tresh
        kp = Keypoints(fastcorners(img, 500, tresh))
        w,h = size(img)
        map(kp) do x
            p = x.I
            Point2f0(p[1], h-p[2])
        end
    end

    canned = map(grayed, s1, s2, s3) do img, gamma, lower, upper
        canny(img, gamma, upper, lower)
    end
    visses = map(x->visualize(x, model=eye(Mat4f0)), [imstream, grayed, canned])
    _view(
        visualize(visses, direction=2),
        img_screen, camera=:orthographic_pixel
    )
    grayedrobj = visses[2].children[]

    keypointvis = visualize(
        (Circle(Point2f0(0), 2f0), keypoints),
        color=RGBA{Float32}(0,0,0,0.3), stroke_width=2f0,
        stroke_color=RGBA{Float32}(1,1,1,1),
        model=grayedrobj[:model], boundingbox=nothing
    )
    _view(keypointvis, img_screen, camera=:orthographic_pixel)
    register_plot!(keypointvis, img_screen)

    n = 80
    xls = linspace(0,1,n)
    yls = linspace(0, 10_000, n)
    pl = plot([xls,xls,xls],[yls,yls,yls], color=[:red :green :blue])
    gui()
    histps = plot_screen.children[1].renderlist[1][end-2:end]
    preserve(map(imstream) do img
        seps = separate(img)
        for i=1:3
            x,y = imhist(view(seps, :, :, i), n, 0.0, 1.0)
            mn = min(length(x), length(y))
            new_vals = map(Point2f0, zip(view(x, 1:mn), view(y, 1:mn)))
            set_arg!(histps[i], :vertex, new_vals)
        end
        nothing
    end)
end
setup_pipeline()
GLPlot.block()
