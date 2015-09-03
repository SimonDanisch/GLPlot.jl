using Reactive
clicks = Input(0)
click_count = foldl(inc, 0, clicks)
lift(click_count) do c
   subscribe(h1("I'm a heading. I have been clicked $c times"), clicks)
end


txt_signal = Input("lol")
vizz, sig = edit("text")
map(txt_signal) do txt
	textbox(value=txt) >>>  txt_signal 
end