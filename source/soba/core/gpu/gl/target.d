module soba.core.gpu.gl.target;
import soba.core.gpu.target;
import soba.core.gpu.gl;
import soba.core.gpu.gl.texture;
import soba.core.gpu.gl.surface;
import soba.core.gpu.texture;
import bindbc.opengl;
import soba.core.gpu.gl.fbo;

/**
    A render target
*/
class SbGLRenderTarget : SbGPURenderTarget {
private:
    SbGLContext context;
    SbGPURenderTargetType tag;
    union {
        SbGLFramebuffer framebuffer;
        SbGLSurface surface;
    }

public:

    /// Constructor
    this(SbGLContext context, SbGLFramebuffer framebuffer) {
        this.context = context;
        this.framebuffer = framebuffer;
        this.tag = SbGPURenderTargetType.Framebuffer;
    }

    /// Constructor
    this(SbGLContext context, SbGLSurface surface) {
        this.context = context;
        this.surface = surface;
        this.tag = SbGPURenderTargetType.Surface;
    }

    /**
        Gets the render targets width in pixels
    */
    override
    uint getWidthPx() {
        switch(tag) {

            // Texture target
            case SbGPURenderTargetType.Framebuffer:
                return framebuffer.getWidthPx();

            // FRAMEBUFFER
            case SbGPURenderTargetType.Surface:
                return surface.getWidthPx();

            default: assert(0, "Invalid tag!");
        }
    }

    /**
        Gets the render targets height in pixels
    */
    override
    uint getHeightPx() {
        switch(tag) {
            
            // Texture target
            case SbGPURenderTargetType.Framebuffer:
                return framebuffer.getHeightPx();

            // FRAMEBUFFER
            case SbGPURenderTargetType.Surface:
                return surface.getHeightPx();

            default: assert(0, "Invalid tag!");
        }
    }

    /**
        Gets the type of the render target
    */
    override
    SbGPURenderTargetType getType() {
        return tag;
    }

    /**
        Whether the render target has a depth and stencil texture
    */
    override
    bool hasDepthStencil() {
        switch(tag) {
            case SbGPURenderTargetType.Framebuffer:
                foreach(target; framebuffer.getTargets()) {
                    if (target.getFormat() == SbGPUTextureFormat.DepthStencil) return true;
                }
                return false;
                
            case SbGPURenderTargetType.Surface:
                return true;

            default: assert(0, "Invalid tag!");
        }
    }

    /**
        Gets the internal framebuffer ID
    */
    GLuint getId() {
        switch(tag) {
            
            // Texture target
            case SbGPURenderTargetType.Framebuffer:
                return framebuffer.getId();

            // FRAMEBUFFER
            case SbGPURenderTargetType.Surface:
                return 0;

            default: assert(0, "Invalid tag!");
        }
    }

    void bind() {
        switch(tag) {
            
            // Texture target
            case SbGPURenderTargetType.Framebuffer:
                glBindFramebuffer(GL_FRAMEBUFFER, framebuffer.getId());
                return;

            // FRAMEBUFFER
            case SbGPURenderTargetType.Surface:
                glBindFramebuffer(GL_FRAMEBUFFER, 0);
                return;

            default: assert(0, "Invalid tag!");
        }
    }
}