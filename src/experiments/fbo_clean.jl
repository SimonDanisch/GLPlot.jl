immutable FrameBuffer{T}
    id::GLuint
    color_attachments::Vector{Texture}

    function FrameBuffer(dimensions::Input)
        fb = glGenFramebuffers()
        glBindFramebuffer(GL_FRAMEBUFFER, fb)
        lift(window.inputs[:framebuffer_size]) do window_size
          resize!(color, window_size)
          resize!(stencil, window_size)
          
      end
      glCheckFrameVufferStatus(GL_FRAMEBUFFER)
end
    end
end

parameters = [
        (GL_TEXTURE_WRAP_S,  GL_CLAMP_TO_EDGE),
        (GL_TEXTURE_WRAP_T,  GL_CLAMP_TO_EDGE ),

        (GL_TEXTURE_MIN_FILTER, GL_NEAREST),
        (GL_TEXTURE_MAG_FILTER, GL_NEAREST) 
]



framebuffsize   = [window.inputs[:framebuffer_size].value]
color           = Texture(RGBA{Ufixed8},     framebuffsize, parameters=parameters)
stencil         = Texture(Vector2{GLushort}, framebuffsize, parameters=parameters)

glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, color.id, 0)
glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT1, GL_TEXTURE_2D, stencil.id, 0)

glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, id[1])
