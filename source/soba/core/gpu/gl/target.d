module soba.core.gpu.gl.target;
import soba.core.gpu.target;
import soba.core.gpu.gl;
import soba.core.gpu.gl.texture;
import soba.core.gpu.gl.surface;
import bindbc.opengl;

/**
    A render target
*/
class SbGLRenderTarget : SbGPURenderTarget {
private:
    SbGLContext context;
    GLuint framebufferId;

    // NOTE: since this internal the tag determines which 
    //       item in the union is active.
    //       0 = SbWGPUTexture
    //       1 = SbWGPUSurface
    uint tag;
    union {
        SbGLTexture texture;
        SbGLSurface surface;
    }

public:
    ~this() {
        glDeleteFramebuffers(1, &framebufferId);
    }

    this(SbGLContext context, SbGLTexture texture) {
        this.context = context;
        this.texture = texture;
        this.tag = 0;

        // Create framebuffer
        glGenFramebuffers(1, &framebufferId);
        glBindFramebuffer(GL_FRAMEBUFFER, framebufferId);
        glBindTexture(GL_TEXTURE_2D, texture.getId());
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture.getId(), 0);

        // Unbind to ensure state is not messed up
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
        glBindTexture(GL_TEXTURE_2D, 0);
    }

    this(SbGLContext context, SbGLSurface surface) {
        this.context = context;
        this.surface = surface;
        this.tag = 1;

        // Surface framebuffer ID is always 0.
        this.framebufferId = 0;
    }

    override
    uint getWidthPx() {
        switch(tag) {

            // Texture target
            case 0:
                return texture.getWidthPx();

            // FRAMEBUFFER
            case 1:
                return surface.getWidthPx();

            default: assert(0, "Invalid tag!");
        }
    }

    override
    uint getHeightPx() {
        switch(tag) {
            
            // Texture target
            case 0:
                return texture.getHeightPx();

            // FRAMEBUFFER
            case 1:
                return surface.getHeightPx();

            default: assert(0, "Invalid tag!");
        }
    }

    /**
        Gets the internal framebuffer ID
    */
    GLuint getId() {
        return framebufferId;
    }
}