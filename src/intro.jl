using GLVisualize, FileIO, Images
w = glscreen();@async renderloop(w)
img = load("logo.png")
view(visualize(img), camera=:fixed_pixel)
map(println, w.inputs[:mouseposition])
